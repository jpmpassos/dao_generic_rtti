unit UDao;

interface

Uses
  Rtti, UAttributes, TypInfo, SysUtils, Forms, Vcl.Dialogs, FireDAC.Comp.Client,
  Generics.Collections, Endereco;

type
  TDAO = class
  private
    function Instanciar<T: Class>: T;

    procedure InsertFirebird<T: Class>(Obj: TObject);
    procedure InsertPostgresql<T: Class>(Obj: TObject);
    procedure AtualizarId(Obj: TObject; Id: Integer);
    function QueryFB<T: Class>(sql: string): TList<T>;
    function QueryPG<T: Class>(sql: string): TList<T>;
  public
    function Insert<T: Class>(Obj: TObject): Integer;
    function Query<T: Class>(sql: string): TList<T>;
    procedure Delete<T: Class>(Obj: TObject);
    procedure Update<T: Class>(Obj: TObject);
  end;

implementation

Uses
  UFieldUtil, REST.Json, UDBConnection, USystemConfig, System.Json,
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
  Contexto := TRttiContext.Create;
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

procedure TDAO.Delete<T>(Obj: TObject);
var
  fieldUtil: TFieldUtil;
  Query: TFDQuery;
  script: String;
begin
  try
    fieldUtil := TFieldUtil.Create;
    script := fieldUtil.ScriptDelete<T>(Obj);

    Query := TDBConnection.GetInstance.Query;

    if TDBConnection.autocommit then
    begin
      Query.Connection.StartTransaction;
    end;
    Query.Close;
    Query.sql.Clear;
    Query.sql.Add(script);
    Query.ExecSQL;

    if TDBConnection.autocommit then
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
            raise Exception.Create('Erro ao executar query. Erro: ' +
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
  Query: TFDQuery;
  script: TScriptInsert;
begin
  try
    fieldUtil := TFieldUtil.Create;
    script := fieldUtil.ScriptInserte<T>(Obj);

    Query := TDBConnection.GetInstance.Query;

    if TDBConnection.autocommit then
    begin
      Query.Connection.StartTransaction;
    end;
    Query.Close;
    Query.sql.Clear;
    Query.sql.Add(script.script);
    Query.Open;
    if not script.chaveprimaria.IsEmpty then
      Id := Query.FieldByName(script.chaveprimaria).AsInteger;

    if TDBConnection.autocommit then
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
            raise Exception.Create('Erro ao executar query. Erro: ' +
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

procedure TDAO.InsertPostgresql<T>(Obj: TObject);
var
  Id: Integer;
  fieldUtil: TFieldUtil;
  Query: TFDQuery;
  script: TScriptInsert;
begin
  try
    fieldUtil := TFieldUtil.Create;
    script := fieldUtil.ScriptInsertePG<T>(Obj);

    Query := TDBConnection.GetInstance.Query;

    if TDBConnection.autocommit then
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

    if TDBConnection.autocommit then
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
            raise Exception.Create('Erro ao executar query. Erro: ' +
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
  valor := tipoInstancia.MetaclassType.Create;
  result := valor.AsType<T>;
end;

function TDAO.Query<T>(sql: string): TList<T>;
begin
  if TSystemConfig.GetInstancia.tipoSGBD = tpFirebird then
    result := QueryFB<T>(sql)
  else
    result := QueryPG<T>(sql);
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
  SourceAsPointer, ResultAsPointer: Pointer;
  Prop: TRttiProperty;
  j, i: Integer;
  Query: TFDQuery;
  fieldUtil: TFieldUtil;
  strTemp: string;
begin
  try
    Query := TDBConnection.GetInstance.Query;

    if TDBConnection.autocommit then
    begin
      Query.Connection.StartTransaction;
    end;

    Query.Open(sql);

    if TDBConnection.autocommit then
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
            raise Exception.Create('Erro ao executar query. Erro: ' +
              E.Message);
          end;
        end;
      end;
    end;

    if Query.RecordCount > 0 then
    begin
      Obj := Instanciar<T>;
      c := TObject(Obj).ClassType;
      result := TList<T>.Create;

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
              Prop.SetValue(ResultAsPointer,
                TValue.From(Query.Fields[Map.indexfield].AsInteger <> 0));
            end
            else if Map.tipo = tpData then
            begin
              Prop.SetValue(ResultAsPointer,
                TValue.From(Query.Fields[Map.indexfield].AsDateTime));
            end
            else if Map.tipo = tpJsonb then
            begin
              // TJson.JsonToObject<Prop.PropertyType.ClassType>(Query.Fields[Map.indexfield].AsString);
              strTemp := Query.Fields[Map.indexfield].AsString;
              Prop.SetValue(ResultAsPointer,
                TValue.From(Query.Fields[Map.indexfield].AsString));
            end;
          except
            on E: Exception do
              raise Exception.Create('Erro preencher ' + Prop.Name + '. ERROR:'
                + E.Message);
          end;

          Inc(i);
        end;
        i := 0;

        result.Add(Obj);
        Query.Next;
      end;
    end;
  finally
    Query := nil;
    FreeAndNil(fieldUtil);
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
  Endereco: TEndereco;
  jsonutil: TJsonUtil;
begin
  try
    Query := TDBConnection.GetInstance.Query;

    if TDBConnection.autocommit then
    begin
      Query.Connection.StartTransaction;
    end;

    Query.Open(sql);

    if TDBConnection.autocommit then
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
            raise Exception.Create('Erro ao executar query. Erro: ' +
              E.Message);
          end;
        end;
      end;
    end;

    if Query.RecordCount > 0 then
    begin
      Obj := Instanciar<T>;
      c := TObject(Obj).ClassType;
      result := TList<T>.Create;

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
              Prop.SetValue(ResultAsPointer, jsonutil.JsonToObject
                (Query.Fields[Map.indexfield].AsString, Map.cjson));
            end;
          except
            on E: Exception do
              raise Exception.Create('Erro preencher ' + Prop.Name + '. ERROR:'
                + E.Message);
          end;

          Inc(i);
        end;
        i := 0;

        result.Add(Obj);
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
    fieldUtil := TFieldUtil.Create;
    script := fieldUtil.ScriptUpdate<T>(Obj);

    Query := TDBConnection.GetInstance.Query;

    if TDBConnection.autocommit then
    begin
      Query.Connection.StartTransaction;
    end;
    Query.Close;
    Query.sql.Clear;
    Query.sql.Add(script);
    Query.ExecSQL;

    if TDBConnection.autocommit then
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
            raise Exception.Create('Erro ao executar query. Erro: ' +
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

end.
