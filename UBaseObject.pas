unit UBaseObject;

interface

uses DBXJSON, DBXJSONReflect, System.JSON;

type
  TBaseObject = class
  public
    { public declarations }
    class function ObjectToJSON<T: class>(myObject: T): TJSONValue;
    class function JSONToObject<T: class>(json: TJSONValue): T;
  end;

implementation

{ TBaseObject }

class function TBaseObject.JSONToObject<T>(json: TJSONValue): T;
var
  unm: TJSONUnMarshal;
begin
  if json is TJSONNull then
    exit(nil);
  unm := TJSONUnMarshal.Create;
  try
    exit(T(unm.Unmarshal(json)))
  finally
    unm.Free;
  end;

end;

class function TBaseObject.ObjectToJSON<T>(myObject: T): TJSONValue;
var
  m: TJSONMarshal;
begin
  if Assigned(myObject) then
  begin
    m := TJSONMarshal.Create(TJSONConverter.Create);
    try
      exit(m.Marshal(myObject));
    finally
      m.Free;
    end;
  end
  else
    exit(TJSONNull.Create);

end;

end.
