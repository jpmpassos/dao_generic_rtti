unit USafeUnit;

interface

uses Classes;

type
  IObjectSafe = interface
    function Safe: TComponent;

    function New(out aReference { : Pointer }; const aObject: TObject)
      : IObjectSafe;

    procedure Guard(const aObject: TObject);

    procedure Dispose(var aReference { : Pointer } );
  end;

  IExceptionSafe = interface
    procedure SaveException;
  end;

function ObjectSafe: IObjectSafe; overload;
function ObjectSafe(out aObjectSafe: IObjectSafe): IObjectSafe; overload;
function ExceptionSafe: IExceptionSafe;

function IsAs(out aReference { : Pointer }; const aObject: TObject;
  const aClass: TClass): Boolean;

implementation

uses Windows, SysUtils;

type
  TExceptionSafe = class(TInterfacedObject, IExceptionSafe)
  private
    FMessages: String;
  public
    destructor Destroy; override;

    procedure SaveException;
  end;

  TInterfacedComponent = class(TComponent)
  private
    FRefCount: Integer;
  protected
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    procedure BeforeDestruction; override;
  end;

  TAddObjectMethod = procedure(const aObject: TObject) of object;

  TObjectSafe = class(TInterfacedComponent, IObjectSafe)
  private
    FObjects: array of TObject;
    FEmptySlots: array of Integer;
    AddObject: TAddObjectMethod;

    procedure AddObjectAtEndOfList(const aObject: TObject);
    procedure AddObjectInEmptySlot(const aObject: TObject);

    procedure RemoveObject(const aObject: TObject);
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;

    function Safe: TComponent;
    function New(out aReference; const aObject: TObject): IObjectSafe;
    procedure Guard(const aObject: TObject);
    procedure Dispose(var aReference);
  end;

function TInterfacedComponent._AddRef: Integer;
begin
  Result := InterlockedIncrement(FRefCount);
end;

function TInterfacedComponent._Release: Integer;
begin
  Result := InterlockedDecrement(FRefCount);

  if Result = 0 then
    Destroy;
end;

procedure TInterfacedComponent.BeforeDestruction;
begin
  if FRefCount <> 0 then
    raise Exception.Create(ClassName + ' not freed correctly');
end;

{ TObjectSafe }

constructor TObjectSafe.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  AddObject := AddObjectAtEndOfList;
end;

destructor TObjectSafe.Destroy;
var
  aIndex: Integer;
  aComponent: TComponent;
begin
  with ExceptionSafe do
  begin
    for aIndex := High(FObjects) downto Low(FObjects) do
      try
        FObjects[aIndex].Free;
      except
        SaveException;
      end;

    for aIndex := Pred(ComponentCount) downto 0 do
      try
        aComponent := Components[aIndex];
        try
          RemoveComponent(aComponent);
        finally
          aComponent.Free;
        end;
      except
        SaveException;
      end;

    try
      inherited Destroy;
    except
      SaveException;
    end;
  end;
end;

function TObjectSafe.Safe: TComponent;
begin
  Result := Self;
end;

procedure TObjectSafe.AddObjectAtEndOfList(const aObject: TObject);
begin
  SetLength(FObjects, Succ(Length(FObjects)));
  FObjects[High(FObjects)] := aObject;
end;

procedure TObjectSafe.AddObjectInEmptySlot(const aObject: TObject);
begin
  FObjects[FEmptySlots[High(FEmptySlots)]] := aObject;
  SetLength(FEmptySlots, High(FEmptySlots));

  if Length(FEmptySlots) = 0 then
    AddObject := AddObjectAtEndOfList;
end;

procedure TObjectSafe.RemoveObject(const aObject: TObject);
var
  aIndex: Integer;
begin
  for aIndex := High(FObjects) downto Low(FObjects) do
  begin
    if FObjects[aIndex] = aObject then
    begin
      FObjects[aIndex] := Nil;

      SetLength(FEmptySlots, Succ(Length(FEmptySlots)));
      FEmptySlots[High(FEmptySlots)] := aIndex;
      AddObject := AddObjectInEmptySlot;

      Exit;
    end;
  end;
end;

procedure TObjectSafe.Dispose(var aReference);
begin
  try
    try
      if TObject(aReference) is TComponent then
        RemoveComponent(TComponent(TObject(aReference)))
      else
        RemoveObject(TObject(aReference));
    finally
      TObject(aReference).Free;
    end;
  finally
    TObject(aReference) := Nil;
  end;
end;

procedure TObjectSafe.Guard(const aObject: TObject);
begin
  try
    if aObject is TComponent then
    begin
      if TComponent(aObject).Owner <> Self then
        InsertComponent(TComponent(aObject));
    end
    else
      AddObject(aObject);
  except
    aObject.Free;

    raise;
  end;
end;

function TObjectSafe.New(out aReference; const aObject: TObject): IObjectSafe;
begin
  try
    Guard(aObject);

    TObject(aReference) := aObject;
  except
    TObject(aReference) := Nil;

    raise;
  end;

  Result := Self;
end;

{ TExceptionSafe }

destructor TExceptionSafe.Destroy;
begin
  try
    if Length(FMessages) > 0 then
      raise Exception.Create(FMessages);
  finally
    try
      inherited Destroy;
    except
    end;
  end;
end;

procedure TExceptionSafe.SaveException;
begin
  try
    if (ExceptObject <> Nil) and (ExceptObject is Exception) then
      FMessages := FMessages + Exception(ExceptObject).Message + #13#10;
  except
  end;
end;

function ExceptionSafe: IExceptionSafe;
begin
  Result := TExceptionSafe.Create;
end;

function ObjectSafe: IObjectSafe;
begin
  Result := TObjectSafe.Create(Nil);
end;

function ObjectSafe(out aObjectSafe: IObjectSafe): IObjectSafe; overload;
begin
  Result := ObjectSafe;

  aObjectSafe := Result;
end;

function IsAs(out aReference { : Pointer }; const aObject: TObject;
  const aClass: TClass): Boolean;
begin
  Result := (aObject <> Nil) and (aObject is aClass);

  if Result then
    TObject(aReference) := aObject;
end;

end.
