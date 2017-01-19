unit UTesteCreat;

interface

Uses rtti;

type
  GpManagedAttribute = class(TCustomAttribute)
  public type
    TConstructorType = (ctNoParam, ctParBoolean);
  strict private
    FBoolParam: boolean;
    FConstructorType: TConstructorType;
  public
    class function IsManaged(const obj: TRttiNamedObject): boolean; static;
    class function GetAttr(const obj: TRttiNamedObject;
      var ma: GpManagedAttribute): boolean; static;
    constructor Create; overload;
    constructor Create(boolParam: boolean); overload;
    property boolParam: boolean read FBoolParam;
    property ConstructorType: TConstructorType read FConstructorType;
  end;

  TGpManaged = class
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TObjectB = class
    FData1: integer;
    FData2: string;
    FData3: boolean;
  end;

  TObjectA = class(TGpManaged)
  strict private[GpManaged]
    FObjectB: TObjectB;
  end;

implementation

uses
  System.SysUtils;

{ GpManagedAttribute }

constructor GpManagedAttribute.Create;
begin

end;

constructor GpManagedAttribute.Create(boolParam: boolean);
begin

end;

class function GpManagedAttribute.GetAttr(const obj: TRttiNamedObject;
  var ma: GpManagedAttribute): boolean;
begin

end;

class function GpManagedAttribute.IsManaged
  (const obj: TRttiNamedObject): boolean;
begin

end;

{ TGpManaged }

constructor TGpManaged.Create;
var
  ctor: TRttiMethod;
  ctx: TRttiContext;
  f: TRttiField;
  ma: GpManagedAttribute;
  params: TArray<TRttiParameter>;
  t: TRttiType;
begin
  ctx := TRttiContext.Create;
  t := ctx.GetType(Self.ClassType);
  for f in t.GetFields do
  begin
    if not GpManagedAttribute.GetAttr(f, ma) then
      continue; // for f
    for ctor in f.FieldType.GetMethods('Create') do
    begin
      if ctor.IsConstructor then
      begin
        params := ctor.GetParameters;
        if (ma.ConstructorType = GpManagedAttribute.TConstructorType.ctNoParam)
          and (Length(params) = 0) then
        begin
          f.SetValue(Self,
            ctor.Invoke(f.FieldType.AsInstance.MetaclassType, []));
          break; // for ctor
        end
        else if (ma.ConstructorType = GpManagedAttribute.TConstructorType.
          ctParBoolean) and (Length(params) = 1) and
          (params[0].ParamType.TypeKind = tkEnumeration) and
          SameText(params[0].ParamType.name, 'Boolean') then
        begin
          f.SetValue(Self, ctor.Invoke(f.FieldType.AsInstance.MetaclassType,
            [ma.boolParam]));
          break; // for ctor
        end;
      end;
    end; // for ctor
  end; // for f
end;

destructor TGpManaged.Destroy;
var
  ctx: TRttiContext;
  dtor: TRttiMethod;
  f: TRttiField;
  t: TRttiType;
begin
  ctx := TRttiContext.Create;
  t := ctx.GetType(Self.ClassType);
  for f in t.GetFields do
  begin
    if not GpManagedAttribute.IsManaged(f) then
      continue; // for f
    for dtor in f.FieldType.GetMethods('Destroy') do
    begin
      if dtor.IsDestructor then
      begin
        dtor.Invoke(f.GetValue(Self), []);
        f.SetValue(Self, nil);
        break; // for dtor
      end;
    end; // for dtor
  end; // for f
end;

end.
