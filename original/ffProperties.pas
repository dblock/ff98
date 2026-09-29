unit ffProperties;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, OleCtnrs, d32gen, d32reg;

type

  PSizeThread = ^TSizeThread;
  TSizeThread = class(TThread)
       public
          constructor Create(Root: string; TargetLabel, TargetLabelExt: TLabel; var CurrentThread: TSizeThread);
          procedure Kill;
       private
          FCDirs: LongInt;
          FCFiles: LongInt;
          FCSize: LongInt;
          FKilled: boolean;
          FRoot : string;
          FLabel: TLabel;
          FLabelExt: TLabel;
          FSizeThread : PSizeThread;
          procedure Execute; override;
          procedure UpdateLabel;
       end;
  
  TFFProp = class(TForm)
    CMPanel: TPanel;
    CMTPanel: TPanel;
    FFPropClose: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    FNName: TLabel;
    FNSize: TLabel;
    FNCreated: TLabel;
    FNAccess: TLabel;
    FNWrite: TLabel;
    Label6: TLabel;
    FNPhysical: TLabel;
    FFPImage: TImage;
    Label7: TLabel;
    FNType: TLabel;
    Label8: TLabel;
    FNExecutor: TLabel;
    Label9: TLabel;
    FNLocation: TLabel;
    FTReadOnly: TCheckBox;
    FTArchive: TCheckBox;
    FTHidden: TCheckBox;
    FTsystem: TCheckBox;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    FNSizeExt: TLabel;
    FFLogo: TSpeedButton;
    procedure FFPropCloseClick(Sender: TObject);
    procedure CMPanelResize(Sender: TObject);
    procedure FTReadOnlyClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
  private
    IgnoreCheck: boolean;
    SizeThread : TSizeThread;
    FRoot: string;
    minWidth, fixedHeight: integer;
    procedure WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo); message WM_GetMinMaxInfo;
    procedure WMwindowposchanging(var M: TWMwindowposchanging); message wm_windowposchanging;
    procedure ShowFileAttributes;
    procedure SetPropWidths;
    procedure KillSizeThread;
    procedure ReadRegistry;
    procedure WriteRegistry;
  public
    class function GetDateField(Field: TFileTime): string;
    class function NiceSize(Size: LongInt): string;
    procedure ShowProps(Root, VirtualFolder: string);
    procedure ShowPropsVolume(Root, VirtualFolder: string);
  end;

var
  FFProp: TFFProp;

implementation

uses d32errors, ffCommon, FFMessage;

{$R *.DFM}

procedure TFFProp.KillSizeThread;
begin
     if Assigned(SizeThread) then SizeThread.Kill;
     while Assigned(SizeThread) do Application.ProcessMessages;
     end;

procedure TFFProp.ShowFileAttributes;
var
   t: integer;
begin
     IgnoreCheck := True;
     if Length(FRoot) > 0
        then t := FileGetAttr(FRoot)
        else t:=FileGetAttr(FRoot);
     if t <> -1 then begin
        FTReadOnly.Checked := (t and faReadOnly) > 0;
        FTArchive.Checked := (t and faArchive) > 0;
        FTHidden.Checked := (t and faHidden) > 0;
        FTSystem.Checked := (t and faSysFile) > 0;
        end;
     IgnoreCheck := False;
     end;

class function TFFProp.GetDateField(Field: TFileTime): string;
var
  LocalFileTime: TFileTime;
  RInt: integer;
begin
     try
     FileTimeToLocalFileTime(Field, LocalFileTime);
     if FileTimeToDosDateTime(LocalFileTime, LongRec(RInt).Hi, LongRec(RInt).Lo) then
        DateTimeToString(Result, 'dddd, d mmmm, yyyy (tt)', FileDateToDateTime(RInt))
        else Result := '';
     except
     Result := '(unavailable)';
     end;
     end;

procedure TFFProp.ShowPropsVolume(Root, VirtualFolder: string);
var
   Handle:THandle;
   FindData: TWin32FindData;
begin
     Handle := 0;
     try
     KillSizeThread;
     Caption := 'Properties - Virtual Folder';

     FNName.Caption := ExtractFileName(Root);
     Handle := FindFirstFile(PChar(Root), FindData);

     FNSize.Caption := 'Calculating ...';
     FNCreated.Caption := GetDateField(FindData.ftCreationTime);
     FNAccess.Caption := GetDateField(FindData.ftLastAccessTime);
     FNWrite.Caption := GetDateField(FindData.ftLastWriteTime);
     FNPhysical.Caption := Root;
     FNType.Caption := 'Virtual Folder';
     FNExecutor.Caption := WindowsDir + 'Explorer.exe';
     FNLocation.Caption := VirtualFolder;
     ExtractImageIcon(Root, FFPImage);

     if Length(Root) > 0 then SizeThread := TSizeThread.Create(Root, FNSize, FNSizeExt, SizeThread);
     ShowFileAttributes;
     SetPropWidths;
     finally
     Windows.FindClose(Handle);
     end;
     end;

procedure TFFProp.SetPropWidths;
var
   i, t: integer;
begin
     minWidth := 300;
     for i:=0 to CMTPanel.ControlCount - 1 do
       if (CMTPanel.Controls[i] is TLabel) then begin
         t:= CMTPanel.Controls[i].Width + CMTPanel.Controls[i].Left;
         if t > minWidth then minWidth := t;
         end;
     minWidth := minWidth + Width - ClientWidth + CMTPanel.Width - CMTPanel.ClientWidth + 5;
     Width := minWidth;
     end;

procedure TFFProp.ShowProps(Root, VirtualFolder: string);
var
   Handle: THandle;
   FindData: TWin32FindData;
begin
     Handle := 0;
     try
     KillSizeThread;
     FRoot := Root;
     Caption := 'Properties - ' + Root;
     FNName.Caption := ExtractFileName(Root);

     Handle := FindFirstFile(PChar(Root), FindData);

     FNSize.Caption := TFFProp.NiceSize((FindData.nFileSizeHigh * MAXDWORD) + FindData.nFileSizeLow);
     FNSizeExt.Caption := '';
     FNType.Caption := QueryReg(HKEY_CLASSES_ROOT, ExtractFileExt(Root), '');
     if FNType.Caption <> '-1' then FNType.Caption := QueryReg(HKEY_CLASSES_ROOT, FNType.Caption, '');
     if FNType.Caption = '-1' then FNType.Caption := ExtractFileExt(Root) + ' file';
     FNCreated.Caption := GetDateField(FindData.ftCreationTime);
     FNAccess.Caption := GetDateField(FindData.ftLastAccessTime);
     FNWrite.Caption := GetDateField(FindData.ftLastWriteTime);
     FNPhysical.Caption := Root;
     FNExecutor.Caption := GetFileTypeExec(ExtractFileExt(Root));
     FNLocation.Caption := VirtualFolder;
     ExtractImageIcon(Root, FFPImage);

     ShowFileAttributes;
     SetPropWidths;
     finally
     Windows.FindClose(Handle);
     end;
     end;

procedure TFFProp.WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo);
begin
   inherited;
   with Msg.MinMaxInfo^ do begin
      if ptMinTrackSize.x< minWidth then ptMinTrackSize.x:= minWidth;
      if ptMinTrackSize.y <> fixedHeight then ptMinTrackSize.y:= fixedHeight;
      if ptMaxTrackSize.x>Screen.Width then ptMaxTrackSize.x:=Screen.Width;
     end;
   end;

procedure TFFProp.WMwindowposchanging(var M: TWMwindowposchanging);
begin
   inherited;
   with M.WindowPos^ do begin
      if cx<= minWidth then cx:= minWidth;
      if cy<= fixedHeight then cy:= fixedHeight;
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



procedure TFFProp.FFPropCloseClick(Sender: TObject);
begin
     if Assigned(SizeThread) then SizeThread.Kill;
     Close;
     end;

procedure TFFProp.CMPanelResize(Sender: TObject);
begin
     FFPropClose.Left := CMPanel.ClientWidth - FFPropClose.Width - 2;
     FFPropClose.Top := (CMPanel.Height - FFPropClose.Height) div 2;
     end;


procedure TFFProp.FTReadOnlyClick(Sender: TObject);
var
   FAttr: integer;
begin
     if not IgnoreCheck then begin
        FAttr := 0;
        if FTReadOnly.Checked then FAttr := FAttr or faReadOnly;
        if FTArchive.Checked then FAttr := FAttr or faArchive;
        if FTHidden.Checked then FAttr := FAttr or faHidden;
        if FTSystem.Checked then FAttr := FAttr or faSysFile;

        if Length(FRoot) > 0 then
        if FileSetAttr(FRoot, FAttr) <> 0 then begin
           FFMessageBox.MessageDlg('Error setting file attribute for ' + FRoot + ' - ' + ErrorRaise(GetLastError), mtError, [mbOk], 0);
           ShowFileAttributes;
           end;

        end; //IgnoreCheck
     end;

constructor TSizeThread.Create(Root: string; TargetLabel, TargetLabelExt: TLabel; var CurrentThread: TSizeThread);
begin
        FRoot := Root;
        FLabel := TargetLabel;
        FLabelExt := TargetLabelExt;
        FSizeThread := @CurrentThread;
        FKilled := False;
        FCSize := 0;
        FCDirs := 0;
        FCFiles := 0;
        inherited Create(false);
     end;


procedure TSizeThread.Execute;
          function DirSize(Directory: string): LongInt;
          var
             SearchResult: integer;
             SearchRec: TSearchRec;
          begin
             Result := 0;
             SearchResult := FindFirst(bs(Directory)+'*.*', faHidden+faDirectory+faAnyFile, SearchRec);
             while (SearchResult = 0) and (not FKilled) do begin
                   if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then begin
                      if (SearchRec.Attr and faDirectory) > 0 then begin
                         DirSize(bs(Directory) + SearchRec.Name);
                         inc(FCDirs);
                         Synchronize(UpdateLabel);
                         end else begin
                         FCSize := FCsize + SearchRec.Size;
                         inc(FCFiles);
                         end;
                      end;
                   SearchResult := FindNext(SearchRec);
                   end;
             try SysUtils.FindClose(SearchRec); except end;
             end;
begin
     try
     DirSize(FRoot);
     if not FKilled then Synchronize(UpdateLabel);
     finally
     if Assigned(FSizeThread) then FSizeThread^ := nil;
     end;
     end;

procedure TSizeThread.Kill;
begin
     FKilled := True;
     end;

procedure TFFProp.FormCreate(Sender: TObject);
begin
     fixedHeight := Height;
     IgnoreCheck := True;
     SizeThread := nil;
     ReadRegistry;
     end;

procedure TSizeThread.UpdateLabel;
begin
     FLabel.Caption := TFFProp.NiceSize(FCSize) + ' ';
     if Assigned(FLabelExt) then FLabelExt.Caption := 'in ' + IntToStr(FCFiles) + ' file(s) and ' + IntToStr(FCDirs) + ' subdir(s).';
     if FFProp.Visible then FFProp.SetPropWidths;
     //if FFPreview.Visible then FFPreview.SetPropWidths;
     end;

class function TFFProp.NiceSize(Size: LongInt): string;
begin
     if Size < 1024 then Result := IntToStr(Size) + ' bytes'
     else begin
          if Size < 1024000 then Result := IntToStr(Size div 1024) + '.' + IntToStr(trunc(((Size mod 1024)/1024)*100)) + ' Kbytes'
          else if Size < 1024000000 then Result := IntToStr(Size div 1024000) + '.' + IntToStr(trunc(((Size mod 1024000)/1024000)*100)) + ' Mbytes'
          else Result := IntToStr(Size div 1024000000) + '.' + IntToStr(trunc(((Size mod 1024000000)/1024000000)*100)) + ' Gbytes';
          Result := Result + ' (' + IntToStr(Size) + ' bytes)'
          end;
     end;

procedure TFFProp.ReadRegistry;
var
   t: integer;
begin
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFProp.Width'); if t > 0 then Self.Width := t;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFProp.Height'); if t > 0 then Self.Height := t;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFProp.Left'); if t >= 0 then Self.Left := t else Self.Left := (Screen.Width - Self.Width) div 2;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFProp.Top'); if t >= 0 then Self.Top := t else Self.Top := (Screen.Height - Self.Height) div 2;
     end;

procedure TFFProp.WriteRegistry;
begin
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFProp.Width', Self.Width);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFProp.Height', Self.Height);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFProp.Left', Self.Left);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFProp.Top', Self.Top);
     end;


procedure TFFProp.FormClose(Sender: TObject; var Action: TCloseAction);
begin
     WriteRegistry;
     end;

procedure TFFProp.FormDestroy(Sender: TObject);
begin
     WriteRegistry;
     end;


end.
