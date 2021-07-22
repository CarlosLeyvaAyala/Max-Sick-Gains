program MaxSickGains;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, FrameViewer09, runtimetypeinfocontrols, lazcontrols, unit1010_frmMain,
  unit_9010_DmMain
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TDm_main, Dm_main);
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

