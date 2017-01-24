unit UFieldUtil;

interface

Uses
  FireDAC.Comp.Client, UConexoes, Rtti, UAttributes,
  Generics.Collections, FireDAC.dapt, Data.DB, USystemConfig;

type
  TScriptInsert = class
  private
    Fscript: String;
    Fchaveprimaria: String;
    Fscriptpgequencia: string;
  public
    property script: String read Fscript write Fscript;
    property chaveprimaria: String read Fchaveprimaria write Fchaveprimaria;
    property scriptpgequencia: string read Fscriptpgequencia
      write Fscriptpgequencia;
  end;

  TMapFieldProp = class
  private
    Findexfield: Integer;
    Findexprop: Integer;
    Ftipo: TTipo;
    Fclasstring: string;
    Fnomecampo: string;
    Fcjson: TClass;

  public
    property indexfield: Integer read Findexfield write Findexfield;
    property indexprop: Integer read Findexprop write Findexprop;
    property tipo: TTipo read Ftipo write Ftipo;
    property classtring: string read Fclasstring write Fclasstring;
    property cjson: TClass read Fcjson write Fcjson;
    property nomecampo: string read Fnomecampo write Fnomecampo;
  end;

  TFieldUtil = class
  private
    Fdquery: TFDQuery;
    function getTipoCampo(Prop: TRttiProperty; Atributo: TCustomAttribute;
      Instance: Pointer): TTipo;
    function PropIsId(Atributo: TCustomAttribute; Prop: TRttiProperty): Boolean;
    function IsAutoincremente(Atributo: TCustomAttribute;
      Prop: TRttiProperty): Boolean;
    function GetSequencia(Atributo: TCustomAttribute;
      Prop: TRttiProperty): string;
    function GetCampoValor(tipo: TTipo; Prop: TRttiProperty;
      Atributo: TCustomAttribute; Obj: TObject): String;
    function GetNomeTabela(Obj: TObject): String;
    function GetNomePrimaryKey(Obj: TObject): String;
    procedure GetCamposValores(var strValues: string; tipo: TTipo;
      Prop: TRttiProperty; Atributo: TCustomAttribute; Obj: TObject);

  public
    function getMap(query: TFDQuery; TypObj: TRttiType; Instance: Pointer)
      : TList<TMapFieldProp>;
    function getMapObj(TypObj: TRttiType): TList<TMapFieldProp>;
    function getObjetoJson(jsonstr: string; TypObj: TRttiType;
      Instance: Pointer): TObject;

    function ScriptInserte<T>(Obj: TObject): TScriptInsert;
    function ScriptInsertePG<T>(Obj: TObject): TScriptInsert;

    function ScriptUpdate<T>(Obj: TObject): String;

    function ScriptDelete<T>(Obj: TObject): String;
  published
    { published declarations }
  end;

implementation

uses
  System.SysUtils;

{ TFieldUtil }

function TFieldUtil.GetNomePrimaryKey(Obj: TObject): String;
var
  Contexto: TRttiContext;
  TypObj: TRttiType;
  Atributo: TCustomAttribute;
  strTable: String;
begin
  Contexto := TRttiContext.Create;
  TypObj := Contexto.GetType(TObject(Obj).ClassInfo);
  for Atributo in TypObj.GetAttributes do
  begin
    // if Atributo is PrimaryKeyAttribute then
    // Exit(PrimaryKeyAttribute(Atributo).nome);
  end;
end;

function TFieldUtil.GetNomeTabela(Obj: TObject): String;
var
  Contexto: TRttiContext;
  TypObj: TRttiType;
  Atributo: TCustomAttribute;
  strTable: String;
begin
  Contexto := TRttiContext.Create;
  TypObj := Contexto.GetType(TObject(Obj).ClassInfo);
  for Atributo in TypObj.GetAttributes do
  begin
    if Atributo is TabelaAttribute then
      Exit(TabelaAttribute(Atributo).nome);
  end;
end;

function TFieldUtil.getObjetoJson(jsonstr: string; TypObj: TRttiType;
  Instance: Pointer): TObject;
var
  Contexto: TRttiContext;
  Prop: TRttiProperty;
  strField: String;
  Atributo: TCustomAttribute;
  index, i: Integer;
  map: TMapFieldProp;
  instancia: TRttiInstanceType;
  Context: TRttiContext;
begin
  Result := TList<TMapFieldProp>.Create;

  i := 0;
  while Length(TypObj.GetProperties) > i do
  begin
    Prop := TypObj.GetProperties[i];
    for Atributo in Prop.GetAttributes do
    begin
      if Atributo is CampoAttribute then
      begin
        strField := CampoAttribute(Atributo).nome;

        // index := query.FieldByName(strField).index;
        if index >= 0 then
        begin
          map := TMapFieldProp.Create;
          map.indexfield := index;
          map.indexprop := i;
          map.tipo := CampoAttribute(Atributo).tipo;
          if map.tipo = tpJsonb then
          begin
            map.classtring := CampoAttribute(Atributo).classobj;
            instancia := (Context.FindType(CampoAttribute(Atributo).classobj)
              as TRttiInstanceType);
            map.cjson := instancia.MetaclassType;
          end;

          // getTipoCampo(Prop, Atributo, Instance);
          // Result.Add(map);
          Break;
        end
        else
          raise Exception.Create('Erro ao encontrar field ' + strField);
      end;
    end;
    Inc(i);
  end;

  // if Result.Count = 0 then
  FreeAndNil(Result);
end;

function TFieldUtil.GetSequencia(Atributo: TCustomAttribute;
  Prop: TRttiProperty): string;
begin
  Result := '';
  for Atributo in Prop.GetAttributes do
  begin
    if Atributo is AutoIncrementoAttribute then
    begin
      Exit(AutoIncrementoAttribute(Atributo).sequencia);
    end;
  end;
end;

function TFieldUtil.getTipoCampo(Prop: TRttiProperty;
  Atributo: TCustomAttribute; Instance: Pointer): TTipo;
begin
  case Prop.GetValue(Instance).Kind of

    tkWChar, tkLString, tkWString, tkString, tkChar, tkUString:
      begin
        Exit(tpString);
      end;

    tkInteger, tkInt64:
      begin
        Exit(tpInteger);
      end;

    tkFloat:
      begin
        // if CampoAttribute(Atributo).Data then
        // Exit(tpData)
        // else
        Exit(tpFloat);
      end

  else
    begin
      // if CampoAttribute(Atributo).boleano then
      begin
        Exit(tpBoleano);
      end;
    end;
  end;
end;

function TFieldUtil.IsAutoincremente(Atributo: TCustomAttribute;
  Prop: TRttiProperty): Boolean;
begin
  Result := False;
  for Atributo in Prop.GetAttributes do
  begin
    if Atributo is AutoIncrementoAttribute then
    begin
      Exit(True);
    end;
  end;
end;

function TFieldUtil.PropIsId(Atributo: TCustomAttribute;
  Prop: TRttiProperty): Boolean;
begin
  Result := False;
  for Atributo in Prop.GetAttributes do
  begin
    // Só aceita apenas um campo como chave primaria
    if Atributo is IdAttribute then
    begin
      Exit(True);
    end;
  end;
end;

function TFieldUtil.ScriptDelete<T>(Obj: TObject): String;
var
  Contexto: TRttiContext;
  TypObj: TRttiType;
  Prop: TRttiProperty;
  strDelete, strWhere, strValuePK: String;
  IsId: Boolean;
  Atributo: TCustomAttribute;
  id: Integer;
  query: TFDQuery;
begin
  strDelete := '';
  strWhere := '';
  strValuePK := '';

  strDelete := 'DELETE FROM ' + GetNomeTabela(Obj);

  Contexto := TRttiContext.Create;
  TypObj := Contexto.GetType(TObject(Obj).ClassInfo);

  for Prop in TypObj.GetProperties do
  begin
    IsId := PropIsId(Atributo, Prop);

    for Atributo in Prop.GetAttributes do
    begin
      if Atributo is CampoAttribute then
      begin
        if IsId then
        begin
          strValuePK := GetCampoValor(CampoAttribute(Atributo).tipo, Prop,
            Atributo, Obj);

          if strValuePK.IsEmpty then
            raise Exception.Create('Valor da chave primária não encontrada!');

          strWhere := ' where ' + CampoAttribute(Atributo).nome + ' = ' +
            strValuePK;

          Break;
        end;
      end;
    end;
  end;

  if strWhere.IsEmpty then
    raise Exception.Create('Chave primária não encontrada!');

  Result := strDelete + strWhere;
end;

function TFieldUtil.ScriptInserte<T>(Obj: TObject): TScriptInsert;
var
  Contexto: TRttiContext;
  TypObj: TRttiType;
  Prop: TRttiProperty;
  strInsert, strFields, strValues, strPrimaryKey, strTabela,
    strSequencia: String;
  IsId, IsAutoincr: Boolean;
  Atributo: TCustomAttribute;
  id: Integer;
  query: TFDQuery;
begin
  Result := TScriptInsert.Create;
  strInsert := '';
  strPrimaryKey := '';
  strFields := '';
  strValues := '';
  strTabela := '';

  strTabela := GetNomeTabela(Obj);
  strInsert := 'INSERT INTO ' + strTabela;
  strPrimaryKey := GetNomePrimaryKey(Obj);

  Contexto := TRttiContext.Create;
  TypObj := Contexto.GetType(TObject(Obj).ClassInfo);

  for Prop in TypObj.GetProperties do
  begin
    IsId := PropIsId(Atributo, Prop);

    if IsId then
    begin
      if TSystemConfig.GetInstancia.Tiposgbd = tpFirebird then
        IsAutoincr := IsAutoincremente(Atributo, Prop)
      else if TSystemConfig.GetInstancia.Tiposgbd = tpPostgreSQL then
      begin
        strSequencia := GetSequencia(Atributo, Prop);
        if strSequencia <> '' then
        begin
          IsAutoincr := True;
        end;
      end;
    end;

    for Atributo in Prop.GetAttributes do
    begin
      if Atributo is CampoAttribute then
      begin
        if IsId then
        begin
          strPrimaryKey := CampoAttribute(Atributo).nome;
          if IsAutoincr then
          begin
            strFields := strFields + CampoAttribute(Atributo).nome + ',';

            strValues := strValues + 'null,';
          end
          else
          begin
            strFields := strFields + CampoAttribute(Atributo).nome + ',';

            GetCamposValores(strValues, CampoAttribute(Atributo).tipo, Prop,
              Atributo, Obj);
          end;
        end
        else
        begin
          strFields := strFields + CampoAttribute(Atributo).nome + ',';

          GetCamposValores(strValues, CampoAttribute(Atributo).tipo, Prop,
            Atributo, Obj);
        end;

        Break;
      end;
    end;
  end;

  strFields := Copy(strFields, 1, Length(strFields) - 1);
  strValues := Copy(strValues, 1, Length(strValues) - 1);
  strInsert := strInsert + ' ( ' + strFields + ' )  VALUES ( ' +
    strValues + ' )';

  if (trim(strPrimaryKey) <> '') and
    (TSystemConfig.GetInstancia.Tiposgbd = tpFirebird) then
    strInsert := strInsert + ' RETURNING ' + strPrimaryKey + ';';

  if IsAutoincr and (TSystemConfig.GetInstancia.Tiposgbd = tpPostgreSQL) and
    not strSequencia.IsEmpty then
  begin
    Result.scriptpgequencia := 'Select currval(''' + strSequencia +
      ''') as cod from ' + strTabela;
  end;

  Result.script := strInsert;
  Result.chaveprimaria := strPrimaryKey;

end;

function TFieldUtil.ScriptInsertePG<T>(Obj: TObject): TScriptInsert;
var
  Contexto: TRttiContext;
  TypObj: TRttiType;
  Prop: TRttiProperty;
  strInsert, strFields, strValues, strPrimaryKey, strTabela,
    strSequencia: String;
  IsId, IsAutoincr: Boolean;
  Atributo: TCustomAttribute;
  id: Integer;
  query: TFDQuery;
begin
  Result := TScriptInsert.Create;
  strInsert := '';
  strPrimaryKey := '';
  strFields := '';
  strValues := '';
  strTabela := '';

  strTabela := GetNomeTabela(Obj);
  strInsert := 'INSERT INTO ' + strTabela;
  strPrimaryKey := GetNomePrimaryKey(Obj);

  Contexto := TRttiContext.Create;
  TypObj := Contexto.GetType(TObject(Obj).ClassInfo);

  for Prop in TypObj.GetProperties do
  begin
    IsId := PropIsId(Atributo, Prop);

    if IsId then
    begin
      if TSystemConfig.GetInstancia.Tiposgbd = tpFirebird then
        IsAutoincr := IsAutoincremente(Atributo, Prop)
      else if TSystemConfig.GetInstancia.Tiposgbd = tpPostgreSQL then
      begin
        strSequencia := GetSequencia(Atributo, Prop);
        if strSequencia <> '' then
        begin
          IsAutoincr := True;
        end;
      end;
    end;

    for Atributo in Prop.GetAttributes do
    begin
      if Atributo is CampoAttribute then
      begin
        if IsId then
        begin
          strPrimaryKey := CampoAttribute(Atributo).nome;
        end
        else
        begin
          strFields := strFields + CampoAttribute(Atributo).nome + ',';

          GetCamposValores(strValues, CampoAttribute(Atributo).tipo, Prop,
            Atributo, Obj);
        end;

        Break;
      end;
    end;
  end;

  strFields := Copy(strFields, 1, Length(strFields) - 1);
  strValues := Copy(strValues, 1, Length(strValues) - 1);
  strInsert := strInsert + ' ( ' + strFields + ' )  VALUES ( ' +
    strValues + ' )';

  if (trim(strPrimaryKey) <> '') and
    (TSystemConfig.GetInstancia.Tiposgbd = tpFirebird) then
    strInsert := strInsert + ' RETURNING ' + strPrimaryKey + ';';

  if IsAutoincr and (TSystemConfig.GetInstancia.Tiposgbd = tpPostgreSQL) and
    not strSequencia.IsEmpty then
  begin
    Result.scriptpgequencia := 'Select currval(''' + strSequencia +
      ''') as cod from ' + strTabela;
  end;

  Result.script := strInsert;
  Result.chaveprimaria := strPrimaryKey;

end;

function TFieldUtil.ScriptUpdate<T>(Obj: TObject): String;
var
  Contexto: TRttiContext;
  TypObj: TRttiType;
  Prop: TRttiProperty;
  strUpdate, strFields, strValues, strWhere, strValuePK: String;
  IsId, IsAutoincremente: Boolean;
  Atributo: TCustomAttribute;
  id: Integer;
  query: TFDQuery;
begin
  strUpdate := '';
  strWhere := '';
  strFields := '';
  strValues := '';
  strValuePK := '';

  strUpdate := 'UPDATE ' + GetNomeTabela(Obj) + ' SET ';

  Contexto := TRttiContext.Create;
  TypObj := Contexto.GetType(TObject(Obj).ClassInfo);

  for Prop in TypObj.GetProperties do
  begin
    IsId := PropIsId(Atributo, Prop);

    for Atributo in Prop.GetAttributes do
    begin
      if Atributo is CampoAttribute then
      begin
        if IsId then
        begin
          strValuePK := GetCampoValor(CampoAttribute(Atributo).tipo, Prop,
            Atributo, Obj);

          if strValuePK.IsEmpty then
            raise Exception.Create('Valor da chave primária não encontrada!');

          strWhere := ' where ' + CampoAttribute(Atributo).nome + ' = ' +
            strValuePK;
        end
        else
        begin
          if not strFields.IsEmpty then
            strFields := strFields + ', ';

          strFields := strFields + CampoAttribute(Atributo).nome + ' = ' +
            GetCampoValor(CampoAttribute(Atributo).tipo, Prop, Atributo, Obj);
        end;
      end;
    end;
  end;

  if strWhere.IsEmpty then
    raise Exception.Create('Chave primária não encontrada!');

  Result := strUpdate + strFields + strWhere;
end;

procedure TFieldUtil.GetCamposValores(var strValues: string; tipo: TTipo;
  Prop: TRttiProperty; Atributo: TCustomAttribute; Obj: TObject);
begin
  case tipo of
    tpString:
      begin
        strValues := strValues + QuotedStr(Prop.GetValue(TObject(Obj))
          .AsString) + ',';
      end;

    tpInteger:
      begin
        strValues := strValues + IntToStr(Prop.GetValue(TObject(Obj))
          .AsInteger) + ',';
      end;

    tpCurrency, tpFloat:
      begin
        strValues := strValues + StringReplace
          (FloatToStr(Prop.GetValue(TObject(Obj)).AsExtended), ',', '.',
          [rfReplaceAll]) + ',';
      end;

    tpData:
      begin
        strValues := strValues + QuotedStr(FormatDateTime('dd.MM.yyyy',
          Prop.GetValue(TObject(Obj)).AsVariant)) + ','
      end;

    tpDataTime:
      begin
        strValues := strValues + QuotedStr(FormatDateTime('dd.MM.yyyy hh:MM:ss',
          Prop.GetValue(TObject(Obj)).AsVariant)) + ','
      end;

    tpBoleano:
      begin
        strValues := strValues + BoolToStr(Prop.GetValue(TObject(Obj))
          .AsVariant) + ',';;
      end;
  end;

end;

function TFieldUtil.GetCampoValor(tipo: TTipo; Prop: TRttiProperty;
  Atributo: TCustomAttribute; Obj: TObject): String;
begin
  case tipo of
    tpString:
      begin
        Exit(QuotedStr(Prop.GetValue(TObject(Obj)).AsString));
      end;

    tpInteger:
      begin
        Exit(IntToStr(Prop.GetValue(TObject(Obj)).AsInteger));
      end;

    tpCurrency, tpFloat:
      begin
        Exit(StringReplace(FloatToStr(Prop.GetValue(TObject(Obj)).AsExtended),
          ',', '.', [rfReplaceAll]));
      end;

    tpData:
      begin
        Exit(QuotedStr(FormatDateTime('dd.MM.yyyy', Prop.GetValue(TObject(Obj))
          .AsVariant)));
      end;

    tpDataTime:
      begin
        Exit(QuotedStr(FormatDateTime('dd.MM.yyyy hh:MM:ss',
          Prop.GetValue(TObject(Obj)).AsVariant)));
      end;

    tpBoleano:
      begin
        Exit(BoolToStr(Prop.GetValue(TObject(Obj)).AsVariant));
      end;
  end;
end;

function TFieldUtil.getMap(query: TFDQuery; TypObj: TRttiType;
  Instance: Pointer): TList<TMapFieldProp>;
var
  Contexto: TRttiContext;
  Prop: TRttiProperty;
  strField: String;
  Atributo: TCustomAttribute;
  index, i: Integer;
  map: TMapFieldProp;
  instancia: TRttiInstanceType;
  Context: TRttiContext;
begin
  Result := TList<TMapFieldProp>.Create;

  i := 0;
  while Length(TypObj.GetProperties) > i do
  begin
    Prop := TypObj.GetProperties[i];
    for Atributo in Prop.GetAttributes do
    begin
      if Atributo is CampoAttribute then
      begin
        strField := CampoAttribute(Atributo).nome;

        index := query.FieldByName(strField).index;
        if index >= 0 then
        begin
          map := TMapFieldProp.Create;
          map.indexfield := index;
          map.indexprop := i;
          map.tipo := CampoAttribute(Atributo).tipo;
          if map.tipo = tpJsonb then
          begin
            map.classtring := CampoAttribute(Atributo).classobj;
            instancia := (Context.FindType(CampoAttribute(Atributo).classobj)
              as TRttiInstanceType);
            map.cjson := instancia.MetaclassType;
          end;

          // getTipoCampo(Prop, Atributo, Instance);
          Result.Add(map);
          Break;
        end
        else
          raise Exception.Create('Erro ao encontrar field ' + strField);
      end;
    end;
    Inc(i);
  end;

  if Result.Count = 0 then
    FreeAndNil(Result);
end;

function TFieldUtil.getMapObj(TypObj: TRttiType): TList<TMapFieldProp>;
var
  Contexto: TRttiContext;
  Prop: TRttiProperty;
  strField: String;
  Atributo: TCustomAttribute;
  index, i: Integer;
  map: TMapFieldProp;
  instancia: TRttiInstanceType;
  Context: TRttiContext;
begin
  Result := TList<TMapFieldProp>.Create;

  i := 0;
  while Length(TypObj.GetProperties) > i do
  begin
    Prop := TypObj.GetProperties[i];
    for Atributo in Prop.GetAttributes do
    begin
      if Atributo is CampoAttribute then
      begin
        strField := CampoAttribute(Atributo).nome;
        map := TMapFieldProp.Create;
        map.indexprop := i;
        map.nomecampo := strField;
        map.tipo := CampoAttribute(Atributo).tipo;
        if map.tipo = tpJsonb then
          map.classtring := CampoAttribute(Atributo).classobj;;
        Result.Add(map);
        Break;
      end;
    end;
    Inc(i);
  end;

  if Result.Count = 0 then
    FreeAndNil(Result);
end;

end.
