unit USystemConfig;

interface

type
  TTipoSGBD = (tpFirebird, tpPostgreSQL);

type
  TSystemConfig = class
  private
    FtipoSGBD: TTipoSGBD;
    Fusername: String;
    Fpassword: String;
    Fserver: String;
    Fdatabase: String;
    Fport: String;

    class var finstancia: TSystemConfig;


    procedure carregarConfiguracao;
    constructor CreatePrivate;

  public
    property tipoSGBD: TTipoSGBD read FtipoSGBD write FtipoSGBD;
    property username: String read Fusername write Fusername;
    property password: String read Fpassword write Fpassword;
    property server: String read Fserver write Fserver;
    property database: String read Fdatabase write Fdatabase;
    property port: String read Fport write Fport;

    class function GetInstancia(): TSystemConfig;
    constructor Create;
  end;

implementation

uses
  System.Classes, System.SysUtils, Vcl.Forms, System.JSON, REST.JSON;

{ TSystemConfig }

procedure TSystemConfig.carregarConfiguracao;
var
  arquivo: TStringList;
  instancia: TSystemConfig;
begin
  arquivo := TStringList.Create;
  arquivo.LoadFromFile(ExtractFileDir(Application.ExeName) +
    '\SystemConfig.conf');
  instancia := TJson.JsonToObject<TSystemConfig>(arquivo[0]);

  Self.password := instancia.password;
  Self.username := instancia.username;
  Self.server := instancia.server;
  Self.database := instancia.database;
  Self.tipoSGBD := instancia.tipoSGBD;
end;

constructor TSystemConfig.Create;
begin

end;

constructor TSystemConfig.CreatePrivate;
begin
  carregarConfiguracao;
end;

class function TSystemConfig.GetInstancia: TSystemConfig;
begin
  if not Assigned(finstancia) then
    finstancia := TSystemConfig.CreatePrivate;

  Result := finstancia;
end;

end.
