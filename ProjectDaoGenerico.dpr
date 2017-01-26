program Project1;

uses
  Vcl.Forms,
  DaoGenerico in 'DaoGenerico.pas' {Form1},
  UConexoes in 'UConexoes.pas',
  UTesteCreat in 'UTesteCreat.pas',
  UObjectClone in 'UObjectClone.pas',
  UContato in 'UContato.pas',
  UProduto in 'UProduto.pas',
  UCupom in 'UCupom.pas',
  UCliente in 'UCliente.pas',
  UBaseObject in 'UBaseObject.pas',
  Unit1 in 'Unit1.pas',
  Endereco in 'Endereco.pas',
  UAttributes in 'DaoGenerico\UAttributes.pas',
  UConnectionUtil in 'DaoGenerico\UConnectionUtil.pas',
  UDao in 'DaoGenerico\UDao.pas',
  UDBConnection in 'DaoGenerico\UDBConnection.pas',
  UFieldUtil in 'DaoGenerico\UFieldUtil.pas',
  UJsonUtil in 'DaoGenerico\UJsonUtil.pas',
  USystemConfig in 'DaoGenerico\USystemConfig.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
