unit UConexoes;

interface

uses FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Comp.Client, FireDAC.VCLUI.Wait,
  FireDAC.Comp.UI, FireDAC.Phys.IBBase, FireDAC.Phys.FB, System.SysUtils,
  Vcl.Forms, UBanco;

type
  TConexoes = class
  private

  public
    class function AbreNovaConexao(COD_CONEXAO: Integer = 1): TFDConnection;
    class function AbreConexao(var FDConexao: TFDConnection;
      COD_CONEXAO: Integer = 1): Boolean;
    class function FechaConexao(var FDConexao: TFDConnection): Boolean;
      overload;
    class function FechaConexao(var FDQuery: TFDQuery): Boolean; overload;
    class function IniciarTransacao(var FDConexao: TFDConnection)
      : Boolean; overload;
    class function IniciarTransacao(var FDQuery: TFDQuery): Boolean; overload;
    class function FecharTransacao(var FDConexao: TFDConnection;
      Commit: Boolean = True): Boolean; overload;
    class function FecharTransacao(var FDQuery: TFDQuery;
      Commit: Boolean = True): Boolean; overload;
    class function TestaConexao(HOST, DB, USUARIO, SENHA: String): Boolean;
  end;

implementation

{ TConexoes }

class function TConexoes.AbreConexao(var FDConexao: TFDConnection;
  COD_CONEXAO: Integer): Boolean;
Var
  Banco: TBanco;
begin
  if not Assigned(FDConexao) then
    FDConexao := TFDConnection.Create(Nil);

  if not Assigned(Banco) then
  begin
    Banco := TBanco.Create;

    Banco.USUARIO := 'SYSDBA';
    Banco.SENHA := 'masterkey';
    Banco.HOST := ParamStr(1);

    if Trim(Banco.HOST) = EmptyStr then
      Banco.HOST := 'LOCALHOST';

    Banco.Banco := ExtractFileDir(Application.ExeName) + '\DB\DB_PAF_ECF.FDB';
  end;

  try
    with FDConexao do
    begin
      DriverName := 'FB';
      LoginPrompt := False;
      Params.Add('User_Name=' + Banco.USUARIO);
      Params.Add('Password=' + Banco.SENHA);

      Params.Add('Protocol=TCPIP');

      Params.Add('Server=' + Banco.HOST);
      Params.Add('Database=' + Banco.Banco);

      Params.Add('CharacterSet=ISO8859_1');

      Open;
    end;

    Result := True;
  except
    on E: Exception do
    begin
      raise Exception.Create('Falha ao Abrir Conexao!' + #13 + E.Message);

      Result := False;
    end;
  end;

end;

class function TConexoes.AbreNovaConexao(COD_CONEXAO: Integer): TFDConnection;
Var
  Banco: TBanco;
  NewFDConexao: TFDConnection;
begin
  try
    NewFDConexao := TFDConnection.Create(Nil);

    try
      with NewFDConexao do
      begin
        DriverName := 'FB';
        LoginPrompt := False;
        Params.Add('User_Name=' + Banco.USUARIO);
        Params.Add('Password=' + Banco.SENHA);

        Params.Add('Protocol=TCPIP');

        Params.Add('Server=' + Banco.HOST);
        Params.Add('Database=' + Banco.Banco);

        Params.Add('CharacterSet=ISO8859_1');

        Open;
      end;

      Result := NewFDConexao;
    except
      on E: Exception do
      begin
        if COD_CONEXAO = 2 then
          raise Exception.Create
            ('Favor Verificar as Configurações do Servidor PV/DAV!')
        else if COD_CONEXAO = 3 then
          raise Exception.Create
            ('Favor Verificar as Configurações do Arquivo CONFIG_SERVIDOR.INI!')
        else
          raise Exception.Create('Falha ao Abrir Conexao!' + #13 + E.Message);

        Result := Nil;
      end;
    end;
  finally
  end;
end;

class function TConexoes.FechaConexao(var FDConexao: TFDConnection): Boolean;
begin
  try
    if Assigned(FDConexao) then
    begin
      if FDConexao.InTransaction then
        FecharTransacao(FDConexao, True);

      FDConexao.Close;

      FreeAndNil(FDConexao);
    end;

    Result := True;
  except
    on E: Exception do
    begin
      raise Exception.Create('Falha ao Fechar Conexao' + #13 + E.Message);

      Result := False;
    end;
  end;
end;

class function TConexoes.FechaConexao(var FDQuery: TFDQuery): Boolean;
begin
  try
    if Assigned(FDQuery.Connection) then
    begin
      if FDQuery.Connection.InTransaction then
        FecharTransacao(FDQuery, True);

      FDQuery.Connection.Close;

      FDQuery.Connection.Free;
    end;

    Result := True;
  except
    on E: Exception do
    begin
      raise Exception.Create('Falha ao Fechar Conexao' + #13 + E.Message);

      Result := False;
    end;
  end;

end;

class function TConexoes.FecharTransacao(var FDQuery: TFDQuery;
  Commit: Boolean): Boolean;
begin
  try
    if Assigned(FDQuery.Connection) then
    begin
      if FDQuery.Connection.InTransaction then
      begin
        if Commit then
          FDQuery.Connection.Commit
        else
          FDQuery.Connection.Rollback;
      end;
    end;

    Result := False;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

class function TConexoes.IniciarTransacao(var FDQuery: TFDQuery): Boolean;
begin
  try
    if Assigned(FDQuery.Connection) then
    begin
      if FDQuery.Connection.InTransaction then
        FecharTransacao(FDQuery, True);

      FDQuery.Connection.StartTransaction;
    end;

    Result := True;
  except
    on E: Exception do
    begin
      raise Exception.Create('Falha ao Iniciar Transação' + #13 + E.Message);

      Result := False;
    end;
  end;

end;

class function TConexoes.TestaConexao(HOST, DB, USUARIO, SENHA: String)
  : Boolean;
Var
  NewFDConexao: TFDConnection;
begin
  try
    NewFDConexao := Nil;
    NewFDConexao := TFDConnection.Create(Nil);

    try
      with NewFDConexao do
      begin
        DriverName := 'FB';
        LoginPrompt := False;
        Params.Add('User_Name=' + USUARIO);
        Params.Add('Password=' + SENHA);

        Params.Add('Protocol=TCPIP');

        Params.Add('Server=' + HOST);
        Params.Add('Database=' + DB);

        Params.Add('CharacterSet=ISO8859_1');

        Open;
      end;

      Result := True;
    except
      on E: Exception do
        Result := False;
    end;
  finally
    try
      if Assigned(NewFDConexao) then
      begin
        NewFDConexao.Close;

        FreeAndNil(NewFDConexao);
      end;
    except
      on E: Exception do
    end;
  end;
end;

class function TConexoes.FecharTransacao(var FDConexao: TFDConnection;
  Commit: Boolean): Boolean;
begin
  try
    if Assigned(FDConexao) then
    begin
      if FDConexao.InTransaction then
      begin
        if Commit then
          FDConexao.Commit
        else
          FDConexao.Rollback;
      end;
    end;

    Result := False;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

class function TConexoes.IniciarTransacao(var FDConexao: TFDConnection)
  : Boolean;
begin
  try
    if Assigned(FDConexao) then
    begin
      if FDConexao.InTransaction then
        FecharTransacao(FDConexao, True);

      FDConexao.StartTransaction;
    end;

    Result := True;
  except
    on E: Exception do
    begin
      raise Exception.Create('Falha ao Iniciar Transação' + #13 + E.Message);

      Result := False;
    end;
  end;
end;

end.
