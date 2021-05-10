unit AldiMainF;

interface

// Kennzeichen: 11 Zeichen / 1 Leerzeichen/ Gebäude: 2 Zeichen/ 1 Leerzeichen / Tor:  1 Zeichen

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, ExtCtrls, OvcState, OvcBase, OvcFiler, OvcStore,
  jpeg, OvcDlg, OvcSplDg, CPort, CommunicationThread, XPMan;

type
  TMain = class(TForm)
    ListView1: TListView;
    btDelete: TButton;
    edTime: TEdit;
    edLKW: TEdit;
    edTor: TEdit;
    edBemerkung: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    btUebernehmen: TButton;
    Timer1: TTimer;
    edDate: TEdit;
    Label5: TLabel;
    OvcIniFileStore1: TOvcIniFileStore;
    OvcFormState1: TOvcFormState;
    OvcComponentState1: TOvcComponentState;
    OvcPersistentState1: TOvcPersistentState;
    btKonfig: TButton;
    OvcSplashDialog1: TOvcSplashDialog;
    ComPort1: TComPort;
    btnDebug: TButton;
    btStatus: TButton;
    XPManifest1: TXPManifest;
    Label6: TLabel;
    edGebaeude: TEdit;
    procedure FormActivate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btUebernehmenClick(Sender: TObject);
    procedure btDeleteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btKonfigClick(Sender: TObject);
    procedure ListView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListView1Deletion(Sender: TObject; Item: TListItem);
    procedure OvcSplashDialog1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnDebugClick(Sender: TObject);
    procedure btStatusClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private-Deklarationen }
    FCurrentTime : TDateTime;
    F200msTicks  : Integer;
    FFirst      : Boolean;
    FCommThread   : TCommunicationThread;
    FStatus       : String;
    FShowStatus : Boolean;
    Fsimulatiom : Boolean;
    procedure CheckList;
    procedure StartThread;
    procedure ThreadDone(Sender: TObject);
    procedure CopySendList(Sender: TObject);
    procedure ReadStatus(Sender: TObject);
    procedure ShowStatus;

  public
    ThreadRunning : Boolean;
    procedure Abort;
  end;

var
  Main: TMain;

implementation

uses AldiKonfig,DebugWindow, ShutDownF, versioninfo;

{$R *.DFM}

procedure TMain.FormActivate(Sender: TObject);
begin
  Caption := ChangeFileExt (ExtractFileName (Application.ExeName), ' ') + ReadVersionInfoApp.FileVersion; 
end;

PROCEDURE TMain.CheckList;
var
  ListIndex : Integer;
  update    : Boolean;
  DiffTime  : Double;
  pTime     : ^TDateTime;
  timeout   : Integer;
begin
  update    := False;
  timeout := AldiKonfigDlg.TimeOut;
  try
    for ListIndex := ListView1.Items.Count - 1 downto 0 do
    begin
      if not ListView1.Items.Item[ListIndex].Checked then
      begin
        pTime := ListView1.Items.Item[ListIndex].Data;
        DiffTime := FCurrentTime - pTime^;
        if (DiffTime  > timeout / (24 * 60)) then
        begin
          if not update then
          begin
            update := true;
            ListView1.Items.BeginUpdate;
          end;
          if AldiKonfigDlg.AutoClear then
          begin
            ListView1.Items.Delete (ListIndex);
          end else begin
            ListView1.Items.Item[ListIndex].Checked := true;
          end;
        end;
      end;
    end;
  finally
    if update then begin
      ListView1.Items.EndUpdate;
    end;
  end;
end;

procedure TMain.CopySendList(Sender: TObject);
var
  listentry  : Integer;
  ToPaint : String;
begin
// Kennzeichen: 11 Zeichen / 1 Leerzeichen/ Gebäude: 2 Zeichen/ 1 Leerzeichen / Tor:  1 Zeichen

  (Sender as TCommunicationThread).FListToSend.Clear;
  for listentry := 0 to ListView1.Items.Count - 1 do
  begin
    with ListView1.Items[listentry] do
    begin
      ToPaint := Format ('%-11s %2.2s %1.1s', [SubItems[1], SubItems[2], SubItems[3]]);
      (Sender as TCommunicationThread).FListToSend.Add (ToPaint);
    end;
  end;
end;

procedure TMain.StartThread;
begin
  if not HandleAllocated then Exit;
  if not Visible then Exit;
  if ThreadRunning then Exit;
  if not ComPort1.Connected then
  begin
    if not FFirst then Exit;
    FFirst := False;
    ComPort1.Connected := True;
    ComPort1.SetDTR (True);
  end;

  FCommThread := TCommunicationThread.Create (ComPort1, AldiKonfigDlg.Anzeigen);
  with FCommThread do
  begin
    Simulation := Fsimulatiom;
    OnCopySendList := CopySendList;
    OnTerminate := ThreadDone;
    OnStatusChanged := ReadStatus;
    Duration := AldiKonfigDlg.GetWechselZeit * 1000;
    SendEmpty := AldiKonfigDlg.cbClearEmpty.Checked;
    if DebugWindowDlg.Visible then begin
      DebugWindowDlg.Clear;
      OnPrintText := DebugWindowDlg.OnPrintText;
      OnPrintLine := DebugWindowDlg.OnPrintLine;
    end;
    Resume;
    ThreadRunning := True;
  end;
end;

procedure TMain.ThreadDone(Sender: TObject);
var
  TheThread : TCommunicationThread;
begin
  TheThread := Sender as TCommunicationThread;
  if FCommThread = TheThread then begin
    ThreadRunning := False;
    FCommThread := nil;
  end;
  if ShutDownDlg.Visible then begin
    ShutDownDlg.Close;
    Exit;
  end;
end;

procedure TMain.ReadStatus(Sender: TObject);
var
  TheThread : TCommunicationThread;
  Tmp : String;
begin
  TheThread := Sender as TCommunicationThread;
  Tmp := TheThread.Status;
  if Tmp <> FStatus then begin
    FStatus := Tmp;
    if Tmp <> '' then FShowStatus := true;
  end;

end;

procedure TMain.ShowStatus;
var
  Msg : String;
begin
  Msg := FStatus;
  if Msg = '' then
  begin
    MessageDlg('Keine Fehler', mtInformation, [mbOK], 0);
  end else begin
    MessageDlg(Msg, mtError, [mbOK], 0);
  end;
  FShowStatus := False;

end;

procedure TMain.Timer1Timer(Sender: TObject);
var
  Msg : boolean;
begin
  FCurrentTime := Now;
  edTime.Text := TimeToStr (FCurrentTime);
  edDate.Text := DateToStr (FCurrentTime);
  Inc (F200msTicks);
  CheckList;
  if FShowStatus then
  begin
    FShowStatus := False;
    ShowStatus;
  end;
end;

procedure TMain.btUebernehmenClick(Sender: TObject);
var
  Lkw      : String;
  Gebaeute : String;
  Tor      : String;
  pTime : ^ TDateTime;
  Save  : TStringList;
begin
  StartThread;
  try
    Lkw := edLKW.Text;
    Tor := edTor.Text;
    Gebaeute := edGebaeude.Text;
    with ListView1.Items.Insert (0) do begin
      Caption := edTime.Text;
      new (pTime);
      pTime^ := FCurrentTime;
      Data := pTime;
      SubItems.Add (edDate.Text);
      SubItems.Add (Lkw);
      SubItems.Add (Gebaeute);
      SubItems.Add (Tor);
      SubItems.Add (edBemerkung.Text);
      Save  := TStringList.Create;
      try
        Save.Add (Caption);
        Save.Add (SubItems[0]);
        Save.Add (SubItems[1]);
        Save.Add (SubItems[2]);
        Save.Add (SubItems[3]);
        Save.Add (SubItems[4]);
        DebugWindowDlg.OnPrintText (Save.CommaText);
      finally
        Save.Free;
      end;
    end;


    if AldiKonfigDlg.cbBemerkung.ItemIndex = 1 then
    begin
      edBemerkung.Text := '';
    end;

    {
    Inc (Tor);
    if Tor > 99 then Lkw := 1;
    case AldiKonfigDlg.cbTor.ItemIndex of
      0 : ; // Wert behalten
      1 : begin edTor.Text := ''; end; // Wert Löschen
      2 : edTor.Text := Format ('%d', [Tor]);
    end;

    Inc (Lkw);
    if Lkw > 999 then Lkw := 1;
    case AldiKonfigDlg.cbLKW.ItemIndex of
      0 : ; // Wert behalten
      1 : begin edLKW.Text := ''; end;// Wert Löschen
      2 : edLKW.Text := Format ('%d', [Lkw]);
    end;
    }
  except
  end;
  if edLKW.Text = '' then edLKW.SetFocus
  else if edTor.Text = '' then edTor.SetFocus
  // else if edBemerkung.Text = '' then edBemerkung.SetFocus
  else edTor.SetFocus;

end;

procedure TMain.btDeleteClick(Sender: TObject);
var
  ListIndex : Integer;
  DelCount  : integer;
begin
  if ListView1.Items.Count = 0 then exit;
  DelCount := 0;
  ListView1.Items.BeginUpdate;
  try
    for ListIndex := ListView1.Items.Count - 1 downto 0 do
    begin
      if ListView1.Items.Item[ListIndex].Checked then
      begin
        ListView1.Items.Delete (ListIndex);
        inc (DelCount);
      end;
    end;
  finally
    ListView1.Items.EndUpdate;
  end;
  if DelCount = 0 then
  begin
    MessageDlg('Bitte Einträge zum löschen anwählen', mtInformation, [mbOK], 0);
  end;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  idx : integer;
begin
  ListView1.Columns[0].Width := edDate.Left - ListView1.Left;
  ListView1.Columns[1].Width := edLKW.Left  - ListView1.Left - ListView1.Columns[0].Width;
  ListView1.Columns[2].Width := edTor.Left  - ListView1.Left - ListView1.Columns[1].Width - ListView1.Columns[0].Width;
  ListView1.Columns[3].Width := edBemerkung.Left - ListView1.Left - ListView1.Columns[2].Width - ListView1.Columns[1].Width - ListView1.Columns[0].Width;
  FFirst := true;
  try
    OvcIniFileStore1.Open;
    btnDebug.Visible := OvcIniFileStore1.ReadInteger ('Debug', 'Trace', 0) = 1;
    Fsimulatiom := OvcIniFileStore1.ReadBoolean ('Debug', 'Simulation', false);
    OvcIniFileStore1.Close;
  except
  end;
  //caption := '

end;

procedure TMain.btKonfigClick(Sender: TObject);
var
  idx : integer;
begin
  Timer1.Enabled := False;
  ShutDownDlg.shutDown;
  // while ThreadRunning do Application.ProcessMessages;
  ComPort1.Connected := False;
  AldiKonfigDlg.Execute;
  FStatus := '';
  FFirst := True;
  Timer1.Enabled := True;
  StartThread;
end;

procedure TMain.ListView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  ListIndex : Integer;
begin
  if Key = VK_DELETE  then
  begin
    ListView1.Items.BeginUpdate;
    try
      for ListIndex := ListView1.Items.Count - 1 downto 0 do
      begin
        if ListView1.Items.Item[ListIndex].Selected then
        begin
          ListView1.Items.Delete (ListIndex);
        end;
      end;
    finally
      ListView1.Items.EndUpdate;
    end;
  end;
end;

procedure TMain.ListView1Deletion(Sender: TObject; Item: TListItem);
var
  pTime : ^ TDateTime;
begin
  pTime := Item.Data;
  Dispose (pTime);
end;

procedure TMain.OvcSplashDialog1Click(Sender: TObject);
begin
  OvcSplashDialog1.Close;
end;

procedure TMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  Timer1.Enabled := False;
  ShutDownDlg.shutDown;
  //while ThreadRunning do Application.ProcessMessages;
end;

procedure TMain.btnDebugClick(Sender: TObject);
begin
  DebugWindowDlg.Visible := not DebugWindowDlg.Visible;
  if DebugWindowDlg.Visible and assigned (FCommThread)then
  begin
    FCommThread.OnPrintText := DebugWindowDlg.OnPrintText;
    FCommThread.OnPrintLine := DebugWindowDlg.OnPrintLine;
  end;

end;

procedure TMain.Abort;
begin
  if ThreadRunning and Assigned (FCommThread) then begin
    FCommThread.Abort;
  end;
end;


procedure TMain.btStatusClick(Sender: TObject);
begin
  ShowStatus;
end;

procedure TMain.FormShow(Sender: TObject);
begin
  StartThread;

end;

end.
