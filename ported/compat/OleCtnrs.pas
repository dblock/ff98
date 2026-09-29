unit OleCtnrs;

// Stand-in for the Delphi VCL TOleContainer. The original embedded the Word
// document as an OLE object, which needs Microsoft Word. This version draws the
// document's text, read by ReadWordDocument in docdll.dll, as a scaled page.

interface

uses Windows, Classes, SysUtils, Controls, Graphics, LazUTF8;

type
  TSizeMode = (smClip, smCenter, smScale, smStretch, smAutoSize);
  TAutoActivate = (aaManual, aaGetFocus, aaDoubleClick);

  TOleContainer = class(TCustomControl)
  private
    FLines: TStringList;
    FSizeMode: TSizeMode;
    FAutoVerbMenu: Boolean;
    FAutoActivate: TAutoActivate;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CreateObjectFromFile(const FileName: string; Iconic: Boolean);
    procedure Close;
    procedure DestroyObject;
  published
    property SizeMode: TSizeMode read FSizeMode write FSizeMode;
    property AutoVerbMenu: Boolean read FAutoVerbMenu write FAutoVerbMenu;
    property AutoActivate: TAutoActivate read FAutoActivate write FAutoActivate;
    property Caption;
    property TabOrder;
  end;

implementation

function ReadWordDocument(FileName: PChar): PChar; cdecl; external 'docdll.dll' name 'ReadWordDocument';

constructor TOleContainer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLines := TStringList.Create;
  Color := clWhite;
end;

destructor TOleContainer.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TOleContainer.CreateObjectFromFile(const FileName: string; Iconic: Boolean);
var
  Text: PChar;
  S: RawByteString;
  i: Integer;
begin
  FLines.Clear;
  Text := ReadWordDocument(PChar(FileName));
  if Text = nil then raise EInOutError.Create('Unable to read ' + FileName);
  S := Text;
  // docdll.dll folds accented characters down by 64, as TFFTxtPreview.ShowDocument undoes.
  for i := 1 to Length(S) do
    if Ord(S[i]) > 127 then S[i] := Chr((Ord(S[i]) + 64) and $FF);
  FLines.Text := WinCPToUTF8(StringReplace(S, #13, #10, [rfReplaceAll]));
  Invalidate;
end;

procedure TOleContainer.Close;
begin
end;

procedure TOleContainer.DestroyObject;
begin
  FLines.Clear;
  Invalidate;
end;

procedure TOleContainer.Paint;
var
  i, Margin, LineHeight, Y: Integer;
begin
  Canvas.Brush.Color := clWhite;
  Canvas.FillRect(ClientRect);
  if FLines.Count = 0 then Exit;
  // A page is about 80 characters wide; the zoom makes the container larger.
  Margin := Width div 20;
  Canvas.Font.Name := 'Times New Roman';
  Canvas.Font.Color := clBlack;
  Canvas.Font.Height := -(Width div 45);
  LineHeight := Canvas.TextHeight('Wg') + 1;
  Y := Margin;
  for i := 0 to FLines.Count - 1 do begin
    if Y > Height then Break;
    Canvas.TextOut(Margin, Y, FLines[i]);
    Inc(Y, LineHeight);
  end;
end;

end.
