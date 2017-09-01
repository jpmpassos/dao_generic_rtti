unit UControleSession;

interface

uses
  System.Generics.Collections, System.Classes, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Comp.Client, FireDAC.VCLUI.Wait, FireDAC.Comp.UI, FireDAC.Phys.IBBase,
  FireDAC.Phys.FB, FireDAC.Phys.PG, USession;

type
  TControleSession = Class(TThreadList<TSession>)
  private
    FMaxId: Integer;
    class var FInstance: TControleSession;

    function getConnectionPorId(id: Integer): TSession;
    function createConnection: TSession;
    constructor CreatePrivate;
  public
    property MaxId: Integer read FMaxId write FMaxId;
    class function Acquire(id: Integer = 0): TSession;
    class procedure Release(AConnection: TSession);
    class function CommitSesion(AConnection: TSession): Boolean;
    class function RollbackSesion(AConnection: TSession): Boolean;
    constructor create;
  End;

implementation

uses
  USystemConfig, System.SysUtils;

{ TControleSession }

class function TControleSession.Acquire(id: Integer): TSession;
begin
  if FInstance = nil then
    FInstance := TControleSession.create;

  if id > 0 then
  begin
    Result := FInstance.getConnectionPorId(id);
    if Result <> nil then
      Exit;
  end;

  Exit(FInstance.createConnection);
end;

class function TControleSession.CommitSesion(AConnection: TSession): Boolean;
begin
  try
    try
      AConnection.Commit;
      Result := true;
    except
      on E: Exception do
        try
          try
            AConnection.Rollback;
          except
            on E: Exception do
          end;
        finally
          Result := False;
        end;
    end;
  finally
    try
      FInstance.Remove(AConnection);
      AConnection.FreeOnRelease;
    except
      on E: Exception do
    end;
  end;
end;

constructor TControleSession.create;
begin
  inherited;
  FMaxId := 0;
end;

function TControleSession.createConnection: TSession;
begin
  Result := TSession.create(nil);

  if TSystemConfig.GetInstancia.tipoSGBD = tpPostgreSQL then
  begin
    Result.DPhysPgDriverLink := TFDPhysPgDriverLink.create(nil);
    Result.DPhysPgDriverLink.VendorHome :=
      TSystemConfig.GetInstancia.caminhoaplicacao + '\pgbin32\';
    Result.DPhysPgDriverLink.VendorLib := 'libpq.dll';
    Result.DPhysPgDriverLink.Release;
    Result.DriverName := 'PG';
  end
  else
    Result.DriverName := 'FB';

  Result.LoginPrompt := False;
  Result.Params.Values['User_Name'] := TSystemConfig.GetInstancia.username;
  // 'SYSDBA';
  Result.Params.Values['Password'] := TSystemConfig.GetInstancia.password;
  // 'masterkey';
  Result.Params.Values['Protocol'] := 'TCPIP';
  Result.Params.Values['Server'] := TSystemConfig.GetInstancia.server;
  // 'localhost';
  Result.Params.Values['Database'] := TSystemConfig.GetInstancia.database;

  Result.Params.Values['CharacterSet'] := TSystemConfig.GetInstancia.charset;
  // 'ISO8859_1';

  Result.Open;

  Result.query := TFDQuery.create(nil);
  Result.query.Connection := Result;
  Result.query.FetchOptions.Mode := fmAll;
  Result.query.FetchOptions.Unidirectional := False;
  // Fquery.FetchOptions.RecordCountMode := cmTotal;

  Result.id := FInstance.MaxId + 1;
  FInstance.FMaxId := Result.id;

  FInstance.Add(Result);
end;

constructor TControleSession.CreatePrivate;
begin
  FInstance := TControleSession.create;
end;

function TControleSession.getConnectionPorId(id: Integer): TSession;
var
  conn: TSession;
  myList: TList<TSession>;
begin
  myList := Self.LockList;
  for conn in myList do
    if conn.id = id then
      Exit(conn);

  Result := nil;
end;

class procedure TControleSession.Release(AConnection: TSession);
begin
  FInstance.Remove(AConnection);
  AConnection.FreeOnRelease;
end;

class function TControleSession.RollbackSesion(AConnection: TSession): Boolean;
begin
  begin
    try
      try
        AConnection.Rollback;
        Result := true;
      except
        on E: Exception do
          try
            try
              AConnection.Rollback;
            except
              on E: Exception do
            end;
          finally
            Result := False;
          end;
      end;
    finally
      try
        FInstance.Remove(AConnection);
        AConnection.FreeOnRelease;
      except
        on E: Exception do
      end;
    end;
  end;
end;

end.
