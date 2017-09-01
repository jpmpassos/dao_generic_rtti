unit USession;

interface

uses
  FireDAC.Comp.Client, FireDAC.Phys.PG;

type
  TSession = class(TFDConnection)
  private
    Fid: Integer;
    Fquery: TFDQuery;
    FDPhysPgDriverLink: TFDPhysPgDriverLink;
    Fautocommit: Boolean;
  public
    property id: Integer read Fid write Fid;
    property autocommit: Boolean read Fautocommit write Fautocommit;
    property DPhysPgDriverLink: TFDPhysPgDriverLink read FDPhysPgDriverLink
      write FDPhysPgDriverLink;
    property query: TFDQuery read Fquery write Fquery;
  end;

implementation

end.
