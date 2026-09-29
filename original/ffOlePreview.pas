unit ffOlePreview;

interface

uses
  Ole2, Dialogs, ExtCtrls, ShlObj, StdCtrls, Buttons, OleCtnrs,
  Windows, Messages, CommCtrl, ActiveX, OleDlg, SysUtils, Classes,
  Controls, Forms, Menus, Graphics, ComObj, d32reg, d32gen, Spin,
  FFCommon, FFProperties, ComCtrls;

type
  TFFPreview = class(TForm)
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
    BBOk: TBitBtn;
    FFLogo: TSpeedButton;
    PreviewPanel: TPanel;
    Horizontal: TScrollBar;
    Vertical: TScrollBar;
    Spin: TSpinEdit;
    Label1: TLabel;
    Status: TStatusBar;
    cmdCenter: TSpeedButton;
    South: TSpeedButton;
    North: TSpeedButton;
    East: TSpeedButton;
    West: TSpeedButton;
    NSTimer: TTimer;
    OleContainer1: TOleContainer;
    procedure BBOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CMTPanelResize(Sender: TObject);
    procedure PreviewPanelResize(Sender: TObject);
    procedure VerticalScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure HorizontalScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure SpinChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure SpinEnter(Sender: TObject);
    procedure cmdCenterClick(Sender: TObject);
    procedure EastMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure NorthMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure WestMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure SouthMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure NorthMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure NSTimerTimer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    minWidth, minHeight: integer;
    OleMinWidth: integer;
    OldFileName: string;
    OleContainer: TOleContainer;
    procedure WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo); message WM_GetMinMaxInfo;
    procedure WMwindowposchanging(var M: TWMwindowposchanging); message wm_windowposchanging;
    procedure ReadRegistry;
    procedure WriteRegistry;
    procedure VsHsScroll;
    //function ExtractWordDoc(FileName: string): string;
  public
    procedure CreateLinkToFile(FileName: string; VirtualDir: string);
    procedure SetPropWidths;
  end;

var
  FFPreview: TFFPreview;
  BUFSIZE: integer = 16384;

implementation

{$R *.DFM}

procedure TFFPreview.SetPropWidths;
var
   i, t: integer;
begin
     minWidth := 0;
     for i:=0 to CMTPanel.ControlCount - 1 do begin
         t:= CMTPanel.Controls[i].Width + CMTPanel.Controls[i].Left;
         if t > minWidth then minWidth := t;
         end;
     CMTPanel.Width := minWidth + 10;
     minWidth := minWidth + OleMinWidth;
     end;

(*

function TFFPreview.ExtractWordDoc(FileName: string): string;
var
   FileHandle : Integer;
   c: integer;
   ch: char;
   WordDoc: boolean;
   ActualRead: integer;
   BufPtr: integer;
   Buf: PAnsiChar;
begin
     Buf := StrAlloc(BUFSIZE);
     BufPtr := -1;
     FileHandle := FileOpen(FileName, fmOpenRead);
     if FileHandle <= 0 then begin
        Result := ' - error opening file!';
        exit;
        end;
     ActualRead:=1;
     WordDoc := False;
     while ActualRead = 1 do begin

     repeat
           ActualRead := Fileread(FileHandle, ch, 1);
           c := Ord(ch);
           if ((c<=255) and (c>=32)) or (c in [7, 5, 10, 30]) then begin
              Buf[BufPtr] := ch;
              inc(BufPtr);
            end else
                if (c = 11) then begin
                   inc(BufPtr);
                   Buf[BufPtr] := #10;
                end else begin
                    if (c = 0) then begin
                       inc(BufPtr);
                       Buf[BufPtr] := Chr(0);
                       ShowMessage(Buf);
                       if CompareText(Buf, 'MSWordDoc') = 0 then begin
                          WordDoc := True;
                          end;
                    end;
                    if (c <> 2) then begin
                       BufPtr := -1;
                       end;
                end;

        until (ActualRead <> 1) or (c = 10);

     if (WordDoc) then begin

        if (BufPtr>0) then ShowMessage(Buf);

        end;

     end;

     Result := '(valid)';
     FileClose(FileHandle);
     end;
  *)

procedure TFFPreview.CreateLinkToFile(FileName: string; VirtualDir: string);
          procedure RecreateOleContainer;
          begin
               if Assigned(OleContainer) then begin
                  OleContainer.Close;
                  OleContainer.DestroyObject;
                  OleContainer.Destroy;
                  end;
               OleContainer := TOleContainer.Create(PreviewPanel);
               end;
var
   Handle: THandle;
   FindData: TWin32FindData;
begin
     //PreviewPanel.Caption := FileName;
     //PreviewPanel.Caption := PreviewPanel.Caption + ExtractWordDoc(FileName);
     //exit;

     RecreateOleCOntainer;
     try
     if CompareText(OldFileName, FileName) = 0 then exit;
     Screen.Cursor := crHourGlass;
     Status.SimpleText := 'Loading ' + bs(VirtualDir) + ExtractFileName(FileName) + ', please wait.';
     Handle := FindFirstFile(PChar(FileName), FindData);

     FNName.Caption := ExtractFileName(FileName);
     FNSize.Caption := TFFProp.NiceSize((FindData.nFileSizeHigh * MAXDWORD) + FindData.nFileSizeLow) + ' bytes';
     FNCreated.Caption := TFFProp.GetDateField(FindData.ftCreationTime);
     FNAccess.Caption := TFFProp.GetDateField(FindData.ftLastAccessTime);
     FNWrite.Caption := TFFProp.GetDateField(FindData.ftLastWriteTime);
     FNVirtual.Caption := VirtualDir;

     //Self.Caption := 'File & Folder Preview - ' + GetFileTypeExec(ExtractFileExt(FileName));
     Self.Caption := 'File & Folder Preview - ' + GetFileTypeName(ExtractFileExt(FileName));

     ExtractImageIcon(FileName, FFPImage);
     SetPropWidths;
     with OleContainer do begin
          SizeMode := smScale;
          AutoVerbMenu := False;
          AutoActivate := aaManual;
          end;
     PreviewPanel.InsertControl(OleContainer);
     OleContainer.Width := PreviewPanel.Width * (Spin.Value+1);
     OleContainer.Height := PreviewPanel.Height * (Spin.Value+1);
     OleContainer.Left := 0;
     OleContainer.Top := 0;
     PreviewPanelResize(Self);
     OleContainer.CreateObjectFromFile(FileName, False);
     Windows.FindClose(Handle);
     except
     if Assigned(OleContainer) then begin
        OleContainer.Close;
        OleContainer.DestroyObject;
        OleContainer.Destroy;
        end;
     end;
     Status.SimpleText := 'Ready.';
     Screen.Cursor := crDefault;
     end;

procedure TFFPreview.BBOkClick(Sender: TObject);
begin
     Close;
     end;

procedure TFFPreview.WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo);
begin
   inherited;
   with Msg.MinMaxInfo^ do begin
      if ptMinTrackSize.x< minWidth then ptMinTrackSize.x:= minWidth;
      if ptMinTrackSize.y< minHeight then ptMinTrackSize.y:= minHeight;
      if ptMaxTrackSize.x>Screen.Width then ptMaxTrackSize.x:=Screen.Width;
      if ptMaxTrackSize.y>Screen.Height then ptMaxTrackSize.y:=Screen.Height;
      end;
   end;

procedure TFFPreview.WMwindowposchanging(var M: TWMwindowposchanging);
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


procedure TFFPreview.FormCreate(Sender: TObject);
begin
     minHeight := Height;
     OleMinWidth := 200;
     ReadRegistry;
     end;

procedure TFFPreview.CMTPanelResize(Sender: TObject);
begin
     BBOk.Top := CMTPanel.ClientHeight - BBOk.Height - 6;
     BBOk.Left := 6;
     end;

procedure TFFPreview.ReadRegistry;
var
   t: integer;
begin
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFPreview.Width'); if t > 0 then Self.Width := t;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFPreview.Height'); if t > 0 then Self.Height := t;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFPreview.Left'); if t >= 0 then Self.Left := t else Self.Left := (Screen.Width - Self.Width) div 2;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFPreview.Top'); if t >= 0 then Self.Top := t else Self.Top := (Screen.Height - Self.Height) div 2;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFPreview.Zoom'); if t >= 1 then Spin.Value := t;
     end;

procedure TFFPreview.WriteRegistry;
begin
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFPreview.Width', Self.Width);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFPreview.Height', Self.Height);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFPreview.Left', Self.Left);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFPreview.Top', Self.Top);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFPreview.Zoom', Spin.Value);
     end;


procedure TFFPreview.PreviewPanelResize(Sender: TObject);
begin
     try
     if not Visible then exit;
     with Vertical do begin
          Left := PreviewPanel.ClientWidth - Width;
          Top := 0;
          Height := PreviewPanel.ClientHeight - Horizontal.Height;
          end;
     with Horizontal do begin
          Top := PreviewPanel.ClientHeight - Height;
          Left := 0;
          Width := PreviewPanel.ClientWidth;
          end;
     if Assigned(OleContainer) then with OleContainer do begin
        if Width < PreviewPanel.ClientWidth then Width := PreviewPanel.ClientWidth;
        if Height < PreviewPanel.ClientHeight then Height := PreviewPanel.ClientHeight;
        VsHsScroll;
        end;
     Horizontal.BringToFront;
     Vertical.BringToFront;
     Update;
     except
     end;
     end;

procedure TFFPreview.VerticalScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
     OleContainer.Top := round((PreviewPanel.ClientHeight - OleContainer.Height) * (ScrollPos/100));
     end;

procedure TFFPreview.HorizontalScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
     OleContainer.Left := round((PreviewPanel.ClientWidth - OleContainer.Width) * (ScrollPos/100));
     end;

procedure TFFPreview.SpinChange(Sender: TObject);
begin
     try
     if Visible then begin
         VsHsScroll;
         OleContainer.Left := 0;
         OleContainer.Top := 0;
         OleContainer.Width := PreviewPanel.Width * (Spin.Value+1);
         OleContainer.Height := PreviewPanel.Height * (Spin.Value+1);
         PreviewPanelResize(Sender);
         end;
     except
     end;
     end;

procedure TFFPreview.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
     WriteRegistry;
     if Assigned(OleContainer) then begin
        OleContainer.Close;
        OleContainer.DestroyObject;
        OleContainer.Destroy;
        OleContainer := nil;
        end;
     end;

procedure TFFPreview.SpinEnter(Sender: TObject);
begin
     Vertical.SetFocus;
     end;

procedure TFFPreview.cmdCenterClick(Sender: TObject);
begin
     Horizontal.Position := 50;
     VsHsScroll;
     end;

procedure TFFPreview.EastMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
     if Sender <> NStimer then begin
        NSTimer.Enabled := True;
        NSTimer.Interval := 300;
        NSTimer.Tag := 1;
        end;
     if not (ssCtrl in Shift) then
        Horizontal.Position := Horizontal.Position + Horizontal.SmallChange
        else Horizontal.Position := 100;
     VsHsScroll;
     end;

procedure TFFPreview.NorthMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
     if Sender <> NStimer then begin
        NSTimer.Enabled := True;
        NSTimer.Interval := 300;
        NStimer.Tag := 0;
        end;
     if not (ssCtrl in Shift) then
        Vertical.Position := Vertical.Position - Vertical.SmallChange
        else Vertical.Position := 0;
     VsHsScroll;
     end;

procedure TFFPreview.WestMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
     if Sender <> NStimer then begin
        NSTimer.Enabled := True;
        NSTimer.Interval := 300;
        NStimer.Tag := 3;
        end;
     if not (ssCtrl in Shift) then
        Horizontal.Position := Horizontal.Position - Horizontal.SmallChange
        else Horizontal.Position := 0;
     VsHsScroll;
     end;

procedure TFFPreview.SouthMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
     if Sender <> NStimer then begin
        NSTimer.Enabled := True;
        NSTimer.Interval := 300;
        NSTimer.Tag := 2;
        end;
     if not (ssCtrl in Shift) then
        Vertical.Position := Vertical.Position + Vertical.SmallChange
        else Vertical.Position := 100;
     VsHsScroll;
     end;

procedure TFFPreview.NorthMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
     NSTimer.Enabled := False;
     end;

procedure TFFPreview.NSTimerTimer(Sender: TObject);
begin
     case NStimer.Tag of
        0:    begin
              NorthMouseDown(NSTimer, mbLeft, [], 0, 0);
              end;
        1:    begin
              EastMouseDown(NSTimer, mbLeft, [], 0, 0);
              end;
        2:    begin
              SouthMouseDown(NSTimer, mbLeft, [], 0, 0);
              end;
        3:    begin
              WestMouseDown(NSTimer, mbLeft, [], 0, 0);
              end;
        end;
     NSTimer.Interval := 20;
     end;

procedure TFFPreview.VSHSScroll;
var
   vs, hs: integer;
begin
    vs := Vertical.Position;
     hs := Horizontal.Position;
     VerticalScroll(Self, scEndScroll, vs);
     HorizontalScroll(Self, scEndScroll, hs);
     end;

procedure TFFPreview.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
   CurKey: Word;
begin
     CurKey := Key;
     Key := 0;
     case CurKey of
        38: NorthMouseDown(Sender, mbLeft, [], 0, 0);
        39: EastMouseDown(Sender, mbLeft, [], 0, 0);
        40: SouthMouseDown(Sender, mbLeft, [], 0, 0);
        37: WestMouseDown(Sender, mbLeft, [], 0, 0);
        else Key := CurKey;
        end;
     end;

procedure TFFPreview.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
     if Key in [37, 38,39,40] then NSTimer.Enabled := False;
     end;

end.
