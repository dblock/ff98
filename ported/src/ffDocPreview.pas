unit ffDocPreview;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, d32reg, d32gen, ffCommon, FFProperties, LazUTF8;

type
  TFFTxtPreview = class(TForm)
    TextMemo: TMemo;
    CMTPanel: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    FNName: TLabel;
    FNSize: TLabel;
    FNCreated: TLabel;
    FNAccess: TLabel;
    FNWrite: TLabel;
    FNVirtual: TLabel;
    FFPImage: TImage;
    FFLogo: TSpeedButton;
    BBOk: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure CMTPanelResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure BBOkClick(Sender: TObject);
  private
    TextMemoMinWidth: integer;
    minWidth, minHeight: integer;
    procedure WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo); message WM_GetMinMaxInfo;
    procedure WMwindowposchanging(var M: TWMwindowposchanging); message wm_windowposchanging;
    procedure ReadRegistry;
    procedure WriteRegistry;
    procedure ShowProps(FileName, VirtualDir: string);
    procedure SetPropWidths;
  public
    procedure ShowDocument(Root, VirtualFolder: string);
  end;

  function ReadWordDocument(FileName: PChar): PChar; cdecl external 'docdll.dll' name 'ReadWordDocument';

var
  FFTxtPreview: TFFTxtPreview;

implementation

uses ff98;

{$R *.lfm}

procedure TFFTxtPreview.ShowProps(FileName, VirtualDir: string);
var
   Handle: THandle;
   FindData: TWin32FindData;
begin
     try
     Screen.Cursor := crHourGlass;
     Handle := FindFirstFile(PChar(FileName), FindData);
     FNName.Caption := ExtractFileName(FileName);
     FNSize.Caption := TFFProp.NiceSize((FindData.nFileSizeHigh * MAXDWORD) + FindData.nFileSizeLow) + ' bytes';
     FNCreated.Caption := TFFProp.GetDateField(FindData.ftCreationTime);
     FNAccess.Caption := TFFProp.GetDateField(FindData.ftLastAccessTime);
     FNWrite.Caption := TFFProp.GetDateField(FindData.ftLastWriteTime);
     FNVirtual.Caption := VirtualDir;
     Self.Caption := 'File & Folder Word Doc Text Preview - ' + GetFileTypeName(ExtractFileExt(FileName));

     ExtractImageIcon(FileName, FFPImage);
     SetPropWidths;
     Windows.FindClose(Handle);
     except
     end;
     Screen.Cursor := crDefault;
     end;

procedure TFFTxtPreview.SetPropWidths;
var
   i, t: integer;
begin
     minWidth := 0;
     for i:=0 to CMTPanel.ControlCount - 1 do begin
         t:= CMTPanel.Controls[i].Width + CMTPanel.Controls[i].Left;
         if t > minWidth then minWidth := t;
         end;
     CMTPanel.Width := minWidth + 10;
     MinWidth := MinWidth + TextMemoMinWidth;
     end;

procedure TFFTxtPreview.ShowDocument(Root, VirtualFolder: string);
var
   iRes: PChar;
   i: integer;
   Lines: TStringList;
   CurLine: string;
begin
     Lines := TStringList.Create;
     CurLine := '';
     Root := ffmain.AppendExt(Root, '.doc');
     ShowProps(Root, VirtualFolder);
     TextMemo.Text := '';     
     try
     Screen.Cursor := crHourGlass;
     iRes := ReadWordDocument(PChar(Root));
     for i:=0 to Length(iRes) - 1 do begin
         if (Ord(iRes[i]) > 127) then iRes[i] := Chr(Ord(iRes[i]) + 64);
         if (Ord(iRes[i]) = 10) then begin
            Lines.Add(WinCPToUTF8(CurLine));
            CurLine := '';
            end else if (Ord(iRes[i]) >= 32)  then CurLine := CurLine + iRes[i];
         end;
     Lines.Add(WinCPToUTF8(CurLine));
     TextMemo.Lines := Lines;
     except
     TextMemo.Lines.Add('[unable to read document]');
     end;
     Screen.Cursor := crDefault;
     Lines.Destroy;

     end;

procedure TFFTxtPreview.WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo);
begin
   inherited;
   with Msg.MinMaxInfo^ do begin
      if ptMinTrackSize.x< minWidth then ptMinTrackSize.x:= minWidth;
      if ptMinTrackSize.y< minHeight then ptMinTrackSize.y:= minHeight;
      if ptMaxTrackSize.x>Screen.Width then ptMaxTrackSize.x:=Screen.Width;
      if ptMaxTrackSize.y>Screen.Height then ptMaxTrackSize.y:=Screen.Height;
      end;
   end;

procedure TFFTxtPreview.WMwindowposchanging(var M: TWMwindowposchanging);
begin
   inherited;
   with M.WindowPos^ do begin
      if cx<= minWidth then cx:= minWidth;
      if cy<= minHeight then cy:= minHeight;
      if (cx<>Width) or (cy<>Height) then begin
         if x<0 then begin cx:=cx+x; x:=0; end;
         if y<0 then begin cy:=cy+y; y:=0; end;
         if x+cx>Screen.Width then cx:=Screen.Width-x;
         if y+cy>Screen.Height then cy:=Screen.Height-y;
      end else begin
         if x<0 then x:=0;
         if y<0 then y:=0;
         if x+cx>Screen.Width then x:=Screen.Width-cx;
         if y+cy>Screen.Height then y:=Screen.Height-cy;
      end;
      end;
  end;

procedure TFFTxtPreview.CMTPanelResize(Sender: TObject);
begin
     BBOk.Top := CMTPanel.ClientHeight - BBOk.Height - 6;
     BBOk.Left := 6;
     end;

procedure TFFTxtPreview.ReadRegistry;
var
   t: integer;
begin
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFTxtView.Width'); if t > 0 then Self.Width := t;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFTxtView.Height'); if t > 0 then Self.Height := t;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFTxtView.Left'); if t >= 0 then Self.Left := t else Self.Left := (Screen.Width - Self.Width) div 2;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFTxtView.Top'); if t >= 0 then Self.Top := t else Self.Top := (Screen.Height - Self.Height) div 2;
     end;

procedure TFFTxtPreview.WriteRegistry;
begin
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFTxtView.Width', Self.Width);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFTxtView.Height', Self.Height);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFTxtView.Left', Self.Left);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFTxtView.Top', Self.Top);
     end;

procedure TFFTxtPreview.FormCreate(Sender: TObject);
begin
     minHeight := Height;
     TextMemoMinWidth := 200;
     ReadRegistry;
     end;

procedure TFFTxtPreview.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
     WriteRegistry;
     end;

procedure TFFTxtPreview.BBOkClick(Sender: TObject);
begin
     Close;
     end;

end.
