unit UObjFunctions;

interface

Uses
  Vcl.StdCtrls, Generics.Collections, System.Rtti, System.AnsiStrings,
  System.Classes, System.TypInfo, System.Generics.Defaults;

type
  TObjFunctions<T: Class> = Class
  private
    class function QuickBuscaPart(busca: Variant; Lista: TList<T>;
      i, j: Integer; IndexName: Integer; ctx: TRttiContext): T;
    class procedure QuickSortPartCres(Lista: TList<T>; iLo, iHi: Integer;
      IndexName: Integer; ctx: TRttiContext);
    class procedure QuickSortPartDecr(Lista: TList<T>; iLo, iHi: Integer;
      IndexName: Integer; ctx: TRttiContext);
    class function CompararLista(lista1, lista2: TList<T>; IndexName: Integer;
      ctx: TRttiContext): TList<T>;

    class function criarInstancia: T;

    class procedure clonarObjeto(Origem, Destino: T);
  public
    class function CompararObj(Obj1, Obj2: TObject): Boolean;
    class function CompararListaObj(lista1, lista2: TList<T>; FieldName: String)
      : TList<T>;
    class function QuickBusca(busca: Variant; Lista: TList<T>;
      FieldName: String): T;
    class procedure SortComponents(var Lista: TList<TComponent>;
      max, min: Integer);
    class procedure QuickSort(Lista: TList<T>; FieldName: String;
      Ordem: String = 'CRES');
    class procedure DestroyList(var Lista: TList<T>);

    class procedure clone(var classeClone: T; classe: T);

    class function cloneLista(Lista: TList<T>): TObjectList<T>;

    class function DiferencaListaAListaB(listaA, listaB: TList<T>;
      const Comparer: IComparer<T>): TObjectList<T>;
  End;

type
  TCtrObjectCombo<T: Class> = Class
  private
    ListObject: TList<T>;

  public
    procedure CarregaComboObject(var AComboBox: TComboBox; Lista: TList<T>;
      FieldName: String);
    function GetListObject(ItemIndexCombo: Integer): T;
    procedure SetIndexCombo(var AComboBox: TComboBox; ItemCombo: String);

  End;

implementation

uses
  System.SysUtils;

{ TObjFunctions }

class procedure TObjFunctions<T>.clonarObjeto(Origem, Destino: T);
Var
  vContext: TRttiContext;
  vRtti: TRttiType;
  vProperty: TRttiProperty;
  vSourcePointer, vDestinyPointer: Pointer;
begin
  vContext := TRttiContext.Create;
  try
    vRtti := vContext.GetType(Origem.ClassType);

    Move(Origem, vSourcePointer, SizeOf(Pointer));
    Move(Destino, vDestinyPointer, SizeOf(Pointer));

    for vProperty in vRtti.GetProperties do
    begin
      vProperty.Name;

      if vProperty.PropertyType.TypeKind = tkClass then
      begin
        if vProperty.IsWritable then
          vProperty.SetValue(vDestinyPointer, criarInstancia);
      end
      else
      begin
        if vProperty.IsWritable then
          vProperty.SetValue(vDestinyPointer,
            vProperty.GetValue(vSourcePointer));
      end;
    end;
  finally
    vContext.Free;
  end;
end;

class procedure TObjFunctions<T>.clone(var classeClone: T; classe: T);
var
  contextRtti: TRttiContext;
  rttiType: TRttiType;
  aProp: TRttiProperty;
  attr: TCustomAttribute;
begin
  try
    try
      contextRtti := TRttiContext.Create;

      rttiType := contextRtti.GetType(TObject(classe).ClassInfo);

      for aProp in rttiType.GetProperties do
        for attr in aProp.GetAttributes do
          aProp.SetValue(TObject(classeClone), aProp.GetValue(TObject(classe)));

    except
      on E: Exception do
      begin
        raise Exception.Create('Falha ao fazer backup do Objeto!' + sLineBreak +
          E.Message);
      end;
    end;
  finally
    contextRtti.Free;
  end;
end;

class function TObjFunctions<T>.cloneLista(Lista: TList<T>): TObjectList<T>;
Var
  Item: T;
  i: Integer;

  valor: TValue;
  ctx: TRttiContext;
  tipo: TRttiType;
  tipoInstancia: TRttiInstanceType;
begin
  Result := TObjectList<T>.Create;

  for i := 0 to Lista.Count - 1 do
  begin
    Item := criarInstancia;

    clonarObjeto(Lista[i], Item);

    Result.Add(Item);
  end;
end;

class function TObjFunctions<T>.CompararLista(lista1, lista2: TList<T>;
  IndexName: Integer; ctx: TRttiContext): TList<T>;
var
  i, j: Integer;
begin
  i := 0;
  j := 0;

  Result := TList<T>.Create;

  while (lista1.Count > i) and (lista2.Count > j) do
  begin

    if ctx.GetType(TObject(lista1[i]).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(lista1[i])).AsVariant = ctx.GetType
      (TObject(lista2[j]).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(lista2[j])).AsVariant then
    begin
      if not ctx.GetType(TObject(lista1[i]).ClassInfo).Equals(lista2[j]) then
        Result.Add(lista1[i]);
      Inc(i);
      Inc(j);
    end
    else if ctx.GetType(TObject(lista1[i]).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(lista1[i])).AsVariant <
      ctx.GetType(TObject(lista2[j]).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(lista2[j])).AsVariant then
    begin
      Result.Add(lista1[i]);
      Inc(i);
    end
    else
    begin
      Inc(j);
    end;
  end;

  try
    if Result.Count = 0 then
      FreeAndNil(Result)
  except
    on E: Exception do
      Result := nil;
  end;
end;

class function TObjFunctions<T>.CompararListaObj(lista1, lista2: TList<T>;
  FieldName: String): TList<T>;
var
  ctx: TRttiContext;
  RTT: TRttiType;
  Obj1: T;
  i: Integer;
begin
  try
    if NOT Assigned(lista1) then
      Exit(NIL);

    if NOT Assigned(lista2) then
      Exit(lista1);

    // RTTI - cria o objeto contexto que serve para recuperar toda informação do objeto.
    ctx := TRttiContext.Create;

    Obj1 := lista1[0];
    RTT := ctx.GetType(Obj1.ClassInfo);

    for i := 0 to Length(RTT.GetProperties) - 1 do
    begin
      if UpperCase(RTT.GetProperties[i].Name) = UpperCase(FieldName) then
      begin
        Result := CompararLista(lista1, lista2, 1, ctx);
        Break;
      end;
    end;
  except
    on E: Exception do
      Result := nil;
  end;
end;

class function TObjFunctions<T>.CompararObj(Obj1, Obj2: TObject): Boolean;
Var
  ctx: TRttiContext;
  rtt1, rtt2: TRttiType;
  strValue: String;
  i: Integer;
begin
  try
    Result := true;

    ctx := TRttiContext.Create;
    rtt1 := ctx.GetType(Obj1.ClassInfo);
    rtt2 := ctx.GetType(Obj2.ClassInfo);

    if rtt1.ClassType <> rtt2.ClassType then
    begin
      Result := false;
    end
    else if ((Obj1 = nil) and (Obj2 <> nil)) or ((Obj2 = nil) and (Obj1 <> nil))
    then
    begin
      Result := false;
    end
    else
    begin
      i := 0;
      while i < Length(rtt1.GetProperties) do
      begin
        if rtt1.GetProperties[i].GetValue(TObject(Obj1)).ToString <>
          rtt2.GetProperties[i].GetValue(TObject(Obj2)).ToString then
        begin
          Result := false;
          i := Length(rtt1.GetProperties);
        end;
        i := i + 1;
      end;
    end;
  finally
    ctx.Free;
  end;
end;

class function TObjFunctions<T>.criarInstancia: T;
var
  valor: TValue;
  ctx: TRttiContext;
  tipo: TRttiType;
  tipoInstancia: TRttiInstanceType;
begin
  tipo := ctx.GetType(TypeInfo(T));
  tipoInstancia := (ctx.FindType(tipo.QualifiedName) as TRttiInstanceType);
  valor := tipoInstancia.MetaclassType.Create;
  Result := valor.AsType<T>;
end;

{ TCrtObjectCombo<T> }

procedure TCtrObjectCombo<T>.CarregaComboObject(var AComboBox: TComboBox;
  Lista: TList<T>; FieldName: String);
var
  ctx: TRttiContext;
  RTT: TRttiType;
  RTP: TRttiProperty;
  strValue: String;
  obj: T;
  i: Integer;
begin
  if not Assigned(Lista) then
    Exit;

  // RTTI - cria o objeto contexto que serve para recuperar toda informação do objeto.
  ctx := TRttiContext.Create;

  // Salva uma copia da lista no Objeto tipo CtrObjectCombo<T>
  Self.ListObject := Lista;
  // limpa o ComboBox passado como paramentro Var
  AComboBox.Clear;

  // Percorre a lista de objetos passada como parametro
  for obj in Lista do
  begin
    // RTTI - recupera toda a informação do atual Objeto da lista para o RttiType
    RTT := ctx.GetType(TObject(obj).ClassInfo);

    // RTTI -  Percorre uma lista de Properties
    for RTP in RTT.GetProperties do
    begin
      // RTTI - busca a Propiedade cujo o nome é igual ao passado como parametro
      if UpperCase(RTP.Name) = UpperCase(FieldName) then
      begin
        // RTTI - insere a descrição no ComboBox
        AComboBox.Items.Add(RTP.GetValue(TObject(obj)).ToString);
      end;
    end;
  end;
end;

function TCtrObjectCombo<T>.GetListObject(ItemIndexCombo: Integer): T;
begin
  try
    if Assigned(ListObject.Items[ItemIndexCombo]) then
    begin
      Result := ListObject.Items[ItemIndexCombo];
    end
    else
    begin
      Result := nil;
    end;
  except
    on E: Exception do
      Result := nil;
  end;
end;

procedure TCtrObjectCombo<T>.SetIndexCombo(var AComboBox: TComboBox;
  ItemCombo: String);
var
  Aux: Integer;
begin
  Aux := 0;

  while Aux < AComboBox.Items.Count do
  begin
    if UpperCase(AComboBox.Items[Aux]) = ItemCombo then
    begin
      AComboBox.ItemIndex := Aux;
      Aux := AComboBox.Items.Count;
    end;
    Aux := Aux + 1;
  end;
end;

class procedure TObjFunctions<T>.SortComponents(var Lista: TList<TComponent>;
  max, min: Integer);
var
  maior, menor: Integer;
  Componente, Curinga: TComponent;
begin
  maior := max;
  menor := min;

  Componente := Lista.Items[((max + min) div 2)];
  // Componente := Lista.Items[min];

  repeat
    while TComponent(Lista.Items[menor]).Tag < Componente.Tag do
      Inc(menor);
    while TComponent(Lista.Items[maior]).Tag < Componente.Tag do
      Inc(maior);

    if (menor <= maior) then
    begin
      Curinga := Lista.Items[menor];
      Lista[menor] := Lista.Items[maior];
      Lista[maior] := Curinga;

      Inc(menor);
      Dec(maior);

    end;

    Dec(maior);
  until (maior > menor);
  if max > menor then
    SortComponents(Lista, menor, max);
  if min < maior then
    SortComponents(Lista, min, maior);

end;

class procedure TObjFunctions<T>.DestroyList(var Lista: TList<T>);
var
  obj: T;
  i: Integer;
begin
  if Assigned(Lista) then
  begin
    try
      for i := 0 to Lista.Count - 1 do
      begin
        try
          obj := Lista[i];
          FreeAndNil(obj);
        except
          on E: Exception do
            Lista[i] := nil;
        end;
      end;

      try
        FreeAndNil(Lista);
      except
        on E: Exception do
          Lista := nil;
      end;
    except
      on E: Exception do
        Lista := nil;
    end;
  end;
end;

class function TObjFunctions<T>.DiferencaListaAListaB(listaA, listaB: TList<T>;
  const Comparer: IComparer<T>): TObjectList<T>;
var
  index: Integer;

  Item: T;
begin
  if not Assigned(Comparer) then
    raise Exception.Create('Comparer Não Implementado!');

  Result := cloneLista(listaA);

  if (not Assigned(listaB)) then
    Exit
  else
  begin
    for Item in listaB do
    begin
      if Result.BinarySearch(Item, index, Comparer) then
        Result.Delete(index);
    end;
  end;

  Result.TrimExcess;

  Result := Result;
end;



class function TObjFunctions<T>.QuickBusca(busca: Variant; Lista: TList<T>;
  FieldName: String): T;
var
  ctx: TRttiContext;
  RTT: TRttiType;
  Obj1: T;
  i: Integer;
  achou_field: Boolean;
begin
  try
    if NOT Assigned(Lista) then
      Exit(NIL);

    if not Lista.Count > 0 then
      Exit(Nil);

    // RTTI - cria o objeto contexto que serve para recuperar toda informação do objeto.
    ctx := TRttiContext.Create;

    Obj1 := Lista[0];
    RTT := ctx.GetType(Obj1.ClassInfo);

    achou_field := false;

    for i := 0 to Length(RTT.GetProperties) - 1 do
    begin
      if UpperCase(RTT.GetProperties[i].Name) = UpperCase(FieldName) then
      begin
        achou_field := true;
        Exit(QuickBuscaPart(busca, Lista, 0, Lista.Count - 1, i, ctx));
      end;
    end;

    if not achou_field then
      raise Exception.Create('Field name não encontrado!');

  except
    on E: Exception do
      raise Exception.Create('Falha ao pesquisar!' + sLineBreak + E.Message);
  end;
end;

class function TObjFunctions<T>.QuickBuscaPart(busca: Variant; Lista: TList<T>;
  i, j: Integer; IndexName: Integer; ctx: TRttiContext): T;
var
  c, p: Integer;
  RTT: TRttiType;
  Obj1: T;
begin
  try
    p := (j - i) div 2;

    if (i + p) > (Lista.Count - 1) then
      Exit(Nil);

    Obj1 := Lista[i + p];

    // RTTI - recupera toda a informação do Objeto atual para o RttiType
    RTT := ctx.GetType(TObject(Obj1).ClassInfo);

    p := (j - i) div 2;

    if j < i then
    begin
      Result := nil;
    end
    else if RTT.GetProperties[IndexName].GetValue(TObject(Obj1)).AsVariant = busca
    then
    begin
      Exit(Lista[i + p]);
    end
    else if RTT.GetProperties[IndexName].GetValue(TObject(Obj1)).AsVariant > busca
    then
    begin
      Result := QuickBuscaPart(busca, Lista, i, i + p - 1, IndexName, ctx);
    end
    else
    begin
      Result := QuickBuscaPart(busca, Lista, i + p + 1, j, IndexName, ctx);
    end;
  except
    on E: Exception do
    begin
      Exit(nil);
    end;
  end;
end;

class procedure TObjFunctions<T>.QuickSort(Lista: TList<T>; FieldName: String;
  Ordem: String);
var
  ctx: TRttiContext;
  RTT: TRttiType;
  Obj1: T;
  i: Integer;
  achou_field: Boolean;
begin
  try
    if Assigned(Lista) then
      if Lista.Count > 0 then
      begin
        // RTTI - cria o objeto contexto que serve para recuperar toda informação do objeto.
        ctx := TRttiContext.Create;

        Obj1 := Lista[0];
        RTT := ctx.GetType(Obj1.ClassInfo);

        achou_field := false;

        for i := 0 to Length(RTT.GetProperties) - 1 do
        begin
          if UpperCase(RTT.GetProperties[i].Name) = UpperCase(FieldName) then
          begin
            achou_field := true;

            if UpperCase(Ordem) = 'CRES' then
            begin
              QuickSortPartCres(Lista, 0, Lista.Count - 1, i, ctx);
            end
            else if UpperCase(Ordem) = 'DECR' then
            begin
              QuickSortPartDecr(Lista, 0, Lista.Count - 1, i, ctx);
            end;

            Break;
          end;
        end;

        if not achou_field then
          raise Exception.Create('Field name não encontrado!');
      end;
  except
    on E: Exception do
      raise Exception.Create('Falha ao ordenar lista!' + sLineBreak +
        E.Message);
  end;
end;

class procedure TObjFunctions<T>.QuickSortPartCres(Lista: TList<T>;
  iLo, iHi: Integer; IndexName: Integer; ctx: TRttiContext);
var
  Lo, Hi: Integer;
  obj, Pivot: T;
begin
  Lo := iLo;
  Hi := iHi;
  Pivot := Lista[(Lo + Hi) div 2];
  repeat
    while ctx.GetType(TObject(Lista[Lo]).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(Lista[Lo])).AsVariant <
      ctx.GetType(TObject(Pivot).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(Pivot)).AsVariant do
      Inc(Lo);
    while ctx.GetType(TObject(Lista[Hi]).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(Lista[Hi])).AsVariant >
      ctx.GetType(TObject(Pivot).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(Pivot)).AsVariant do
      Dec(Hi);
    if Lo <= Hi then
    begin
      obj := Lista[Lo];
      Lista[Lo] := Lista[Hi];
      Lista[Hi] := obj;
      Inc(Lo);
      Dec(Hi);
    end;
  until Lo > Hi;
  if Hi > iLo then
    QuickSortPartCres(Lista, iLo, Hi, IndexName, ctx);
  if Lo < iHi then
    QuickSortPartCres(Lista, Lo, iHi, IndexName, ctx);
end;

class procedure TObjFunctions<T>.QuickSortPartDecr(Lista: TList<T>;
  iLo, iHi, IndexName: Integer; ctx: TRttiContext);
var
  Lo, Hi: Integer;
  obj, Pivot: T;
begin
  Lo := iLo;
  Hi := iHi;
  Pivot := Lista[(Lo + Hi) div 2];

  repeat
    while ctx.GetType(TObject(Lista[Lo]).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(Lista[Lo])).AsVariant >
      ctx.GetType(TObject(Pivot).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(Pivot)).AsVariant do
      Inc(Lo);

    while ctx.GetType(TObject(Lista[Hi]).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(Lista[Hi])).AsVariant <
      ctx.GetType(TObject(Pivot).ClassInfo).GetProperties[IndexName]
      .GetValue(TObject(Pivot)).AsVariant do
      Dec(Hi);

    if Lo <= Hi then
    begin
      obj := Lista[Lo];
      Lista[Lo] := Lista[Hi];
      Lista[Hi] := obj;
      Inc(Lo);
      Dec(Hi);
    end;
  until Lo > Hi;
  if Hi > iLo then
    QuickSortPartDecr(Lista, iLo, Hi, IndexName, ctx);
  if Lo < iHi then
    QuickSortPartDecr(Lista, Lo, iHi, IndexName, ctx);
end;

end.
