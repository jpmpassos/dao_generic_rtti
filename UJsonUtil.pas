unit UJsonUtil;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Classes;

type
  TTipoCampo = (tpInicio, tpCampo, tpValor, tpFim);

type
  TJsonString = class
  private
    Fcampo: string;
    Fvalor: string;
    Fvalorobjeto: TObject;
  published
    constructor Create();
    property campo: string read Fcampo write Fcampo;
    property valor: string read Fvalor write Fvalor;
    property valorobjeto: TObject read Fvalorobjeto write Fvalorobjeto;
  end;

type
  TOBJson = class
  private
    Fcampos: TList<TJsonString>;
  published
    constructor Create();
    property campos: TList<TJsonString> read Fcampos write Fcampos;
  end;

type
  TJsonUtil = class
  private
    function ExtractStringsModificada(Separators, WhiteSpace: TSysCharSet;
      Content: PChar; Strings: TStrings): Integer;
    function RecuperarJsonString(str: TStringList): TJsonString;

    function carregarObjeto(var json: string): TOBJson;
    function carregarCamposObjeto(var json: string): TJsonString;
  published
    function JsonToObject(json: string; Tcjson: TClass): TObject;
  end;

implementation

uses
  System.Rtti, UAttributes, System.TypInfo, UFieldUtil;

{ TJsonUtil }

function TJsonUtil.carregarCamposObjeto(var json: string): TJsonString;
var
  tipo: TTipoCampo;
  p, p2: Integer;
  str: string;
begin
  Result := TJsonString.Create;
  tipo := tpCampo;

  if not json.Trim.IsEmpty then
  begin
    while tpFim <> tipo do
    begin
      str := Copy(json, 1, 1);
      if (tipo <> tpValor) or (str = ' ') or (str = '"') then
        json := Copy(json, 2, Length(json) - 1);

      if str = '{' then
      begin
        Result.valorobjeto := carregarObjeto(json) as TOBJson;
      end
      else if (str = '"') or (tipo = tpValor) then
      begin
        if tipo = tpCampo then
        begin
          p := Pos('"', json);
          Result.campo := Copy(json, 1, p - 1);
          json := Copy(json, p + 1, Length(json) - p + 1);
        end
        else if (tipo = tpValor) and (str <> '"') then
        begin
          if (str <> ' ') then
          begin
            p := Pos(',', json);
            p2 := Pos('}', json);
            if (p > p2) and (p > 0) then
            begin
              p := p2;
            end;
            Result.valor := Copy(json, 1, p - 1);
            json := Copy(json, p + 1, Length(json) - p + 1);
            tipo := tpFim;
          end;
        end
        else if (tipo = tpValor) and (str = '"') then
        begin
          p := Pos('"', json);
          Result.valor := Copy(json, 1, p - 1);
          json := Copy(json, p + 1, Length(json) - p + 1);
          tipo := tpFim;
        end;
      end
      else if str = ':' then
      begin
        tipo := tpValor;
      end;
    end;
  end;
end;

function TJsonUtil.carregarObjeto(var json: string): TOBJson;
var
  tipo: TTipoCampo;
  str: string;
begin
  Result := TOBJson.Create;
  if not json.Trim.IsEmpty then
  begin
    while tpFim <> tipo do
    begin
      str := Copy(json, 1, 1);
      if str = '{' then
      begin
        json := Copy(json, 2, Length(json) - 1);
        Result.campos.Add(carregarCamposObjeto(json));
      end
      else if str = '"' then
      begin
        Result.campos.Add(carregarCamposObjeto(json));
      end
      else if str = '}' then
      begin
        tipo := tpFim;
      end
      else
      begin
        json := Copy(json, 2, Length(json) - 1);
      end;
    end;
  end;

end;

function TJsonUtil.JsonToObject(json: string;Tcjson: TClass): TObject;
var
  terminar: Boolean;
  Method: TRttiMethod;
  value: TValue;
  Context: TRttiContext;
  TypObj: TRttiType;
  instancia: TRttiInstanceType;
  p: Pointer;
  Prop: TRttiProperty;
  j, i: Integer;
  strTemp: string;
  Atributo: TCustomAttribute;
  objson: TOBJson;
  camposjson: TList<TJsonString>;
  ResultAsPointer: Pointer;
  Maps: TList<TMapFieldProp>;
  fieldUtil: TFieldUtil;
  Map: TMapFieldProp;
begin
  objson := carregarObjeto(json);
  // instancia := (C.FindType(Str_Class.AsString) as TRttiInstanceType);


  Result := Tcjson.Create;
  TypObj := Context.GetType(Tcjson);
  Maps := fieldUtil.getMapObj(TypObj);
  Move(Result, ResultAsPointer, SizeOf(Pointer));

  while objson.campos.Count > i do
  begin
    j := 0;
    while Maps.Count > j do
    begin
      Map := Maps[j];
      if Map.nomecampo = objson.campos[i].campo then
      begin
        try
          Prop := TypObj.GetProperties[Map.indexprop];
          if Map.tipo = tpString then
          begin
            Prop.SetValue(ResultAsPointer, TValue.From(objson.campos[i].valor));
          end
          else if Map.tipo = tpBoleano then
          begin
            Prop.SetValue(ResultAsPointer,
              TValue.From(StrToBool(objson.campos[i].valor)));
          end
          else if Map.tipo = tpFloat then
          begin
            Prop.SetValue(ResultAsPointer,
              TValue.From(objson.campos[i].valor.ToDouble()));
          end
          else if Map.tipo = tpInteger then
          begin
            Prop.SetValue(ResultAsPointer,
              TValue.From(objson.campos[i].valor.ToInteger()));
          end
          else if Map.tipo = tpData then
          begin
            Prop.SetValue(ResultAsPointer,
              TValue.From(StrToDate(objson.campos[i].valor)));
          end;
        except
          on E: Exception do
            raise Exception.Create('Erro preencher ' + Prop.Name + '. ERROR:' +
              E.Message);
        end;

        Maps.Remove(Map);
        j := Maps.Count;
      end;
      Inc(j);
    end;

    Inc(i);
  end;
end;

function TJsonUtil.ExtractStringsModificada(Separators, WhiteSpace: TSysCharSet;
  Content: PChar; Strings: TStrings): Integer;
var
  Head, Tail: PChar;
  EOS, InQuote: Boolean;
  QuoteChar: Char;
  Item: string;
begin
  Result := 0;
  if (Content = nil) or (Content^ = #0) or (Strings = nil) then
    Exit;
  Tail := Content;
  InQuote := false;
  QuoteChar := #0;
  Strings.BeginUpdate;
  try
    Include(WhiteSpace, #13);
    Include(WhiteSpace, #10);

    Include(Separators, #0);
    Include(Separators, #13);
    Include(Separators, #10);
    // Include(Separators, '''');
    // Include(Separators, '"');
    repeat
      while (Tail^ in WhiteSpace) do
        Inc(Tail);
      Head := Tail;
      while true do
      begin
        while (InQuote and not((Tail^ = #0) or (Tail^ = QuoteChar))) or
          not(Tail^ in Separators) do
          Inc(Tail);
        if (Tail^ in ['''', '"']) then
        begin
          if (QuoteChar <> #0) and (QuoteChar = Tail^) then
            QuoteChar := #0
          else if QuoteChar = #0 then
            QuoteChar := Tail^;
          InQuote := QuoteChar <> #0;
          Inc(Tail);
        end
        else
          Break;
      end;
      EOS := Tail^ = #0;
      // if (Head <> Tail)  then
      begin
        if Strings <> nil then
        begin
          SetString(Item, Head, Tail - Head);
          Strings.Add(Item);
        end;
        Inc(Result);
      end;
      Inc(Tail);
    until EOS;
  finally
    Strings.EndUpdate;
  end;
end;

function TJsonUtil.RecuperarJsonString(str: TStringList): TJsonString;
begin
  Result := TJsonString.Create;
  Result.campo := str.Strings[0];
  Result.valor := str.Strings[1];
end;

{ TJsonString }

{ TJsonString }

constructor TJsonString.Create;
begin
  Self.Fvalorobjeto := nil;
  Self.Fcampo := EmptyStr;
  Self.Fvalor := EmptyStr;
end;

{ TOBJson }

constructor TOBJson.Create();
begin
  Fcampos := TList<TJsonString>.Create;
end;

end.
