{***************************************************************
*
* Project : FastAntiAlias
* Unit    : FAAlias
* Purpose : To demonstrate the use of super-sampling technique
*           to anti-alias an image, as well to fast access to
*           a bitmap image pixels using the ScanLine property
* Author  : Nacho Urenda (based on an example project by Rod
*           Stephens published on Delphi Informant,
*           april 98 issue)
* Date    : 15/08/2000
*
***************************************************************}

unit FAAlias;

interface

uses
  Windows, SysUtils, Graphics, Controls, Forms, StdCtrls, ExtCtrls,
  ComCtrls, ShellApi, Classes;

type
  TAntiAliasForm = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    OutBox: TPaintBox;
    OrigBox: TPaintBox;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    ProcessBtn: TButton;
    ZoomOutBox: TCheckBox;
    ZoomOrigBox: TCheckBox;
    Method: TRadioGroup;
    OrigVScrollBar: TScrollBar;
    OutVScrollBar: TScrollBar;
    OrigHScrollBar: TScrollBar;
    OutHScrollBar: TScrollBar;
    Memo1: TMemo;
    procedure SeparateColor(color : TColor; var r, g, b : Integer);
    procedure OutBoxPaint(Sender: TObject);
    procedure DrawFace(bm : TBitmap; pen_width : Integer);
    procedure OrigBoxPaint(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ProcessBtnClick(Sender: TObject);
    procedure DrawBigBmp;
    procedure FormCreate(Sender: TObject);
    procedure ZoomOrigBoxClick(Sender: TObject);
    procedure ZoomOutBoxClick(Sender: TObject);
    procedure Label10Click(Sender: TObject);
    procedure Label12Click(Sender: TObject);
    procedure OrigScrollBarChange(Sender: TObject);
    procedure OutScrollBarChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure AntiAliasPicture;
    procedure FastAntiAliasPicture;
  end;

var
  AntiAliasForm: TAntiAliasForm;



const
    MaxPixelCount   =  32768;

type
    pRGBArray  =  ^TRGBArray;
    TRGBArray  =  ARRAY[0..MaxPixelCount-1] OF TRGBTriple;

implementation

{$R *.DFM}

var
    orig_bmp, big_bmp, out_bmp : TBitmap;


{***************************************************************
 TAntiAliasForm.SeparateColor
   15/08/2000

   The original procedure by Rod Stephens has been somewhat
   fastened
***************************************************************}
procedure TAntiAliasForm.SeparateColor(color : TColor;
  var r, g, b : Integer);
begin
  r := Byte(color);
  g := Byte(color shr 8);
  b := Byte(color shr 16);
end;


{***************************************************************
 TAntiAliasForm.AntiAliasPicture
   15/08/2000

   The original AAliasPicture procedure by Rod Stephens has been
   rewritten to improve the supersampling from double to triple
   factor, and somewhat simplified...
***************************************************************}
procedure TAntiAliasForm.AntiAliasPicture;
var
  x, y: integer;
  totr, totg, totb, r, g, b : integer;
  i, j: integer;
begin
  // For each row
  for y := 0 to orig_bmp.Height - 1 do
  begin
    // For each column
    for x := 0 to orig_bmp.Width - 1 do
    begin
      totr := 0;
      totg := 0;
      totb := 0;

      // Read each of the sample pixels
      for i := 0 to 2 do
      begin
        for j := 0 to 2 do
        begin
          SeparateColor(big_bmp.Canvas.Pixels[(x*3) + j, (y*3) + i], r, g, b);
          totr := totr + r;
          totg := totg + g;
          totb := totb + b;
        end;
      end;

      out_bmp.Canvas.Pixels[x,y] := RGB(totr div 9,
                                        totg div 9,
                                        totb div 9);
    end; // end for columns
  end; // end for rows
end;



{***************************************************************
 TAntiAliasForm.FastAAliasPicture
   20/08/2000
***************************************************************}
procedure TAntiAliasForm.FastAntiAliasPicture;
var
  x, y, cx, cy : integer;
  totr, totg, totb : integer;
  Row1, Row2, Row3, DestRow: pRGBArray;
  i: integer;
begin
  // For each row
  for y := 0 to orig_bmp.Height - 1 do
  begin
    // We compute samples of 3 x 3 pixels
    cy := y*3;
    // Get pointers to actual, previous and next rows in supersampled bitmap
    Row1 := big_bmp.ScanLine[cy];
    Row2 := big_bmp.ScanLine[cy+1];
    Row3 := big_bmp.ScanLine[cy+2];

    // Get a pointer to destination row in output bitmap
    DestRow := out_bmp.ScanLine[y];

    // For each column...
    for x := 0 to orig_bmp.Width - 1 do
    begin
      // We compute samples of 3 x 3 pixels
      cx := 3*x;

      // Initialize result color
      totr := 0;
      totg := 0;
      totb := 0;

      // For each pixel in sample
      for i := 0 to 2 do
      begin
        // New red value
        totr := totr + Row1[cx + i].rgbtRed
             + Row2[cx + i].rgbtRed
             + Row3[cx + i].rgbtRed;
        // New green value
        totg := totg + Row1[cx + i].rgbtGreen
             + Row2[cx + i].rgbtGreen
             + Row3[cx + i].rgbtGreen;
        // New blue value
        totb := totb + Row1[cx + i].rgbtBlue
             + Row2[cx + i].rgbtBlue
             + Row3[cx + i].rgbtBlue;
      end;

      // Set output pixel colors
      DestRow[x].rgbtRed := totr div 9;
      DestRow[x].rgbtGreen := totg div 9;
      DestRow[x].rgbtBlue := totb div 9;
    end;
  end;
end;


{***************************************************************
 TAntiAliasForm.OrigBoxPaint
 TAntiAliasForm.OutBoxPaint
   15/08/2000

   The original procedures by Rod Stephens have been modified
   to allow the zooming and panning effects
***************************************************************}
procedure TAntiAliasForm.OrigBoxPaint(Sender: TObject);
var ZoomRect: TRect;
begin
  // If zoomed display an enlarged protion of the bitmap
  if ZoomOrigBox.Checked then
  begin
    ZoomRect := Rect(OrigHScrollBar.Position,
                     OrigVScrollBar.Position,
                     OrigHScrollBar.Position+60,
                     OrigVScrollBar.Position+60);
    OrigBox.Canvas.CopyRect(OrigBox.ClientRect, orig_bmp.Canvas, ZoomRect)
  end else
    OrigBox.Canvas.Draw(0, 0, orig_bmp);
end;

procedure TAntiAliasForm.OutBoxPaint(Sender: TObject);
var ZoomRect: TRect;
begin
  if ZoomOutBox.Checked then
  begin
    ZoomRect := Rect(OutHScrollBar.Position,
                     OutVScrollBar.Position,
                     OutHScrollBar.Position+60,
                     OutVScrollBar.Position+60);
    OutBox.Canvas.CopyRect(OutBox.ClientRect, out_bmp.Canvas, ZoomRect)
  end else
    OutBox.Canvas.Draw(0, 0, out_bmp);
end;


{***************************************************************
 TAntiAliasForm.DrawFace
   15/08/2000

   Procedure written by Rod Stephens (unmodified)
***************************************************************}
procedure TAntiAliasForm.DrawFace(bm : TBitmap;
                                  pen_width : Integer);
var
  x1, y1, x2, y2, x3, y3, x4, y4 : Integer;
  old_width                      : Integer;
  old_color                      : TColor;
begin
  // Save the original brush color and pen width.
  old_width := bm.Canvas.Pen.Width;
  old_color := bm.Canvas.Brush.Color;

  // Erase background;
  bm.Canvas.Pen.Color := clwhite;
  bm.Canvas.Brush.Color := clwhite;
  bm.Canvas.Rectangle(0, 0, bm.width, bm.height);

  // Draw the head.
  bm.Canvas.Pen.Color := clBlack;
  bm.Canvas.Pen.Width := pen_width;
  bm.Canvas.Brush.Color := clYellow;
  x1 := Round(bm.Width * 0.05);
  y1 := x1;
  x2 := Round(bm.Height * 0.95);
  y2 := x2;
  bm.Canvas.Ellipse(x1, y1, x2, y2);

  // Draw the eyes.
  bm.Canvas.Brush.Color := clWhite;
  x1 := Round(bm.Width * 0.25);
  y1 := Round(bm.Height * 0.25);
  x2 := Round(bm.Width * 0.4);
  y2 := Round(bm.Height * 0.4);
  bm.Canvas.Ellipse(x1, y1, x2, y2);
  x1 := Round(bm.Width * 0.75);
  x2 := Round(bm.Width * 0.6);
  bm.Canvas.Ellipse(x1, y1, x2, y2);

  // Draw the pupils.
  bm.Canvas.Brush.Color := clBlack;
  bm.Canvas.Refresh;
  x1 := Round(bm.Width * 0.275);
  y1 := Round(bm.Height * 0.3);
  x2 := Round(bm.Width * 0.375);
  y2 := Round(bm.Height * 0.4);
  bm.Canvas.Ellipse(x1, y1, x2, y2);
  x1 := Round(bm.Width * 0.725);
  x2 := Round(bm.Width * 0.625);
  bm.Canvas.Ellipse(x1, y1, x2, y2);

  // Draw the nose.
  bm.Canvas.Brush.Color := clAqua;
  x1 := Round(bm.Width * 0.425);
  y1 := Round(bm.Height * 0.425);
  x2 := Round(bm.Width * 0.575);
  y2 := Round(bm.Height * 0.6);
  bm.Canvas.Ellipse(x1, y1, x2, y2);

  // Draw a crooked smile.
  x1 := Round(bm.Width * 0.25);
  y1 := Round(bm.Height * 0.25);
  x2 := Round(bm.Width * 0.75);
  y2 := Round(bm.Height * 0.75);
  x3 := Round(bm.Width * 0.4);
  y3 := Round(bm.Height * 0.6);
  x4 := Round(bm.Width * 0.8);
  y4 := Round(bm.Height * 0.6);
  bm.Canvas.Arc(x1, y1, x2, y2, x3, y3, x4, y4);

  bm.Canvas.Brush.Color := old_color;
  bm.Canvas.Pen.Width := old_width;
end;


{***************************************************************
 TAntiAliasForm.FormDestroy
   15/08/2000

   We must free the memory bitmaps before exiting
***************************************************************}
procedure TAntiAliasForm.FormDestroy(Sender: TObject);
begin
  orig_bmp.Free;
  big_bmp.Free;
  out_bmp.Free;
end;


{***************************************************************
 TAntiAliasForm.Button1Click
   15/08/2000
***************************************************************}
procedure TAntiAliasForm.ProcessBtnClick(Sender: TObject);
var IniTime, ElapsedTime: DWord;
begin
  // Display the hourglass cursor.
  Screen.Cursor := crHourGlass;

  // Erase the time elapsed label
  Label4.Caption := '';
  Label4.Refresh;

  // Erase the result PaintBox.
  out_bmp.Canvas.Brush.color := clWhite;
  out_bmp.Canvas.FillRect(out_bmp.Canvas.ClipRect);
  // Force repaint of outbox
  OutBox.Refresh;

  // Draw the supersampled image
  DrawBigBmp;

  // Create the anti-aliased version.
  if Method.ItemIndex = 0 then
  begin
    IniTime := GetTickCount;
    AntiAliasPicture;
    ElapsedTime := GetTickCount - IniTime;
  end else begin
    IniTime := GetTickCount;
    FastAntiAliasPicture;
    ElapsedTime := GetTickCount - IniTime;
  end;

  // Force repaint of output PaintBox
  OutBox.Invalidate;

  // Just to display calculation time
  Label4.Caption := IntToStr(ElapsedTime) + ' ms';
  Label4.Refresh;

  // Force repaint of outbox
  OutBox.Invalidate;

  // Remove the hourglass cursor.
  Screen.Cursor := crDefault;
end;


{***************************************************************
 TAntiAliasForm.DrawBigBmp
   15/08/2000
***************************************************************}
procedure TAntiAliasForm.DrawBigBmp;
begin
  // Draw the supersampled image
  DrawFace(big_bmp, 6);
end;



{***************************************************************
 TAntiAliasForm.FormCreate
   15/08/2000
***************************************************************}
procedure TAntiAliasForm.FormCreate(Sender: TObject);
begin
  // Create the necessary memory bitmaps.
  orig_bmp := TBitmap.Create;
  orig_bmp.Width := OrigBox.ClientWidth;
  orig_bmp.Height := OrigBox.ClientHeight;
  // Bitmap MUST be 24 bits to get ScanLine[] to work
  orig_bmp.PixelFormat := pf24bit;

  // Initialize original bitmap
  DrawFace(Orig_bmp, 2);

  // Create supersampled bitmap
  big_bmp := TBitmap.Create;
  big_bmp.Width := orig_bmp.Width * 3;
  big_bmp.Height := orig_bmp.Height * 3;
  big_bmp.PixelFormat := pf24bit;

  // Create output bitmap
  out_bmp := TBitmap.Create;
  out_bmp.Width := orig_bmp.Width;
  out_bmp.Height := orig_bmp.Height;
  out_bmp.PixelFormat := pf24bit;

  // Make sure the 'Example' page is visible on startup
  PageControl1.ActivePage := TabSheet1;

  // Initialize Scroll Bars
  OrigHScrollBar.Min := 0;
  OrigHScrollBar.Max := OrigBox.Width - (OrigBox.Width div 5);
  OrigHScrollBar.LargeChange := OrigBox.Width div 5;
  OrigVScrollBar.Min := 0;
  OrigVScrollBar.Max := OrigBox.Height - (OrigBox.Height div 5);
  OrigVScrollBar.LargeChange := OrigBox.Height div 5;

  OutHScrollBar.Min := 0;
  OutHScrollBar.Max := OutBox.Width - (OutBox.Width div 5);
  OutHScrollBar.LargeChange := OutBox.Width div 5;
  OutVScrollBar.Min := 0;
  OutVScrollBar.Max := OutBox.Height - (OutBox.Height div 5);
  OutVScrollBar.LargeChange := OutBox.Height div 5;

  // Load text into the 'How it works...' memo
  Memo1.Lines.LoadFromFile('ReadMe.txt');
end;


{***************************************************************
 TAntiAliasForm.ZoomOrigBoxClick
   15/08/2000
***************************************************************}
procedure TAntiAliasForm.ZoomOrigBoxClick(Sender: TObject);
begin
  with TCheckBox(Sender) do
  begin
    OrigHScrollBar.Visible := Checked;
    OrigVScrollBar.Visible := Checked;
  end;
  OrigBox.Invalidate;
end;


{***************************************************************
 TAntiAliasForm.ZoomOutBoxClick
   15/08/2000
***************************************************************}
procedure TAntiAliasForm.ZoomOutBoxClick(Sender: TObject);
begin
  with TCheckBox(Sender) do
  begin
    OutHScrollBar.Visible := Checked;
    OutVScrollBar.Visible := Checked;
  end;
  OutBox.Invalidate;
end;




{***************************************************************
 TAntiAliasForm.Label10Click
   16/08/2000
***************************************************************}
procedure TAntiAliasForm.Label10Click(Sender: TObject);
begin
 ShellExecute(ValidParentForm(Self).Handle, 'open',
              PChar(TLabel(Sender).Caption),
              NIL, NIL, SW_SHOWNORMAL);
end;


{***************************************************************
 TAntiAliasForm.Label12Click
   16/08/2000
***************************************************************}
procedure TAntiAliasForm.Label12Click(Sender: TObject);
begin
 ShellExecute(ValidParentForm(Self).Handle, 'open',
              PChar('mailto:nurenda@wanadoo.es?subject=Fast antialias'),
              NIL, NIL, SW_SHOWNORMAL);
end;


{***************************************************************
 TAntiAliasForm.OrigScrollBarChange
   20/08/2000
***************************************************************}
procedure TAntiAliasForm.OrigScrollBarChange(Sender: TObject);
begin
  OrigBox.Invalidate;
end;


{***************************************************************
 TAntiAliasForm.OutScrollBarChange
   20/08/2000
***************************************************************}
procedure TAntiAliasForm.OutScrollBarChange(Sender: TObject);
begin
  OutBox.Invalidate
end;

end.
