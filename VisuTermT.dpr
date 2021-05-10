program VisuTermT;

uses
  Forms,
  AldiMainF in 'AldiMainF.pas' {Main},
  AldiKonfig in 'AldiKonfig.pas' {AldiKonfigDlg},
  CommunicationThread in 'CommunicationThread.pas',
  DebugWindow in 'DebugWindow.pas' {DebugWindowDlg},
  ShutDownF in 'ShutDownF.pas' {ShutDownDlg};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.CreateForm(TAldiKonfigDlg, AldiKonfigDlg);
  Application.CreateForm(TDebugWindowDlg, DebugWindowDlg);
  Application.CreateForm(TShutDownDlg, ShutDownDlg);
  Application.Run;
end.
