unit AldiKonfig;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls, OvcBase, OvcState, OvcFiler, OvcStore, CPortCtl;

type
  TAldiKonfigDlg = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    Bevel1: TBevel;
    edWechselzeit: TEdit;
    Label1: TLabel;
    edTimeOut: TEdit;
    Label2: TLabel;
    OvcComponentState1: TOvcComponentState;
    Label5: TLabel;
    Label6: TLabel;
    OvcIniFileStore1: TOvcIniFileStore;
    ComComboBox1: TComComboBox;
    Label3: TLabel;
    cbAutoClear: TCheckBox;
    Label4: TLabel;
    cbLKW: TComboBox;
    cbTor: TComboBox;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    cbBemerkung: TComboBox;
    Label10: TLabel;
    cbAnzeigen: TComboBox;
    Label11: TLabel;
    cbClearEmpty: TCheckBox;
    function GetWechselZeit : Integer;
    function GetTimeOut : Integer;
    function GetAutoClear : Boolean;
    function GetAnzeigen : integer;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure OvcComponentState1RestoreState(Sender: TObject);
    procedure OvcComponentState1SaveState(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    property  WechselZeit : integer read GetWechselZeit;
    property  TimeOut     : integer read GetTimeOut;
    property  AutoClear   : Boolean read GetAutoClear;
    property  Anzeigen    : integer read GetAnzeigen;
    procedure Execute;
  end;

var
  AldiKonfigDlg: TAldiKonfigDlg;

implementation

uses AldiMainF;

{$R *.DFM}
procedure TAldiKonfigDlg.Execute;
var
  TmpFWechselZeit : String;
  TmpFTimeOut     : String;
  TmpFAutoClear   : Boolean;

begin
  ComComboBox1.ComPort := Main.ComPort1;
  ComComboBox1.UpdateSettings;
  // OvcComponentState1SaveState (NIL);
  TmpFWechselZeit := edWechselzeit.Text;
  TmpFTimeOut     := edTimeOut.Text;
  TmpFAutoClear   := cbAutoClear.Checked;
  if ShowModal = mrOk then
  begin
    ComComboBox1.ApplySettings;
  end else begin
    edWechselzeit.Text  := TmpFWechselZeit;
    edTimeOut.Text      := TmpFTimeOut;
    cbAutoClear.Checked := TmpFAutoClear;
  end;
end;

function TAldiKonfigDlg.GetWechselZeit : Integer;
begin
  result := StrToIntDef (edWechselzeit.Text, 0)
end;

function TAldiKonfigDlg.GetTimeOut : Integer;
begin
  result := StrToIntDef (edTimeOut.Text, 0);
end;

function TAldiKonfigDlg.GetAutoClear : Boolean;
begin
  result := cbAutoClear.Checked
end;


procedure TAldiKonfigDlg.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := (GetWechselZeit <> 0) and (GetTimeOut <> 0);
end;

procedure TAldiKonfigDlg.OvcComponentState1RestoreState(Sender: TObject);
begin
  OvcIniFileStore1.Open;
  cbLKW.ItemIndex        := OvcIniFileStore1.ReadInteger ('Input', 'Lkw', 0);
  cbTor.ItemIndex        := OvcIniFileStore1.ReadInteger ('Input', 'Tor', 0);;
  cbBemerkung .ItemIndex := OvcIniFileStore1.ReadInteger ('Input', 'Bemerkung', 0);;
  cbAnzeigen.ItemIndex   := OvcIniFileStore1.ReadInteger ('Input', 'Anzeigen', 1);
  OvcIniFileStore1.Close;
end;

procedure TAldiKonfigDlg.OvcComponentState1SaveState(Sender: TObject);
begin
  OvcIniFileStore1.Open;
  OvcIniFileStore1.WriteInteger ('Input', 'Lkw',       cbLKW.ItemIndex);
  OvcIniFileStore1.WriteInteger ('Input', 'Tor',       cbTor.ItemIndex);
  OvcIniFileStore1.WriteInteger ('Input', 'Bemerkung', cbBemerkung .ItemIndex);
  OvcIniFileStore1.WriteInteger ('Input', 'Anzeigen',  cbAnzeigen.ItemIndex);

  OvcIniFileStore1.Close;
end;

function TAldiKonfigDlg.GetAnzeigen: integer;
begin
  result := cbAnzeigen.ItemIndex + 1;
end;

end.
