unit unit1010_frmMain;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Forms, Controls, Graphics, ComCtrls, Menus,
  StdCtrls, ExtCtrls, Spin, EditBtn, CheckLst, BGRAGraphicControl,
  BGRABitmap, BGRAClasses,
  BGRABitmapTypes;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    GCPlayer: TBGRAGraphicControl;
    CheckBox2: TCheckBox;
    CheckListBox1: TCheckListBox;
    CheckListBox2: TCheckListBox;
    Edit1: TEdit;
    FileNameEdit1: TFileNameEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox6: TGroupBox;
    GroupBox7: TGroupBox;
    GroupBox8: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    lblBlendPercent: TLabel;
    lblMinDays: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    ListBox1: TListBox;
    ListBox2: TListBox;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    SpinEdit1: TSpinEdit;
    SpinEdit2: TSpinEdit;
    SpinEdit3: TSpinEdit;
    seBlendPeriod: TSpinEdit;
    StatusBar1: TStatusBar;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure GCPlayerRedraw(Sender: TObject; b: TBGRABitmap);
    procedure pbPlayerJourneyPaint(Sender: TObject);
  private
    procedure PaintPlayerSummary;
    function PaintFitLvl(const b: TBGRABitmap; aName: string;
      fitStage: integer; percent: real; col: TBGRAPixel): integer;
    function PaintBlending(const b: TBGRABitmap; fitStage: integer;
      percent, blend: real; col: TBGRAPixel): integer;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.pbPlayerJourneyPaint(Sender: TObject);
begin
  PaintPlayerSummary;
end;

procedure TfrmMain.PaintPlayerSummary;
begin
end;

function TfrmMain.PaintFitLvl(const b: TBGRABitmap; aName: string;
  fitStage: integer; percent: real; col: TBGRAPixel): integer;
var
  h, w, pw: integer;
begin
  h := b.Height;
  w := b.Width;
  pw := Round(w * percent);
  Result := fitStage + pw;
  // BG
  b.FillRect(fitStage, 0, Result, h, col, dmSet);
  // Fitness lvl name
  b.TextOut((pw div 2) + fitStage, (h div 2) - (b.FontHeight div 2),
    aName, clBlack, taCenter);
  // Bodyslide min
  b.TextOut(fitStage + 6, h - b.FontHeight, '0', clBlack, taLeftJustify);
  // Bodyslide max
  b.TextOut(Result - 6, h - b.FontHeight, '100', clBlack, taRightJustify);
end;

function TfrmMain.PaintBlending(const b: TBGRABitmap; fitStage: integer;
  percent, blend: real; col: TBGRAPixel): integer;
var
  h, w, pw, gd: integer;
begin
  h := b.Height;
  w := b.Width;
  pw := Round(w * percent);
  Result := fitStage + pw;

  gd := Round(pw * blend);

  // Left gradient
  if fitStage > 0 then
    b.GradientFill(fitStage, 0, fitStage + gd, h,
      col, BGRAPixelTransparent, gtLinear,
      PointF(fitStage, 0), PointF(fitStage + gd, 0), dmDrawWithTransparency
      );
  // Right gradient
  if Result < w - 3 then
  b.GradientFill(Result, 0, Result - gd, h,
    col, BGRAPixelTransparent, gtLinear,
    PointF(Result, 0), PointF(Result - gd, 0), dmDrawWithTransparency
    );
  // Transition line
  b.DrawLineAntialias(Result, 0, Result, h, clBlue, 2, True);
  //b.TextOut(Result + 2, 2, 'Transition', clBlue, taLeftJustify);
end;

procedure TfrmMain.GCPlayerRedraw(Sender: TObject; b: TBGRABitmap);
var
  //temp: TBGRABitmap;
  lvl, h, w, days, d1, d2, d3: integer;
begin
  d1 := 10;
  d2 := 50;
  d3 := 160;
  days := d1 + d2 + d3;
  b.FillTransparent;
  lvl := PaintFitLvl(b, 'Flabby', 0, d1 / days, BGRA(210, 200, 0));
  lvl := PaintFitLvl(b, 'Plain', lvl, d2 / days, BGRA(210, 150, 0));
  lvl := PaintFitLvl(b, 'Hot', lvl, d3 / days, BGRA(210, 100, 0));

  lvl := PaintBlending(b, 0, d1 / days, 0.3, BGRA(0, 100, 210, 200));
  lvl := PaintBlending(b, lvl, d2 / days, 0.2, BGRA(0, 100, 210, 200));
  lvl := PaintBlending(b, lvl, d3 / days, 0.1, BGRA(0, 100, 210, 200));

  //b.FillEllipseAntialias(GCPlayer.Width div 2, (GCPlayer.Height) div 2,
  //  (GCPlayer.Width - 10) div 2, (GCPlayer.Height - 10) div 2, BGRA(150, 150, 150));


  //b.GradientFill(0, 0, w, h,
  //  BGRABlack, BGRAPixelTransparent, gtLinear,
  //  PointF(0, 0), PointF(100, 0), dmDrawWithTransparency
  //  );
end;


end.
