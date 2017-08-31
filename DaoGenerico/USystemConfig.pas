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
    Fcharset: string;
    Fcaminhoaplicacao: string;

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
    property charset: string read Fcharset write Fcharset;
    property caminhoaplicacao: string read Fcaminhoaplicacao
      write Fcaminhoaplicacao;

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
  Self.caminhoaplicacao := ExtractFileDir(Application.ExeName);

  arquivo := TStringList.Create;

  arquivo.LoadFromFile(Self.caminhoaplicacao + '\SystemConfig.conf');
  instancia := TJson.JsonToObject<TSystemConfig>(arquivo[0]);

  Self.password := instancia.password;
  Self.username := instancia.username;
  Self.server := instancia.server;
  Self.tipoSGBD := instancia.tipoSGBD;

  if instancia.tipoSGBD = tpFirebird then
    Self.database := Self.caminhoaplicacao + StringReplace(instancia.database,
      '/', '\', [rfReplaceAll])
  else
    Self.database := instancia.database;


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
