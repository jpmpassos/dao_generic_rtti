unit UDao;

interface

Uses
  Rtti, UAttributes, TypInfo, SysUtils, FireDAC.Comp.Client,
  Generics.Collections, UControleConexao, UFieldUtil;

type
  TDAO = class
  private
    fautocomite: Boolean;
    Session: TConnetion;
    function Instanciar<T: Class>: T;

    procedure InsertFirebird<T: Class>(Obj: TObject);
    procedure InsertPostgresql<T: Class>(Obj: TObject);
    procedure AtualizarId(Obj: TObject; Id: Integer);
    function QueryFB<T: Class>(sql: string): TList<T>;
    function QueryPG<T: Class>(sql: string): TList<T>;

    function CarregarObjeto<T: Class>(Maps: TList<TMapFieldProp>;
      Map: TMapFieldProp; TypObj: TRttiType): T;

    function GetConection: TConnetion;
  public
    function Insert<T: Class>(Obj: TObject): Integer;
    function Query<T: Class>(sql: string): TList<T>;
    function Get<T: Class>(codigo: Integer): T;
    procedure Delete<T: Class>(Obj: TObject);
    procedure Update<T: Class>(Obj: TObject);

    function CommitRelease: Boolean;
    constructor create(autoCommit: Boolean = true);
  end;

implementation

Uses
  REST.Json, UDBConnection, USystemConfig, System.Json,
  Data.DBXJSONReflect, UJsonUtil;

{ TDAO }

procedure TDAO.AtualizarId(Obj: TObject; Id: Integer);
var
  Contexto: TRttiContext;
  TypObj: TRttiType;
  Prop: TRttiProperty;
  SourceAsPointer, ResultAsPointer: Pointer;
  strInsert, strFields, strValues, strPrimaryKey: String;
  IsId, IsAutoincremente: Boolean;
  Atributo: TCustomAttribute;
begin
  Contexto := TRttiContext.create;
  TypObj := Contexto.GetType(TObject(Obj).ClassInfo);
  Move(Obj, ResultAsPointer, SizeOf(Pointer));

  for Prop in TypObj.GetProperties do
  begin
    for Atributo in Prop.GetAttributes do
    begin
      if Atributo is IdAttribute then
      begin
        Prop.SetValue(ResultAsPointer, TValue.From(Id));
        Break;
      end;
    end;
  end;
end;

function TDAO.CarregarObjeto<T>(Maps: TList<TMapFieldProp>; Map: TMapFieldProp;
  TypObj: TRttiType): T;
var
  i: Integer;
  strTemp: string;
  Prop: TRttiProperty;
  SourceAsPointer, ResultAsPointer: Pointer;
begin
  i := 0;
  Result := Instanciar<T>;
  Move(Result, ResultAsPointer, SizeOf(Pointer));
  while Maps.Count > i do
  begin
    Map := Maps[i];
    try
      Prop := TypObj.GetProperties[Map.indexprop];
      if Map.tipo = tpString then
      begin
        Prop.SetValue(ResultAsPointer,
          TValue.From(Session.Query.Fields[Map.indexfield].AsString));
      end
      else if Map.tipo = tpBoleano then
      begin
        Prop.SetValue(ResultAsPointer,
          TValue.From(StrToBool(Session.Query.Fields[Map.indexfield]
          .AsString)));
      end
      else if Map.tipo = tpFloat then
      begin
        Prop.SetValue(ResultAsPointer,
          TValue.From(Session.Query.Fields[Map.indexfield].AsFloat));
      end
      else if Map.tipo = tpInteger then
      begin
        Prop.SetValue(ResultAsPointer,
          TValue.From(Session.Query.Fields[Map.indexfield].AsInteger));
      end
      else if Map.tipo = tpBoleano then
      begin
        Prop.SetValue(ResultAsPointer,
          TValue.From(Session.Query.Fields[Map.indexfield].AsInteger <> 0));
      end
      else if Map.tipo = tpData then
      begin
        Prop.SetValue(ResultAsPointer,
          TValue.From(Session.Query.Fields[Map.indexfield].AsDateTime));
      end
      else if Map.tipo = tpJsonb then
      begin
        // TJson.JsonToObject<Prop.PropertyType.ClassType>(Query.Fields[Map.indexfield].AsString);
        strTemp := Session.Query.Fields[Map.indexfield].AsString;
        Prop.SetValue(ResultAsPointer,
          TValue.From(Session.Query.Fields[Map.indexfield].AsString));
      end;
    except
      on E: Exception do
        raise Exception.create('Erro preencher ' + Prop.Name + '. ERROR:' +
          E.Message);
    end;

    Inc(i);
  end;
end;

function TDAO.CommitRelease: Boolean;
begin
  try
    if not fautocomite then
    begin
      try
        Session.Query.Connection.Commit;
        Exit(true)
      except
        on E: Exception do
        begin
          try
            if Session.InTransaction then
              Session.Rollback;
          finally
            Result := false;
          end;
        end;
      end;
    end;
  finally
    try
      TConexoesLista.Release(Session);

      FreeAndNil(Session);
    except
      on E: Exception do
    end;
  end;
end;

constructor TDAO.create(autoCommit: Boolean);
begin
  fautocomite := autoCommit;

  if not autoCommit then
  begin
    Session := TConexoesLista.Acquire();
    Session.StartTransaction;
  end;
end;

procedure TDAO.Delete<T>(Obj: TObject);
var
  fieldUtil: TFieldUtil;
  Query: TFDQuery;
  script: String;
begin
  try
    fieldUtil := TFieldUtil.create;
    script := fieldUtil.ScriptDelete<T>(Obj);

    Query := TDBConnection.GetInstance.Query;

    if TDBConnection.autoCommit then
    begin
      Query.Connection.StartTransaction;
    end;
    Query.Close;
    Query.sql.Clear;
    Query.sql.Add(script);
    Query.ExecSQL;

    if TDBConnection.autoCommit then
    begin
      try
        Query.Connection.Commit;
      except
        on E: Exception do
        begin
          try
            if Assigned(Query) and Query.Connection.InTransaction then
              Query.Connection.Rollback;
          finally
            raise Exception.create('Erro ao executar query. Erro: ' +
              E.Message);
          end;
        end;
      end;
    end;
  finally
    Query := nil;
    FreeAndNil(fieldUtil);
  end;
end;

function TDAO.Get<T>(codigo: Integer): T;
var
  Maps: TList<TMapFieldProp>;
  Method: TRttiMethod;
  Map: TMapFieldProp;
  Obj: T;
  c: TClass;
  value: TValue;
  Context: TRttiContext;
  TypObj: TRttiType;
  j, i: Integer;
  fieldUtil: TFieldUtil;
  sql: string;
begin
  try
    if fautocomite then
    begin
      Session := TConexoesLista.Acquire();
      Session.StartTransaction;
    end;

    fieldUtil := TFieldUtil.create;

    Obj := Instanciar<T>;

    sql := fieldUtil.ScriptGet(Obj);

    try
      FreeAndNil(Obj);
    except
      on E: Exception do
    end;

    if sql.IsEmpty then
      raise Exception.create('Erro ao recuperar objeto.a');

    Session.Query.Open(sql + IntToStr(codigo));

    if fautocomite then
    begin
      try
        Session.Query.Connection.Commit;
        TConexoesLista.Release(Session);
      except
        on E: Exception do
        begin
          try
            if Session.InTransaction then
              Session.Rollback;
          finally
            TConexoesLista.Release(Session);
            raise Exception.create('Erro ao executar query. Erro: ' +
              E.Message);
          end;
        end;
      end;
    end;

    if Session.Query.RecordCount > 0 then
    begin
      Obj := Instanciar<T>;
      c := TObject(Obj).ClassType;
      TypObj := Context.GetType(c);
      fieldUtil := TFieldUtil.create;
      Maps := fieldUtil.getMap(Session.Query, TypObj, TObject(Obj));
      Result := CarregarObjeto<T>(Maps, Map, TypObj);
    end;
  finally
    try
      FreeAndNil(Obj);
    except
      on E: Exception do
    end;

    try
      FreeAndNil(c);
    except
      on E: Exception do
    end;

    try
      FreeAndNil(TypObj);
    except
      on E: Exception do
    end;

    try
      FreeAndNil(fieldUtil);
    except
      on E: Exception do
        fieldUtil := nil;
    end;
  end;
end;

function TDAO.GetConection: TConnetion;
begin
  Exit(TConexoesLista.Acquire());
end;

function TDAO.Insert<T>(Obj: TObject): Integer;
begin
  if TSystemConfig.GetInstancia.tipoSGBD = tpFirebird then
    InsertFirebird<T>(Obj)
  else
    InsertPostgresql<T>(Obj);
end;

procedure TDAO.InsertFirebird<T>(Obj: TObject);
var
  Id: Integer;
  fieldUtil: TFieldUtil;
  script: TScriptInsert;
begin
  try
    fieldUtil := TFieldUtil.create;
    script := fieldUtil.ScriptInserte<T>(Obj);

    if fautocomite then
    begin
      Session := TConexoesLista.Acquire();
      Session.StartTransaction;
    end;

    Session.Query.Close;
    Session.Query.sql.Clear;
    Session.Query.sql.Add(script.script);
    Session.Query.Open;

    if not script.chaveprimaria.IsEmpty then
      Id := Session.Query.FieldByName(script.chaveprimaria).AsInteger;

    if fautocomite then
    begin
      try
        Session.Query.Connection.Commit;
      except
        on E: Exception do
        begin
          try
            if Session.InTransaction then
              Session.Rollback;
          finally
            raise Exception.create('Erro ao executar query. Erro: ' +
              E.Message);
          end;
        end;
      end;
    end;

    if Id > 0 then
      AtualizarId(Obj, Id);
  finally
    if fautocomite then
      TConexoesLista.Release(Session);

    FreeAndNil(fieldUtil);
  end;
end;

procedure TDAO.InsertPostgresql<T>(Obj: TObject);
var
  Id: Integer;
  fieldUtil: TFieldUtil;
  Query: TFDQuery;
  script: TScriptInsert;
begin
  try
    fieldUtil := TFieldUtil.create;
    script := fieldUtil.ScriptInsertePG<T>(Obj);

    Query := TDBConnection.GetInstance.Query;

    if TDBConnection.autoCommit then
    begin
      Query.Connection.StartTransaction;
    end;
    Query.Close;
    Query.sql.Clear;
    Query.sql.Add(script.script);
    Query.ExecSQL;

    if not script.chaveprimaria.IsEmpty then
    begin
      Query.Close;
      Query.sql.Clear;
      Query.sql.Add(script.scriptpgequencia);
      Query.Open;

      Id := Query.FieldByName('cod').AsInteger;
    end;

    if TDBConnection.autoCommit then
    begin
      try
        Query.Connection.Commit;

        if Id > 0 then
          AtualizarId(Obj, Id);
      except
        on E: Exception do
        begin
          try
            if Assigned(Query) and Query.Connection.InTransaction then
              Query.Connection.Rollback;
          finally
            raise Exception.create('Erro ao executar query. Erro: ' +
              E.Message);
          end;
        end;
      end;
    end;
  finally
    Query := nil;
    FreeAndNil(fieldUtil);
  end;
end;

function TDAO.Instanciar<T>: T;
var
  valor: TValue;
  ctx: TRttiContext;
  tipo: TRttiType;
  tipoInstancia: TRttiInstanceType;
begin
  tipo := ctx.GetType(TypeInfo(T));
  tipoInstancia := (ctx.FindType(tipo.QualifiedName) as TRttiInstanceType);
  valor := tipoInstancia.MetaclassType.create;
  Result := valor.AsType<T>;
end;

function TDAO.Query<T>(sql: string): TList<T>;
begin
  if TSystemConfig.GetInstancia.tipoSGBD = tpFirebird then
    Result := QueryFB<T>(sql)
  else
    Result := QueryPG<T>(sql);
end;

function TDAO.QueryFB<T>(sql: string): TList<T>;
var
  Maps: TList<TMapFieldProp>;
  Method: TRttiMethod;
  Map: TMapFieldProp;
  Obj: T;
  c: TClass;
  value: TValue;
  Context: TRttiContext;
  TypObj: TRttiType;
  j, i: Integer;
  fieldUtil: TFieldUtil;
begin
  try
    if fautocomite then
    begin
      Session := TConexoesLista.Acquire();
      Session.StartTransaction;
    end;

    Session.Query.Open(sql);

    if fautocomite then
    begin
      try
        Session.Query.Connection.Commit;
        TConexoesLista.Release(Session);
      except
        on E: Exception do
        begin
          try
            if Session.InTransaction then
              Session.Rollback;
          finally
            TConexoesLista.Release(Session);
            raise Exception.create('Erro ao executar query. Erro: ' +
              E.Message);
          end;
        end;
      end;
    end;

    if Session.Query.RecordCount > 0 then
    begin
      Obj := Instanciar<T>;
      c := TObject(Obj).ClassType;
      Result := TList<T>.create;

      TypObj := Context.GetType(c);

      fieldUtil := TFieldUtil.create;
      Maps := fieldUtil.getMap(Session.Query, TypObj, TObject(Obj));

      j := 0;
      Session.Query.RecNo := j;

      while not Session.Query.Eof do
      begin
        Result.Add(CarregarObjeto<T>(Maps, Map, TypObj));
        Session.Query.Next;
      end;
    end;
  finally
    try
      FreeAndNil(Obj);
    except
      on E: Exception do
    end;

    try
      FreeAndNil(c);
    except
      on E: Exception do
    end;

    try
      FreeAndNil(TypObj);
    except
      on E: Exception do
    end;

    try
      FreeAndNil(fieldUtil);
    except
      on E: Exception do
        fieldUtil := nil;
    end;
  end;
end;

function TDAO.QueryPG<T>(sql: string): TList<T>;
var
  Maps: TList<TMapFieldProp>;
  Method: TRttiMethod;
  Map: TMapFieldProp;
  LJsonResponse: TJSONObject;
  Obj: T;
  c: TClass;
  value: TValue;
  Context: TRttiContext;
  TypObj: TRttiType;
  instancia: TRttiInstanceType;
  SourceAsPointer, ResultAsPointer: Pointer;
  Prop: TRttiProperty;
  j, i: Integer;
  Query: TFDQuery;
  fieldUtil: TFieldUtil;
  strTemp: string;
  unm: TJSONUnMarshal;
  Tcjson: TClass;
  objetojson: TObject;
  Json: TJSONValue;
  jsonutil: TJsonUtil;
begin
  try
    Query := TDBConnection.GetInstance.Query;

    if TDBConnection.autoCommit then
    begin
      Query.Connection.StartTransaction;
    end;

    Query.Open(sql);

    if TDBConnection.autoCommit then
    begin
      try
        Query.Connection.Commit;
      except
        on E: Exception do
        begin
          try
            if Assigned(Query) and Query.Connection.InTransaction then
              Query.Connection.Rollback;
          finally
            raise Exception.create('Erro ao executar query. Erro: ' +
              E.Message);
          end;
        end;
      end;
    end;

    if Query.RecordCount > 0 then
    begin
      Obj := Instanciar<T>;
      c := TObject(Obj).ClassType;
      Result := TList<T>.create;

      TypObj := Context.GetType(c);

      Maps := fieldUtil.getMap(Query, TypObj, TObject(Obj));

      j := 0;
      Query.RecNo := j;

      while not Query.Eof do
      begin
        Obj := Instanciar<T>;
        Move(Obj, ResultAsPointer, SizeOf(Pointer));
        while Maps.Count > i do
        begin
          Map := Maps[i];
          try
            Prop := TypObj.GetProperties[Map.indexprop];
            if Map.tipo = tpString then
            begin
              Prop.SetValue(ResultAsPointer,
                TValue.From(Query.Fields[Map.indexfield].AsString));
            end
            else if Map.tipo = tpBoleano then
            begin
              Prop.SetValue(ResultAsPointer,
                TValue.From(StrToBool(Query.Fields[Map.indexfield].AsString)));
            end
            else if Map.tipo = tpFloat then
            begin
              Prop.SetValue(ResultAsPointer,
                TValue.From(Query.Fields[Map.indexfield].AsFloat));
            end
            else if Map.tipo = tpInteger then
            begin
              Prop.SetValue(ResultAsPointer,
                TValue.From(Query.Fields[Map.indexfield].AsInteger));
            end
            else if Map.tipo = tpBoleano then
            begin
              try
                Prop.SetValue(ResultAsPointer,
                  TValue.From(Query.Fields[Map.indexfield].AsInteger <> 0));
              except
                on E: Exception do
                  Prop.SetValue(ResultAsPointer, TValue.From(false));
              end;

            end
            else if Map.tipo = tpData then
            begin
              Prop.SetValue(ResultAsPointer,
                TValue.From(Query.Fields[Map.indexfield].AsDateTime));
            end
            else if Map.tipo = tpJsonb then
            begin
              Prop.SetValue(ResultAsPointer,
                jsonutil.JsonToObject(Query.Fields[Map.indexfield].AsString,
                Map.cjson));
            end;
          except
            on E: Exception do
              raise Exception.create('Erro preencher ' + Prop.Name + '. ERROR:'
                + E.Message);
          end;

          Inc(i);
        end;
        i := 0;

        Result.Add(Obj);
        Query.Next;
      end;
    end;
  finally
    Query := nil;
    FreeAndNil(fieldUtil);
  end;
end;

procedure TDAO.Update<T>(Obj: TObject);
var
  fieldUtil: TFieldUtil;
  Query: TFDQuery;
  script: String;
begin
  try
    fieldUtil := TFieldUtil.create;
    script := fieldUtil.ScriptUpdate<T>(Obj);

    Query := TDBConnection.GetInstance.Query;

    if TDBConnection.autoCommit then
    begin
      Query.Connection.StartTransaction;
    end;
    Query.Close;
    Query.sql.Clear;
    Query.sql.Add(script);
    Query.ExecSQL;

    if TDBConnection.autoCommit then
    begin
      try
        Query.Connection.Commit;
      except
        on E: Exception do
        begin
          try
            if Assigned(Query) and Query.Connection.InTransaction then
              Query.Connection.Rollback;
          finally
            raise Exception.create('Erro ao executar query. Erro: ' +
              E.Message);
          end;
        end;
      end;
    end;
  finally
    Query := nil;
    FreeAndNil(fieldUtil);
  end;
end;

initialization

finalization

end.
