unit CommunicationThread;

interface

uses
  types, Classes, Cport;
{ $DEFINE DEBUG}

type
  TOnPrintText    = procedure (const ToPrint : string) of Object;
  TOnPrintLine    = procedure (const Index : integer; const ToPrint : string) of Object;

  type
    TAnzeigeCfg = packed record
      case Boolean of
        False : (all : dWord);
        True  : (Adresse  : Byte; Fault  : Byte);
    end;

  TCommunicationThread = class(TThread)
  private
    procedure Master;
    procedure SendMasterTele;
    procedure Aribtrier;
    function MasterTeleReceived: Boolean;
    function AnythingReceiveded: Boolean;
    procedure SendSlaveTele;
    procedure MasterDelay(TotDelay: dword);
    procedure DoPrintLine;
    procedure PrintLine(index: integer; txt: String);
    function  ProcessRx : Boolean;
    { Private-Deklarationen }
  protected
    FAnzeigeList : TStringList;
    (*
    FAnzeige1   : Byte;
    FAnzeige2   : Byte;
    FAnzeige1Ok   : Boolean;
    FAnzeige2Ok   : Boolean;
    *)
    FOnPrintLine     : TOnPrintLine;
    FOnPrintText     : TOnPrintText;
    FOnCopySendList  : TNotifyEvent;
    FOnSended        : TNotifyEvent;
    FOnStatusChanged : TNotifyEvent;
    FThePrintText : String;
    FXLines : Integer;
    FAbort  : Boolean;
    FDuration : DWORD;
    FRxState : integer;
    FStatus : String;
    FSendEmpty : Boolean;
    TheLineText : String;
    TheLineIndex : integer;
    //FRXTele      : array [0..63] of char;
    //FRXTeleLen   : integer;
    FRXBuffer    : array [0..63] of char;
    FRXBufferLen : integer;
    FReceiving   : Boolean;
    FRollover    : Boolean;
    FSimulation  : Boolean;
    FLineCount   : integer;
    procedure Execute; override;

    function  XmitTeleLow (Tele : String; waitack : boolean = true) : Boolean;
    function  XmitTele    (Adr : Char; Tele : String; Retry : integer = 5) : Boolean;
    function  XmitString  (Adr : Char; LineNr: Byte; S: String; Retry : integer = 5) : Boolean;
    function  PaintOnLED (index : integer; addr : Byte; Line : Byte; MaxRetry : Boolean = True) : Boolean;

    function  GetAnzeigeOk (index : Integer) : Boolean;
    procedure PrintText (txt : String);
    procedure DoPrintText;
    procedure DoCopySendList;
    procedure DoSended;
    procedure DoStatusChanged;

  public
    FListToSend : TStringList;
    FComPort    : TComPort;
    constructor Create (aComPort : TComPort; aAnzeigeCount : integer);
    destructor  Destroy; override;
    procedure   Abort;
    property    AnzeigeOk[index : integer] : Boolean read GetAnzeigeOk;
    property    OnPrintText : TOnPrintText read FOnPrintText write FOnPrintText;
    property    OnCopySendList : TNotifyEvent read FOnCopySendList write FOnCopySendList;
    property    OnSended : TNotifyEvent read FOnSended write FOnSended;
    property    Duration : DWord read FDuration write FDuration;
    property    OnStatusChanged : TNotifyEvent read FOnStatusChanged write FOnStatusChanged;
    property    Status : String read FStatus;
    property    SendEmpty : Boolean read FSendEmpty write FSendEmpty;
    property    OnPrintLine : TOnPrintLine read FOnPrintLine write FOnPrintLine;
    property    Simulation  : Boolean read FSimulation write FSimulation;

  end;

implementation

uses
{$IFDEF DEBUG}
dbugintf,
{$ENDIF}
math,
patconv,
sysutils, windows;




const
  StartChar = #$02;
  StopChar  = #$03;



{ Wichtig: Methoden und Eigenschaften von Objekten in der VCL können nur in einer
  Methode namens Synchronize verwendet werden; Beispiel:
      Synchronize(UpdateCaption);

  wobei UpdateCaption so aussehen könnte:

    procedure TCommunicationThread.UpdateCaption;
    begin
      Form1.Caption := 'Aktualisiert in einem Thread';
    end; }

{ TCommunicationThread }
constructor TCommunicationThread.Create (aComPort : TComPort; aAnzeigeCount : integer);
var
  AnzeigeCfg : TAnzeigeCfg;
  idx : integer;
  b : Pointer;
begin
  FAnzeigeList := TStringList.Create;
  for idx := 0 to aAnzeigeCount - 1 do
  begin
    AnzeigeCfg.Adresse := $10 + idx;
    AnzeigeCfg.Fault    := 0;
    b := pointer (AnzeigeCfg.all);
    FAnzeigeList.AddObject (Format ('Anzeige %d', [idx+1]), TObject (b));
  end;
  FreeOnTerminate := True;
  FComPort := aComPort;
  FListToSend := TStringList.Create;
  FStatus := '';
  FDuration := 10000;
  FSendEmpty := true;
  FSimulation := false;
  FRollover := false;
  FLineCount := 6;

  inherited Create (True);
end;

destructor TCommunicationThread.Destroy;
begin
  FListToSend.Free;
end;

procedure TCommunicationThread.DoPrintText;
begin
  if (assigned (FOnPrintText)) then
  begin
    FOnPrintText(FThePrintText);
  end;
end;

procedure TCommunicationThread.DoCopySendList;
begin
  if (assigned (FonCopySendList)) then
  begin
    FOnCopySendList(self);
  end;
end;

procedure TCommunicationThread.DoSended;
begin
  if (assigned (FonSended)) then
  begin
    FonSended(self);
  end;
end;


procedure TCommunicationThread.PrintText (txt : String);
begin
  txt := FComPort.Port + '-' + txt;
  {$IFDEF DEBUG}
  SendDebug(txt);
  {$ENDIF}

  if (assigned (FOnPrintText)) then
  begin
    FThePrintText := txt;
    Synchronize (DoPrintText);
  end;
end;

procedure TCommunicationThread.DoPrintLine;
begin
  FOnPrintLine (TheLineIndex, TheLineText);
end;

procedure TCommunicationThread.PrintLine (index : integer; txt : String);
begin
  if (assigned (FOnPrintLine)) then
  begin
    TheLineIndex := index;
    TheLineText := txt;
    Synchronize (DoPrintLine);
  end;
end;

procedure  TCommunicationThread.Abort;
begin
  FAbort := True;
end;

procedure  TCommunicationThread.SendMasterTele;
var
  toxmit : string;
begin
  PrintText ('SendMasterTele');
  ToXmit := StartChar + #$FF + #$ff + StopChar;
  XmitTeleLow (ToXmit, false);
end;


procedure  TCommunicationThread.SendSlaveTele;
var
  toxmit : string;
begin
  PrintText ('SendSlaveTele');
  ToXmit := StartChar + #$FF + #$00 + StopChar;
  XmitTeleLow (ToXmit, false);
end;



function TCommunicationThread.ProcessRx : Boolean;
var
  lRxBuffer : array [0..63] of char;
  lRxLength : Integer;
  RxI   : integer;
begin
  result := false;
  while (FComPort.InputCount > 0) and not FAbort do
  begin
    result := true;
    lRxLength := FComPort.InputCount;
    if (lRxLength >= 64 ) then
    begin
      lRxLength := 64;
    end;
    FComPort.Read (lRxBuffer, lRxLength);
    for rxI := 0 to lRxLength - 1 do
    begin
      case lRxBuffer[RxI] of
        StartChar : begin
                      FReceiving := True;
                      FillChar (FRXBuffer, sizeof (FRXBuffer), 0);
                      FRXBuffer[0] := StartChar;
                      FRXBufferLen := 1;
                     end;
        StopChar  : begin
                      if (FReceiving) then
                      begin
                        FRXBuffer[FRXBufferLen] := lRxBuffer[RxI];
                        inc (FRXBufferLen);
                        FReceiving := false;
                        PrintText ('>>' + Array2PattStr (FRXBuffer, FRXBufferLen));
                      end;
                    end;
        else        begin
                      if FReceiving then
                      begin
                        FRXBuffer[FRXBufferLen] := lRxBuffer[RxI];
                        inc (FRXBufferLen);
                      end else begin
                        FRXBuffer[0] := lRxBuffer[RxI];
                        FRXBufferLen := 0;
                      end;
                    end;
      end;
      if FRXBufferLen = 63 then FRXBufferLen := 0;
    end;
  end;
end;


function TCommunicationThread.AnythingReceiveded : Boolean;
var
  RxBuffer : array [0..63] of char;
  RxLength : Integer;
  start : dword;

  function ProcessChar (c : char) : Boolean;
  begin
    result := false;
    if (c = StartChar) then
    begin
      FRxState := 1;
      exit;
    end;
    case FRxState of
      0: ;
      1: if (c = #$FF) then inc (FRxState) else FRxState := 0;
      2: if (c = #$00) then inc (FRxState) else FRxState := 0;
      3: if (c = StopChar) then result := true else FRxState := 0;
    end;
    if Result then
      PrintText ('Slave Tele Received');
  end;

begin
  result := false;
  start := GetTickCount();
  while (GetTickCount() - start < 1000) and not FAbort do
  begin
    if ProcessRx then start := GetTickCount();
    if FRXBufferLen = 4 then
    begin
      result :=  (FRXBuffer[0] = StartChar)
             and (FRXBuffer[1] = #$FF)
             and (FRXBuffer[2] = #$00)
             and (FRXBuffer[3] = StopChar);
      if result then
      begin
        PrintText ('Slave Tele Received');
        break;
      end;
    end;
    sleep (250);
  end;
  FRXBufferLen := 0;
end;

procedure  TCommunicationThread.MasterDelay (TotDelay : dword);
var
  Delay : integer;
  start : dword;
begin
  start := GetTickCount();
  while ((start + TotDelay) > GetTickCount()) and not FAbort do
  begin
    if ProcessRx then exit;
    SendMasterTele();
    Delay := start + FDuration - GetTickCount();
    if (Delay > 250) then
    begin
      Delay := 250;
    end;
    Sleep(Delay);
    PrintText (Format ('Delay: %d', [Delay]));
  end;
end;

procedure  TCommunicationThread.Aribtrier;
var
  start : dword;
  stopp : dword;
begin
  PrintText ('Aribtrier Mode');
  start := GetTickCount();
  if AnythingReceiveded () then begin
    MasterDelay (1000);
  end;
  stopp := GetTickCount();
  PrintText (Format ('Duration: %f s', [(stopp-start)/1000]));
end;

procedure  TCommunicationThread.Master;
var
  AnzCfg : TAnzeigeCfg;

  procedure BuildStatus;
  var
    AnzIdx : integer;
    TmpStat : String;
    DefCnt : integer;
  begin
    TmpStat := '';
    DefCnt := 0;
    for AnzIdx := 0 to FAnzeigeList.Count - 1 do
    begin
      AnzCfg.ALL := Dword (FAnzeigeList.Objects[AnzIdx]);
      if AnzCfg.Fault > 2 then
      begin
        if DefCnt = 0 then
        begin
          TmpStat := Format ('%d', [AnzCfg.Adresse]);
        end else begin
          TmpStat := TmpStat + Format (', %d', [AnzCfg.Adresse]);
        end;
        inc (defCnt);
      end;
    end;
    if DefCnt > 1 then
    begin
      TmpStat := 'Keine Verbindung zu den Anzeigen: ' + TmpStat;
    end else begin
      if DefCnt > 0 then
      begin
        TmpStat := 'Keine Verbindung zur Anzeige ' + TmpStat;
      end;
    end;
    if (FStatus <> TmpStat) then
    begin
      FStatus := TmpStat;
      if assigned (FOnStatusChanged) then begin
        Synchronize (DoStatusChanged);
      end;
    end;
  end;


  procedure SendList;
  var
    start : dword;
    stopp : dword;
    LIndex : integer;
    TotDelay : integer;
    AnzIdx : integer;
    AnzCfg : TAnzeigeCfg;
    AnzOk  : Boolean;
    n      : integer;
    
  begin
    LIndex := 0;
    repeat
      if FAbort then Exit;
      start := GetTickCount();
      if FComPort.Connected then
      begin
        for AnzIdx := 0 to FAnzeigeList.Count - 1 do
        begin
          AnzCfg.ALL := Dword (FAnzeigeList.Objects[AnzIdx]);
                   // index, addr, Line
          AnzOk := true;
          for n := 0 to FLineCount - 1 do
          begin
            AnzOk := AnzOk and PaintOnLED (LIndex + n, AnzCfg.Adresse, 1 + n);
          end;
          if AnzOk then
          begin
            AnzCfg.Fault := 0;
          end else begin
            AnzCfg.Fault := min (AnzCfg.Fault + 1, 5);
          end;
          FAnzeigeList.Objects[AnzIdx] := Pointer (AnzCfg.all);
        end;
        Synchronize(DoSended);
        BuildStatus;
      end;
      stopp := GetTickCount();
      PrintText (Format ('Duration: %f s', [(stopp-start)/1000]));
      if (FRollover) then
      begin
        inc (LIndex);
      end else begin
        inc (LIndex, FLineCount);
      end;
      if LIndex >= FListToSend.Count then begin
        TotDelay := start + FDuration - GetTickCount() - 1000;
      end else begin
        TotDelay := start + FDuration - GetTickCount();
      end;
      MasterDelay (TotDelay);
      stopp := GetTickCount();
      PrintText (Format ('Duration: %f s', [(stopp-start)/1000]));
    until Lindex >= FListToSend.Count;
  end;




begin
  PrintText ('!!! Master State !!!');
  if FSendEmpty or (FListToSend.Count > 0) then
  begin
    SendList;
  end;
  SendSlaveTele ();
end;

procedure TCommunicationThread.Execute;
begin
  { Thread-Code hier plazieren }
  PrintText ('!!! Communication Thread started !!!');
  while FComPort.Connected do
  begin
    Synchronize (DoCopySendList);
    if (FListToSend.Count > 0) or FSendEmpty then
    begin
      if FAbort then break;
      Aribtrier();
      if FAbort then break;
      Master();
    end else begin
      if FAbort then break;
      ProcessRx;
      Sleep(500);
    end;
  end;
end;

function TCommunicationThread.XmitTeleLow (Tele : String; waitack : boolean) : Boolean;
var
  ToXmit : string;
  l      : Byte;
  AddStr : String;
  RxBuffer : array [0..4] of char;
  RxLength : Integer;
begin
  //if First then exit;
  Result := True;
  if not FComPort.Connected then Exit;
  //PrintText (Format ('XmitTeleLow:  %s', [Tele]));
  ToXmit := Tele;
  Inc (FXLines);
  AddStr := Format ('%.4d:', [FXLines]);
  For l := 1 to length (ToXmit) do begin
    AddStr := AddStr + Format (' 0x%.2X', [Byte (ToXmit[l])]);
  end;
  PrintText (AddStr);
  //FComPort.ClearBuffer (True, True);

  if FAbort then
  begin
    Result := False;
    Exit;
  end;

  if FSimulation then
  begin
    Result := true;
    Exit;
  end;

  Result := FComPort.Write (ToXMit[1], Length (ToXmit)) = Length (ToXmit);

  if not waitack then begin
    exit;
  end;
  FillChar (RxBuffer, 4, 0);

  if FAbort then
  begin
    Result := False;
    Exit;
  end;
  RxLength := FComPort.Read  (RxBuffer, 4);
  if RxLength = 4 then begin
    Result := (RxBuffer[0] = StartChar)
          and (RxBuffer[1] = Tele[2])
          and (RxBuffer[2] = #$41)
          and (RxBuffer[3] = StopChar);
  end else begin
    Result := False;
  end;
  if RxLength > 0 then
  begin
    AddStr := '>>';
    For l := 0 to RxLength - 1 do begin
      AddStr := AddStr + Format (' 0x%.2X', [Byte (RxBuffer[l])]);
    end;
    PrintText (AddStr);
  end;
end;

function TCommunicationThread.XmitTele (Adr : Char; Tele : String; retry : integer) : Boolean;
var
  ToXmit : string;
begin
  //PrintText (Format ('XmitTele: %d, %s', [Byte (adr), Tele]));
  ToXmit := StartChar + Adr + Tele + StopChar;
  Result := False;
  while (retry > 0) and (Result = False) do
  begin
    if FAbort then Exit;
    Result := XmitTeleLow (ToXMit);
    Dec (retry);
  end;
end;

function TCommunicationThread.XmitString  (Adr : Char; LineNr: Byte; S: String; Retry : integer) : Boolean;
var
  Line : Char;
  Fx   : Char;
begin
  //PrintText (Format ('XmitString: %d, %d, %s', [Byte (adr), LineNr, S]));
  Line := Char (LineNr + $30);
  FX   := CHar ($20);
  Result := XMitTele (Char (Adr), #$30 + Line + FX + S, Retry);
end;

function TCommunicationThread.PaintOnLED (index : Integer; addr : Byte; Line : Byte; MaxRetry : boolean) : Boolean;
var
  ToPaint : string;
begin
  result := false;
  if (FRollover) and (index >= FListToSend.Count) then
  begin
    index := 0;
  end;
  if index >= FListToSend.Count then
  begin
    ToPaint := '';
  end else begin
    ToPaint := FListToSend [index];
  end;
  PrintText (Format ('Paint: %d, %d, %d (%s)', [index, addr, Line, ToPaint]));
  PrintLine (addr * 256 + Line, ToPaint);
  result := XmitString (char (addr), Line, ToPaint);
  if FAbort then
  begin
    result := true;
  end;
end;

function  TCommunicationThread.GetAnzeigeOk (index : Integer) : Boolean;
var
  AnzCfg : TAnzeigeCfg;
begin
  //Result := True;
  AnzCfg.All := Dword (FAnzeigeList.Objects[index]);
  Result := AnzCfg.Fault < 2;
end;


function TCommunicationThread.MasterTeleReceived: Boolean;
begin
  result := false;
end;

procedure TCommunicationThread.DoStatusChanged;
begin
  if (assigned (FonStatusChanged)) then
  begin
    FonStatusChanged(self);
  end;
end;

end.
