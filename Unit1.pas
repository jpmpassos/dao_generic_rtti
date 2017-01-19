unit Unit1;

interface

uses SysUtils, Rtti;

type
  WInstancia_Not_Null = class(Exception);

type
  TRetorna_TObject = class
    class function Instanciar(const Str_Class: TValue): TObject;
  end;

implementation

uses TypInfo;

class function TRetorna_TObject.Instanciar(const Str_Class: TValue): TObject;
var
  C: TRttiContext;
  instancia: TRttiInstanceType;
  p: TRttiType;
  Erro: string;
begin
  try
    case Str_Class.Kind of
      tkString, tkLString, tkWString, tkUString:
        begin
          Erro := Str_Class.AsString + ' Classe Não encontrada' + sLineBreak +
            '<Lembrete : verifique ortografia&nbsp; / Case Sensitive>' +
            sLineBreak;
          instancia := (C.FindType(Str_Class.AsString) as TRttiInstanceType);
          result := (instancia.MetaclassType.Create);
        end;
      tkClassRef:
        begin
          Erro := 'O parâmetro passado deve ser do tipo Tclass' + sLineBreak;
          p := C.GetType(Str_Class.AsClass);
          instancia := (C.FindType(p.QualifiedName) as TRttiInstanceType);
          result := instancia.MetaclassType.Create;
        end;
    else
      begin
        Erro := 'O parâmetro passado não é válidado para a função' + sLineBreak;
        abort;
      end;
    end;
  except
    on e: Exception do
    begin
      raise WInstancia_Not_Null.Create(Erro + 'Mensagem Original' + sLineBreak +
        e.message);
    end;
  end;
end;

end.
