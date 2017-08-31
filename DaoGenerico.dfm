object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 288
  ClientWidth = 467
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 80
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Teste Clone'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 208
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Teste Query'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 341
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Teste Insert'
    TabOrder = 2
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 64
    Top = 168
    Width = 105
    Height = 25
    Caption = 'Teste Query PG'
    TabOrder = 3
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 200
    Top = 168
    Width = 97
    Height = 25
    Caption = 'Teste Update'
    TabOrder = 4
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 335
    Top = 168
    Width = 97
    Height = 25
    Caption = 'Teste inserir postegre'
    TabOrder = 5
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 256
    Top = 216
    Width = 75
    Height = 25
    Caption = 'Teste Delete'
    TabOrder = 6
    OnClick = Button7Click
  end
  object Button8: TButton
    Left = 64
    Top = 96
    Width = 75
    Height = 25
    Caption = 'Teste Get'
    TabOrder = 7
    OnClick = Button8Click
  end
end
