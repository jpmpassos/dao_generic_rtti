program Project1;

uses
  Vcl.Forms,
  DaoGenerico in 'DaoGenerico.pas' {Form1},
  UAttributes in 'UAttributes.pas',
  UDao in 'UDao.pas',
  UConexoes in 'UConexoes.pas',
  UBanco in 'UBanco.pas',
  UDBConnection in 'UDBConnection.pas',
  UFieldUtil in 'UFieldUtil.pas',
  UTesteCreat in 'UTesteCreat.pas',
  UObjectClone in 'UObjectClone.pas',
  UContato in 'UContato.pas',
  UConnectionUtil in 'UConnectionUtil.pas',
  UProduto in 'UProduto.pas',
  UCupom in 'UCupom.pas',
  USystemConfig in 'USystemConfig.pas',
  UCliente in 'UCliente.pas',
  UBaseObject in 'UBaseObject.pas',
  Unit1 in 'Unit1.pas',
  Endereco in 'Endereco.pas',
  UJsonUtil in 'UJsonUtil.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
