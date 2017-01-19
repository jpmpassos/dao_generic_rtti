unit UBanco;

interface

type
  TBanco = class
    private
      Fusuario,
      Fsenha  ,
      Fhost   ,
      Fbanco  : String;
    public
      property usuario: string read Fusuario write Fusuario;
      property senha  : string read Fsenha   write Fsenha;
      property host   : string read Fhost    write Fhost;
      property banco  : string read Fbanco   write Fbanco;
  end;

implementation

end.
