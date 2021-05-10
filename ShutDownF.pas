unit ShutDownF;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls;

type
  TShutDownDlg = class(TForm)
    Label1: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure shutDown;
  end;

var
  ShutDownDlg: TShutDownDlg;

implementation

uses AldiMainF;

procedure TShutDownDlg.shutDown;
begin
  if Main.ThreadRunning then
  begin
    Main.Abort;
    ShowModal;
  end;
end;

{$R *.DFM}

end.
