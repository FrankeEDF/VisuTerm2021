unit DebugWindow;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls;

type
  TDebugWindowDlg = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    cbActive: TCheckBox;
    ListBox1: TListBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private-Deklarationen }
    AnzIndex : array of integer;
  public
    { Public-Deklarationen }
    procedure OnPrintText (const aText: String);
    procedure Clear;
    procedure OnPrintLine(const Index : integer; const ToPrint : string);
  end;

var
  DebugWindowDlg: TDebugWindowDlg;

implementation

{$R *.DFM}

procedure TDebugWindowDlg.OnPrintText (const aText: String);
begin
  if cbActive.Checked then
  Memo1.Lines.Add (aText);
end;

procedure TDebugWindowDlg.Clear;
begin
  Memo1.Lines.Clear;
end;

procedure TDebugWindowDlg.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Memo1.Lines.Clear;
end;

procedure TDebugWindowDlg.OnPrintLine(const Index: integer;
  const ToPrint: string);
var
  idx : integer;
begin
  for idx := 0 to Length (AnzIndex) -  1 do
  begin
    if AnzIndex[idx] = Index then
    begin
      ListBox1.Items [idx] := Format ('[0x%.4x] <%s>', [index, ToPrint]);
      exit;
      // draw, exit;
    end;
  end;
  idx := Length (AnzIndex);
  SetLength (AnzIndex, idx + 1);
  AnzIndex[idx] := Index;

  ListBox1.Items.Add (ToPrint);
end;

end.
