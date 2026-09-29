unit ff98;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, FFDirListBox, Buttons, FileCtrl, ComCtrls, ToolWin,
  ExtCtrls, Menus, VVManager, ffButton, d32gen, d32errors, ShellApi, OleAuto,
  CoolMenu, ExtManager, FFMessage;

type
  TFFMain = class(TForm)
    BBImages: TImageList;
    cmdPanel: TPanel;
    ffcmdToolBar: TToolBar;
    cmdSetup: TToolButton;
    cmdHelp: TToolButton;
    cmdAbout: TToolButton;
    cmdQuit: TToolButton;
    folderPanel: TToolBar;
    cmdDocuments: TToolBar;
    BDImages: TImageList;
    docNew: TToolButton;
    docOpen: TToolButton;
    docOpenAs: TToolButton;
    docPrint: TToolButton;
    docRename: TToolButton;
    docRemove: TToolButton;
    docCopyTo: TToolButton;
    docMoveto: TToolButton;
    docRecent: TToolButton;
    docProperties: TToolButton;
    docPreview: TToolButton;
    RightPanel: TPanel;
    FFShell: TFFDirListBox;
    MainMenu: TMainMenu;
    ffMenu: TMenuItem;
    ptPanel: TPanel;
    mnuSetup: TMenuItem;
    N1: TMenuItem;
    mnuQuit: TMenuItem;
    mnuHelpAbout: TMenuItem;
    mnuHelp: TMenuItem;
    N2: TMenuItem;
    mnuAbout: TMenuItem;
    DNamePanel: TPanel;
    FFSWWord: TSpeedButton;
    VolumesList: TComboBox;
    StatusBar: TStatusBar;
    cmdNewFolder: TToolButton;
    cmdRenameFolder: TToolButton;
    mnuFolders: TMenuItem;
    mnuFolderCreate: TMenuItem;
    mnuFolderRename: TMenuItem;
    mnuFolderProperties: TMenuItem;
    mnuDocuments: TMenuItem;
    mnuDocNew: TMenuItem;
    mnuDocOpen: TMenuItem;
    mnuDocOpenAs: TMenuItem;
    mnuDocPrint: TMenuItem;
    mnuDocRename: TMenuItem;
    mnuDocDelete: TMenuItem;
    N3: TMenuItem;
    mnuDocCopyTo: TMenuItem;
    mnuDocMoveTo: TMenuItem;
    N4: TMenuItem;
    mnuDocPreview: TMenuItem;
    RecentMenu: TPopupMenu;
    DocPopMenu: TPopupMenu;
    popNewDoc: TMenuItem;
    popOpenDoc: TMenuItem;
    popOpenAs: TMenuItem;
    popPrintDoc: TMenuItem;
    popRenameDoc: TMenuItem;
    popDelDoc: TMenuItem;
    N5: TMenuItem;
    popCopyTo: TMenuItem;
    popDocMove: TMenuItem;
    N6: TMenuItem;
    popDocProps: TMenuItem;
    popDocPreview: TMenuItem;
    FolderPopupMenu: TPopupMenu;
    popFolCreateNew: TMenuItem;
    popFolRename: TMenuItem;
    N7: TMenuItem;
    popFolProperties: TMenuItem;
    popFolDocNew: TMenuItem;
    cmdFolProps: TToolButton;
    mnuDocProps: TMenuItem;
    mnuSwitch: TMenuItem;
    cmdKillFolder: TToolButton;
    mnuFolderKill: TMenuItem;
    GMTimer: TTimer;
    txtPreview: TToolButton;
    mnuTxtPreview: TMenuItem;
    popTxtPreview: TMenuItem;
    procedure ptPanelResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cmdQuitClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure cmdPanelResize(Sender: TObject);
    procedure DNamePanelResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cmdSetupClick(Sender: TObject);
    procedure VolumesListChange(Sender: TObject);
    procedure FFShellChange(Sender: TObject);
    procedure cmdAboutClick(Sender: TObject);
    procedure docOpenAsClick(Sender: TObject);
    procedure FFShellDblClick(Sender: TObject);
    procedure docOpenClick(Sender: TObject);
    procedure docNewClick(Sender: TObject);
    procedure docPrintClick(Sender: TObject);
    procedure docRenameClick(Sender: TObject);
    procedure docRemoveClick(Sender: TObject);
    procedure FFSWWordClick(Sender: TObject);
    procedure cmdNewFolderClick(Sender: TObject);
    procedure cmdRenameFolderClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FFShellKeyPress(Sender: TObject; var Key: Char);
    procedure docCopyToClick(Sender: TObject);
    procedure docMovetoClick(Sender: TObject);
    procedure docRecentClick(Sender: TObject);
    procedure DocPopMenuPopup(Sender: TObject);
    procedure FFShellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FolderPopupMenuPopup(Sender: TObject);
    procedure cmdFolPropsClick(Sender: TObject);
    procedure docPropertiesClick(Sender: TObject);
    procedure docPreviewClick(Sender: TObject);
    procedure cmdHelpClick(Sender: TObject);
    procedure FFShellKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cmdKillFolderClick(Sender: TObject);
    procedure StatusBarResize(Sender: TObject);
    procedure GMTimerTimer(Sender: TObject);
    procedure VolumesListKeyPress(Sender: TObject; var Key: Char);
    procedure txtPreviewClick(Sender: TObject);
  private
     TillExpired: integer;
     Expired: boolean;
     SemiBool: boolean;
     minWidth, minHeight: integer;
     procedure KillFolder;
     procedure WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo); message WM_GetMinMaxInfo;
     procedure WMwindowposchanging(var M: TWMwindowposchanging); message wm_windowposchanging;
     procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SysCommand;
     procedure ShowInitForm;
     function fileCopyFile(Source, Target: string; Move: boolean): boolean;
     procedure FileExecute(Op: string; FileName: string);
     function GetOLEObject(ClassName: string): Variant;
     procedure Selectdocument(CName: string);
     procedure UpdateMenus;
     procedure ReadRegistry;
     procedure WriteRegistry;
  public
     VManager: TVVManager;
     BManager: TFFbuttonManager;
     EManager: TExtManager;
     procedure docOpenCopyAs(Document: string);
     function AppendExt(Name, Ext: string): string;
     function RemoveExt(Name, Ext: string): string;
  end;

const
   FFversionId: string = '100160798';
   ShareWareMax : integer = 30*12;

var
  FFMain: TFFMain;

implementation

{$R *.DFM}

uses FFRoot, FFSetup, ffInit, FFSelect, d32reg, FFCommon, ffProperties,
  ffOlePreview, ffDocPreview;

procedure TFFMain.ptPanelResize(Sender: TObject);
begin
     {with PathFinder do begin
          Left := 0;
          Top := 0;
          Width := ptPanel.ClientWidth;
          ptPanel.ClientHeight := Height;
          end;}
     end;

procedure TFfMain.WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo);
begin
   inherited;
   with Msg.MinMaxInfo^ do begin
      if ptMinTrackSize.x< minWidth then ptMinTrackSize.x:= minWidth;
      if ptMinTrackSize.y< minHeight then ptMinTrackSize.y:= minHeight;
      if ptMaxTrackSize.x>Screen.Width then ptMaxTrackSize.x:=Screen.Width;
      if ptMaxTrackSize.y>Screen.Height then ptMaxTrackSize.y:=Screen.Height;
      end;
   end;

procedure TFFMain.WMSysCommand(var Msg: TWMSysCommand);
begin
   if Msg.CmdType=SC_CLOSE then exit;
   if Msg.CmdType=SC_MINIMIZE then begin
      Application.Minimize;
      end else inherited;
   end;

procedure TFfMain.WMwindowposchanging(var M: TWMwindowposchanging);
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

procedure TFFMain.ShowInitForm;
begin
     InitForm := TInitForm.Create(Application);
     InitForm.Show;
     InitForm.Update;
     end;

procedure TFFMain.FormCreate(Sender: TObject);
   procedure AddRevisionDate;
   var
      FirstRunDate: LongInt;
      Year, Mon, Day: Word;
   begin
        try
        DecodeDate(Now, Year, Mon, Day);
        FirstRunDate:=Day + Mon * 100 + Year * 10000;
        AddReg(HKEY_CURRENT_USER,   '\Console\Revision Data\_vxdr',
                                       FFVersionID,
                                       FirstRunDate);
        except
        end;
        end;
   function ElapsedDays(First, Second: TDateTime): LongInt;
   var
      aYear, aMon, aDay,
      bYear, bMon, bDay: word;
      internal1, internal2: LongInt;
      jnum: real;
      cd: integer;
      sOut: string;

      function Jul( mo, da, yr: integer): real;
      var
         i, j, k, j2, ju: real;
      begin
           i := yr;     j := mo;     k := da;
           j2 := int( (j - 14)/12 );
           ju := k - 32075 + int(1461 * ( i + 4800 + j2 ) / 4 );
           ju := ju + int( 367 * (j - 2 - j2 * 12) / 12);
           ju := ju - int(3 * int( (i + 4900 + j2) / 100) / 4);
           Jul := ju;
           end;
      begin
        try
        DecodeDate(First, aYear, aMon, aDay);
        DecodeDate(Second, bYear, bMon, bDay);
        jnum:=jul(aMon,aDay,aYear);
        str(jnum:10:0,sOut);
        val(sOut,internal1,cd);
        jnum:=jul(bMon,bDay,bYear);
        str(jnum:10:0,sOut);
        val(sOut,internal2,cd);
        Result:=internal1-internal2;
        except
        AddRevisionDate;
        Result:=0;
        end;
        end;
   procedure ExpirationManager;
   var
      FirstRunDate: LongInt;
      aDate: TDateTime;
      Year, Mon, Day: Word;
   begin
        Expired:=False;
        try FirstRunDate:=QueryReg(HKEY_CURRENT_USER,
                    '\Console\Revision Data\_vxdr',
                    FFVersionId); except FirstRunDate:=0; end;
        if FirstRunDate = -3 then begin
           FFMessageBox.Messagedlg('This beta release of FF has Expired!', mtInformation, [mbOk], 0);
           Application.Terminate;
           end else
        if FirstRunDate > 0 then begin
           try
           Year:=FirstRunDate div 10000;
           Mon:=FirstRunDate div 100 - Year * 100;
           Day:=FirstRunDate - Year * 10000 - Mon * 100;
           aDate:=EncodeDate(Year, Mon, Day);
           tillExpired:=ElapsedDays(Now, aDate);
           //ShowMessage(IntToStr(15 - eDays) + ' left till expiration.');
           if tillExpired > ShareWareMax then begin
              AddReg(HKEY_CURRENT_USER,   '\Console\Revision Data\_vxdr',
                                          FFVersionID,
                                          -3);
              FFMessageBox.Messagedlg('This release of FF has Expired!', mtInformation, [mbOk], 0);
              Application.Terminate;
              end;
           except
           AddRevisionDate;
           end;
           end else begin
           AddRevisionDate;
           end;

        end;
var
   ColCountReg : integer;
begin
     Application.HelpFile := bs(ExtractFileDir(Application.ExeName)) + 'folder.hlp';
     ShowInitForm;
     ExpirationManager;
     minWidth := Width;
     minHeight := Height;
     InitForm.Stat('Initializing Extensions ...', 10);
     EManager := TExtManager.Create;
     FFShell.ExtManager := EManager;
     InitForm.Stat('Initializing VFM ...', 20);
     VManager := TVVManager.Create;
     InitForm.Stat('Initializing Buttons ...', 50);
     BManager := TFFButtonManager.Create;
     with BManager do begin
          AddButtonSync(cmdSetup, 'Setup', 'General');
          AddButtonSync(cmdAbout, 'About', 'General');
          AddButtonSync(cmdQuit, 'Quit', 'General');
          AddButtonSync(cmdHelp, 'Help', 'General');
          AddButtonSync(FFSWWord, 'Microsoft Word', 'General');

          AddButton(docNew, 'New Document', 'Documents');
          AddButton(docOpen, 'Open Document', 'Documents');
          AddButton(docOpenAs, 'Open As', 'Documents');
          AddButton(docPrint, 'Print Document', 'Documents');
          AddButton(docRename, 'Rename Document', 'Documents');
          AddButton(docRemove, 'Remove Document', 'Documents');
          AddButton(docCopyTo, 'Copy To', 'Documents');
          AddButton(docMoveTo, 'Move To', 'Documents');
          AddButton(docRecent, 'Recent Documents', 'Documents');
          AddButton(docProperties, 'Document Properties', 'Documents');
          Addbutton(docPreview, 'Document Preview', 'Documents');
          Addbutton(txtPreview, 'Doc Text Preview', 'Documents');

          AddButton(cmdNewFolder, 'Create New Folder', 'Folders');
          Addbutton(cmdRenameFolder, 'Rename Current Folder', 'Folders');
          AddButton(cmdKillFolder, 'Kill Current Folder', 'Folders');
          Addbutton(cmdFolProps, 'Folder Properties', 'Folders');

          ReadRegistry;
          end;

     ColCountReg := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'Shell.ColumnCount');
     if (ColCountReg > 0) then FFShell.Columns := ColCountReg;
     InitForm.Stat('Ready.', 100);
     end;

procedure TFFMain.cmdQuitClick(Sender: TObject);
begin
     WriteRegistry;
     if FFProp.Visible then FFProp.Close;
     if FFPreview.Visible then FFPreview.Close;
     VManager.WriteRegistry;
     BManager.WriteRegistry;
     EManager.WriteRegistry;
     Application.Terminate;
     end;

procedure TFFMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
     cmdQuitClick(Sender);
     end;

procedure TFFMain.cmdPanelResize(Sender: TObject);
begin
     folderPanel.Top := ffCmdToolBar.Height + (cmdPanel.ClientHeight - (ffCmdToolBar.Height + cmdDocuments.Height + folderPanel.Height)) div 2;
     end;

procedure TFFMain.DNamePanelResize(Sender: TObject);
begin
     VolumesList.Width := DNAmePanel.ClientWidth - VolumesList.Left - 4;
     end;

procedure TFFMain.FormShow(Sender: TObject);
begin
     VManager.PopulateCombo(VolumesList);
     if VManager.Count = 0 then begin
        FFMessageBox.Messagedlg('Welcome to File && Folder! You should now define virtual volumes, I shall open the setup windows for you!', mtInformation, [mbOk], 0);
        cmdSetupClick(Sender);
        end else begin
        ReadRegistry;
        end;
     if Assigned(FFShell.OnChange) then FFShell.OnChange(Self);
     SemiBool := False;
     GMTimerTimer(Sender);
     end;

procedure TFFMain.cmdSetupClick(Sender: TObject);
begin
     FFSet.ShowModal;
     if Assigned(FFShell.OnChange) then FFShell.OnChange(Self);
     end;

procedure TFFMain.VolumesListChange(Sender: TObject);
begin
     if (VolumesList.Items.Count > 0) then begin
        FFShell.SetRoot(TFFRoot(VolumesList.Items.Objects[VolumesList.ItemIndex]));
        DNamePanel.Caption := VolumesList.Items[VolumesList.ItemIndex];
        ptPanel.Caption := '';
        end else begin
        FFShell.Items.Clear;
        DNamePanel.Caption := '';
        end;
     end;

procedure TFFMain.UpdateMenus;
begin
     mnuSetup.Enabled := cmdSetup.Enabled;
     mnuAbout.Enabled := cmdAbout.Enabled;
     mnuQuit.Enabled := cmdQuit.Enabled;
     mnuHelp.Enabled := cmdHelp.Enabled;
     mnuDocNew.Enabled := docNew.Enabled;
     mnuDocOpen.Enabled := docOpen.Enabled;
     mnuDocOpenAs.Enabled := docOpenAs.Enabled;
     mnuDocPrint.Enabled := docPrint.Enabled;
     mnuDocRename.Enabled := docRename.Enabled;
     mnuDocDelete.Enabled := docRemove.EnableD;
     mnuDocCopyTo.Enabled := docCopyTo.Enabled;
     mnuDocMoveTo.Enabled := docMoveTo.Enabled;
     mnuDocPreview.Enabled := docPreview.Enabled;
     mnuTxtPreview.Enabled := txtPreview.Enabled;
     mnuDocProps.Enabled := docProperties.Enabled;

     mnuFolderCreate.Enabled := cmdNewFolder.Enabled;
     mnuFolderRename.Enabled := cmdRenameFolder.Enabled;
     mnuFolderKill.Enabled := cmdKillFolder.Enabled;
     mnuFolderProperties.Enabled := cmdFolProps.Enabled;


     end;

procedure TFFMain.FFShellChange(Sender: TObject);
var
   CurrentStyle: TItemStyle;
begin
     StatusBar.Panels[0].Text := FFShell.Root.Name + FFShell.VPath;
     BManager.Updatebuttons;

     docRecent.Enabled := (FFShell.Root.Recent.Count > 0) and BManager.isEnabled(docRecent);

     if FFShell.ItemIndex >= 0 then begin
        CurrentStyle := FFShell.ItemStyle(FFSHell.ItemIndex);
        docNew.Enabled := (FFShell.FoldersCount = 0) and BManager.isEnabled(docNew);
        docOpenAs.Enabled := (CurrentStyle = worddoc) and BManager.isEnabled(docOpenAs);
        docOpen.Enabled := (CurrentStyle = worddoc) and BManager.isEnabled(docOpen);
        docPrint.Enabled := (CurrentStyle = worddoc) and BManager.isEnabled(docPrint);
        docRename.Enabled := (CurrentStyle = worddoc) and BManager.isEnabled(docRename);
        docRemove.Enabled := (CurrentStyle = worddoc) and BManager.isEnabled(docRemove);
        docCopyTo.Enabled := (CurrentStyle = wordDoc) and BManager.isEnabled(docCopyTo);
        docMoveTo.Enabled := (CurrentStyle = wordDoc) and BManager.isEnabled(docCopyTo);
        docProperties.Enabled := (CurrentStyle = wordDoc) and BManager.isEnabled(docProperties);
        docPreview.Enabled := (CurrentStyle = wordDoc) and BManager.isEnabled(docPreview);
        txtPreview.Enabled := (CurrentStyle = wordDoc) and BManager.isEnabled(txtPreview);

        cmdNewFolder.Enabled := (CurrentStyle in [folder, volume]) and (FFShell.DocumentsCount = 0) and BManager.isEnabled(cmdNewFolder);
        cmdRenameFolder.Enabled := (CurrentStyle in [folder]) and BManager.isEnabled(cmdRenameFolder);
        cmdKillFolder.Enabled := (CurrentStyle in [folder]) and BManager.isEnabled(cmdKillFolder);
        cmdFolProps.Enabled := (CurrentStyle in [folder,volume]) and BManager.isEnabled(cmdFolProps);

        end else begin
        docOpenAs.Enabled := False;
        docOpen.Enabled := False;
        docNew.Enabled := False;
        docPrint.Enabled := False;
        docRename.Enabled := False;
        docRemove.Enabled := False;
        docCopyTo.Enabled := False;
        docMoveTo.Enabled := False;
        docProperties.Enabled := False;
        docPreview.Enabled := False;
        txtPreview.Enabled := False;

        cmdRenameFolder.Enabled := False;
        cmdKillFolder.Enabled := False;
        cmdNewFolder.Enabled := False;
        cmdFolProps.Enabled := False;
        end;
     UpdateMenus;

     if cmdFolProps.Enabled and FFProp.Visible then FFProp.ShowPropsVolume(FFShell.GetItemPath(FFShell.ItemIndex), FFShell.Root.Name + FFShell.VPath);
     if docProperties.Enabled and FFProp.Visible then FFProp.ShowProps(bs(FFShell.GetPath)+AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), FFShell.Root.Name + FFShell.VPath);
     if docPreview.Enabled and FFPreview.Visible then FFPreview.CreateLinkToFile(bs(FFShell.GetPath)+AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), FFShell.Root.Name + FFShell.VPath);
     if txtPreview.Enabled and FFTxtPreview.Visible then FFTxtPreview.ShowDocument(FFShell.GetItemPath(FFShell.ItemIndex), FFShell.Root.Name + FFShell.VPath);

     //if docProperties.Enabled and FFProp.Visible then FFProp.ShowProps(bs(FFShell.GetItemPath(FFShell.ItemIndex))+AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), FFShell.Root.Name + FFShell.VPath);
     //if docPreview.Enabled and FFPreview.Visible then FFPreview.CreateLinkToFile(bs(FFShell.GetPath)+AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), FFShell.Root.Name + FFShell.VPath);
     end;

procedure TFFMain.cmdAboutClick(Sender: TObject);
begin
     InitForm.ShowAbout;
     end;

function TFFMain.fileCopyFile(Source, Target: string; Move: boolean): boolean;
begin
     if Source = Target then Result := True
     else begin
          if FileExists(Target) then Result := FFMessageBox.MessageDlg('Document ' + ExtractFileName(Target) + ' already exists, do you wish to overwrite it?', mtConfirmation, [mbYes,mbNo], 0) = mrYes else Result := True;
          if Result then begin
             Result := CopyFile(PChar(Source), PChar(Target), False);
             if not Result then FFMessageBox.MessageDlg('Error copying ' + ExtractFileName(Source) + ' to ' + ExtractfileName(Target) + #13#10 + ErrorRaise(GetLastError), mtError, [mbOk], 0)
             else if Move then if not DeleteFile(Source) then
             FFMessageBox.MessageDlg('Error deleting ' + Source + ': ' + ErrorRaise(GetLastError), mtError, [mbOk], 0);
          end;
          end;
     end;

procedure TFFMain.FileExecute(Op: string; FileName: string);
begin
     try ShellExecute(Application.Handle, PChar(Op), PChar(FileName), '', PChar(ExtractFileDir(FileName)), SW_SHOWMAXIMIZED); except end;
     end;

procedure TFFMain.docOpenAsClick(Sender: TObject);
var
   CName, CWName: string;
begin
     if docOpenAs.Enabled then begin
        CName := FFShell.Items[FFShell.ItemIndex];
        if FFMessageBox.InputQuery('Open a Copy', 'Please enter a new document name:', CName) then
           if Length(CName) > 0 then begin
              CWName := AppendExt(CName, '.doc');
              if FileCopyFile(bs(FFShell.Directory) + AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), bs(FFShell.Directory)+CWName, False) then begin
                 FFShell.Root.AddtoRecent(bs(FFShell.Directory) + CWName);
                 FileExecute('open', bs(FFShell.Directory)+CWName);
                 FFShell.RefreshCurrent;
                 SelectDocument(RemoveExt(CWName, '.doc'));
                 end;
              end;
           end;
     end;

procedure TFFMain.FFShellDblClick(Sender: TObject);
begin
     docOpenAsClick(Sender);
     end;

procedure TFFMain.Selectdocument(CName: string);
var
   i: integer;
begin
     CName := RemoveExt(CName, '.doc');
     for i:=FFShell.Items.Count - 1 downto 0 do begin
         if (CName = FFShell.Items[i]) then begin
            FFShell.ItemIndex := i;
            break;
            end;
         end;
     if Assigned(FFShell.OnChange) then FFShell.OnChange(Self);
     end;

procedure TFFMain.docOpenClick(Sender: TObject);
begin
     if docOpen.Enabled then begin
        FFShell.Root.AddtoRecent(bs(FFShell.Directory) + FFShell.Items[FFShell.ItemIndex]);
        FileExecute('open', bs(FFShell.Directory) + AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'));
        end;
     end;

procedure TFFMain.docNewClick(Sender: TObject);
          function FormatDateDoc: string;
          begin
               Result := FormatDateTime('yymmdd', Now);
               end;

          function GetUniqueName(Root, Name, Ext: string): string;
          var
             Counter: integer;
          begin
               Root := bs(Root);
               if CompareText(ExtractFileExt(Name), Ext) = 0 then Delete(Name, Length(Name) - Length(Ext) + 1, Length(Name));
               Result := Name;
               Counter := 1;
               while FileExists(Root + Result + Ext) do begin
                     if CompareText(ExtractFileExt(Name), Ext) = 0 then Delete(Name, Length(Name) - Length(Ext) + 1, Length(Name));
                     Result := Name + '_' + IntToStr(Counter);
                     inc(Counter);
                     end;
               Result := Result + Ext;
               end;

var
   OLEWordBasic: Variant;
   CName: string;
begin
     if docNew.Enabled then begin
        CName := FormatDateDoc;
        CName := RemoveExt(GetUniqueName(bs(FFShell.Directory), CName, '.doc'), '.doc');
        if FFMessageBox.InputQuery('New Document Name', 'Please enter a new Word document name:', CName) then
           if (Length(CName) > 0) then begin
              CName := AppendExt(CName, '.doc');
              OLEWordBasic := GetOleObject('Word.Basic');
              OLEWordBasic.FileNew('Normal');
              if FileExists(bs(FFShell.Directory) + CName) then begin
                 if FFMessageBox.MessageDlg('Document ' + CName + ' already exists, do you wish to overwrite it?', mtConfirmation, [mbYes,mbNo], 0) = mrYes then
                    DeleteFile(PChar(bs(FFShell.Directory) + CName)) else exit;
                 end;
              OLEWordBasic.FileSaveAs(bs(FFShell.Directory) + CName,,,'');
              FFShell.RefreshCurrent;
              SelectDocument(CName);
              FFShell.Root.AddtoRecent(bs(FFShell.Directory) + CName);
              OleWordBasic.AppMinimize(True);
              OLEWordBasic.AppMaximize(True);
           end;
     end;

end;

function TFFMain.GetOLEObject(ClassName: string): Variant;
begin
     try
     Result := GetActiveOleObject(ClassName);
     except
      try
      Result := CreateOleObject(ClassName);
      except
      FFMessageBox.MessageDlg('Error creating OLE object ' + ClassName + ': ' + ErrorRaise(GetLastError), mtError, [mbOk], 0);
      end;
     end;
     end;

procedure TFFMain.docPrintClick(Sender: TObject);
begin
     if docPrint.Enabled then begin
        FileExecute('print', bs(FFShell.Directory) + AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'));
        end;
     end;

procedure TFFMain.docRenameClick(Sender: TObject);
var
   CName, CWName: string;
begin
     if docRename.Enabled then begin
        CName := FFShell.Items[FFShell.ItemIndex];
        if FFMessageBox.InputQuery('Rename a Document', 'Please enter a new document name:', CName) then
           if Length(CName) > 0 then begin
              CWName := AppendExt(CName, '.doc');
              if FileCopyFile(bs(FFShell.Directory) + AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), bs(FFShell.Directory)+CWName, False) then begin
                 if FFShell.Items[FFShell.ItemIndex] <> RemoveExt(CWName, '.doc') then
                 if not DeleteFile(bs(FFShell.Directory)+AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc')) then begin
                    FFMessageBox.MessageDlg('Error deleting ' + FFShell.Items[FFShell.ItemIndex] + ': ' + ErrorRaise(GetLastError), mtError, [mbOk], 0);
                    end else begin
                    FFShell.RefreshCurrent;
                    SelectDocument(AppendExt(CWName, '.doc'));
                    end;
                 end;
              end;
           end;
     end;

procedure TFFMain.docRemoveClick(Sender: TObject);
var
   CurrentItem: String;
begin
     if DocRemove.Enabled then begin
        CurrentItem := FFShell.Items[FFShell.ItemIndex];
        if FFMessageBox.MessageDlg('Are you sure you want to delete ' + CurrentItem + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        if not DeleteFile(bs(FFShell.Directory)+AppendExt(CurrentItem, '.doc')) then begin
           FFMessageBox.MessageDlg('Error deleting ' + CurrentItem + ': ' + ErrorRaise(GetLastError), mtError, [mbOk], 0);
           end else begin
           FFShell.RefreshCurrent;
           end;
        end;
     end;

procedure TFFMain.FFSWWordClick(Sender: TObject);
var
   OleWordBasic : Variant;
begin
     OLEWordBasic := GetOleObject('Word.Basic');
     OleWordBasic.AppMinimize(True);
     OLEWordBasic.AppMaximize(True);
     end;

procedure TFFMain.cmdNewFolderClick(Sender: TObject);
var
   CName: string;
begin
     if cmdNewFolder.Enabled then begin
        CName := FormatDateTime('yymmdd', Now);
        if FFMessageBox.InputQuery('New Folder Name', 'Please enter a new folder name:', CName) then begin
           if DirectoryExists(bs(FFShell.Directory) + CName) then begin
              FFMessageBox.Messagedlg('This directory already exists, changing to it.', mtError, [mbOk], 0);
              SelectDocument(CName);
              FFShell.OpenCurrent;
              FFShell.OnChange(Sender);
              end else begin
              if CreateDir(bs(FFShell.Directory) + CName) then begin
                 FFShell.RefreshCurrent;
                 SelectDocument(CName);
                 FFShell.OpenCurrent;
                 FFShell.OnChange(Sender);
                 end else begin
                 FFMessageBox.MessageDlg('Error creating ' + CName + #13#10 + ErrorRaise(GetLastError), mtError, [mbOk], 0);
                 end;
              end;
           end;
        end;
     end;

procedure TFFMain.cmdRenameFolderClick(Sender: TObject);
var
   OldName, OldPath, CName: string;
begin
     if cmdRenameFolder.Enabled then begin
        CName := FFShell.Items[FFShell.ItemIndex];
        OldName := CName;
        OldPath := bs(ExtractFilePath(FFShell.GetRealPath));
        if FFMessageBox.InputQuery('New Folder Name', 'Please enter a new folder name:', CName) then begin
           ShowMessage(OldPath+OldName+ '->' + OldPath+CName);
           if CName <> OldName then
           if MoveFile(PChar(OldPath+OldName), PChar(OldPath+CName)) then begin
              FFShell.Directory := OldPath+CName;
              FFShell.Items[FFShell.ItemIndex] := CName;
              end else begin
              FFMessageBox.MessageDlg('Error renaming ' + FFShell.Items[FFShell.ItemIndex] + #13#10 + ErrorRaise(GetLastError), mtError, [mbOk], 0);
              end;
           end;
        end;

     end;

procedure TFFMain.FormKeyPress(Sender: TObject; var Key: Char);
var
   ptPanelCol : TColor;
begin
     case Ord(Key) of
          8:    begin
                ptPanel.Caption := Copy(ptPanel.Caption, 1, Length(ptPanel.Caption) - 1);
                FFShell.SelectCloser(ptPanel.Caption);
                end;
        13, 10: begin
                if (Length(ptPanel.Caption) = 0) or (CompareText(ptPanel.Caption, Copy(FFShell.Items[FFShell.ItemIndex], 1, Length(ptPanel.Caption))) = 0) then begin
                   ptPanel.Caption := '';
                   docOpenAsClick(Sender);
                   end else begin
                   FFShell.OpenLocked := FFShell.OpenLocked+1;
                   ptPanelCol := ptPanel.Color;
                   ptPanel.Color := clRed;
                   ptPanel.Refresh;
                   sleep(150);
                   ptPanel.Color := ptPanelCol;
                   ptPanel.Refresh;
                   end;
                end;
        5,32:   begin
                end;
        27:     begin
                ptPanel.Caption := '';
                FFShell.SelectParent;
                end;
        else    begin
                   ptPanel.Caption := ptPanel.Caption + Key;
                   if (PtPanel.Caption[1] <> '-') then FFShell.SelectCloser(ptPanel.Caption);
                   if ptPanel.Caption = '--setup' then cmdSetupClick(Sender)
                   else if ptPanel.Caption = '--quit' then cmdQuitClick(Sender)
                   else if ptPanel.Caption = '--kill' then begin
                        ptPanel.Caption := '';
                        KillFolder;
                        end;
                end;
        end;
     end;

procedure TFFMain.FFShellKeyPress(Sender: TObject; var Key: Char);
begin
     Key := Chr(0);
     end;

procedure TFFMain.docCopyToClick(Sender: TObject);
begin
     if DocCopyTo.Enabled then begin
        FFSel.FFSelDir.SetRoot(FFShell.Root);
        if FFSel.Execute = mrOk then begin
           if FFSel.Directory = FFShell.Directory then
              FFMessageBox.MessageDlg('Source and destination are identical!', mtError, [mbOk], 0)
           else if fileCopyFile(bs(FFShell.Directory)+AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), bs(FFSel.Directory)+AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), False) then begin
                FFShell.Directory := FFSel.Directory;
                FFMessageBox.MessageDlg('Successfully copied ' + FFShell.Items[FFShell.ItemIndex] + ' to ' + FFSel.Directory, mtInformation, [mbOk], 0);
                end;
           end;
        end;
end;

procedure TFFMain.docMovetoClick(Sender: TObject);
begin
     if DocMoveTo.Enabled then begin
        FFSel.FFSelDir.SetRoot(FFShell.Root);
        if FFSel.Execute = mrOk then begin
           if FFSel.Directory = FFShell.Directory then
              FFMessageBox.MessageDlg('Source and destination are identical!', mtError, [mbOk], 0)
           else if fileCopyFile(bs(FFShell.Directory)+AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), bs(FFSel.Directory)+AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), True) then begin
                FFShell.Directory := FFSel.Directory;
                FFMessageBox.MessageDlg('Successfully moved ' + FFShell.Items[FFShell.ItemIndex] + ' to ' + FFSel.Directory, mtInformation, [mbOk], 0);
                end;
           end;
        end;
     end;

procedure TFFMain.docRecentClick(Sender: TObject);
var
   Point: TPoint;
begin
     FFShell.Root.RecentToMenu(RecentMenu);
     Point.X := docRecent.Width div 2;
     Point.Y := docRecent.Height div 2;
     Point := docRecent.ClientToScreen(Point);
     RecentMenu.Popup(Point.X, Point.Y);
     end;

procedure TFFMain.DocPopMenuPopup(Sender: TObject);
begin
     popNewDoc.Enabled := docNew.Enabled;
     popOpenDoc.Enabled := docOpen.Enabled;
     popOpenAs.Enabled := docOpenAs.Enabled;
     popPrintDoc.Enabled := docPrint.Enabled;
     popRenameDoc.Enabled := docRename.Enabled;
     popDelDoc.Enabled := docRemove.Enabled;
     popCopyTo.Enabled := docCopyTo.Enabled;
     popDocMove.Enabled := docMoveto.Enabled;
     popDocProps.Enabled := docProperties.Enabled;
     popDocPreview.Enabled := docPreview.Enabled;
     popTxtPreview.Enabled := txtPreview.Enabled;
     end;

procedure TFFMain.FFShellMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
   CurPoint: TPoint;
begin
     CurPoint.X := X;
     CurPoint.Y := Y;
     if Button = mbRight then begin
        FFShell.ItemIndex := FFShell.ItemAtPos(CurPoint, False);
        if Assigned(FFShell.OnChange) then FFShell.OnChange(Sender);
        FFShell.OpenCurrent;
        CurPoint := FFShell.ClientToScreen(CurPoint);
        case FFShell.ItemStyle(FFSHell.ItemIndex) of
             worddoc: begin
                      DocPopMenu.Popup(CurPoint.X, CurPoint.Y);
                      end;
             else     begin
                      FolderPopupMenu.Popup(CurPoint.X, CurPoint.Y);
                      end;
             end;
        end else if Button = mbLeft then begin
        if (FFShell.ItemAtPos(CurPoint, True) <> -1) then begin
            ptPanel.Caption := '';
            FFShell.HaveKeyPressed := False;
            end;
        end;
     end;

procedure TFFMain.FolderPopupMenuPopup(Sender: TObject);
begin
     popFolCreateNew.Enabled := cmdNewFolder.Enabled;
     popFolRename.Enabled := cmdRenameFolder.Enabled;
     popFolProperties.Enabled := cmdFolProps.Enabled;
     popFolDocNew.Enabled := docNew.Enabled;
     end;

procedure TFFMain.ReadRegistry;
var
   t: integer;
   s: string;
   Root: TFFRoot;
begin
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFMain.Width'); if t > 0 then Self.Width := t;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFMain.Height'); if t > 0 then Self.Height := t;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFMain.Left'); if t >= 0 then Self.Left := t else Self.Left := (Screen.Width - Self.Width) div 2;
     t := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'FFMain.Top'); if t >= 0 then Self.Top := t else Self.Top := (Screen.Height - Self.Height) div 2;
     s := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'Volume'); if (s <> '-1') then begin
       Root := VManager.FindVolumePhysical(s);
       if Assigned(Root) then begin
          for t:=0 to VolumesList.Items.Count - 1 do
              if CompareText(VolumesList.Items[t], Root.Name) = 0 then begin
                 VolumesList.ItemIndex := t;
                 break;
                 end;
          FFShell.SetRoot(Root);
          end;
       end;
     s := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'Folder'); if (s <> '-1') then FFShell.Directory := s;
     end;

procedure TFFMain.WriteRegistry;
begin
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFMain.Width', Self.Width);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFMain.Height', Self.Height);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFMain.Left', Self.Left);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'FFMain.Top', Self.Top);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'Volume', FFShell.Root.Path);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'Folder', FFShell.Directory);
     end;

procedure TFFMain.cmdFolPropsClick(Sender: TObject);
begin
     if cmdFolProps.Enabled then begin
        if not FFProp.Visible then FFProp.Show;
        FFProp.ShowPropsVolume(FFShell.GetPath, FFShell.Root.Name + FFShell.VPath);
        end;
     end;

procedure TFFMain.docPropertiesClick(Sender: TObject);
begin
     if docProperties.Enabled then begin
        if not FFProp.Visible then FFProp.Show;
        FFProp.ShowProps(bs(FFShell.GetPath)+AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), FFShell.Root.Name + FFShell.VPath);
        end;
     end;

procedure TFFMain.docPreviewClick(Sender: TObject);
begin
     if docPreview.Enabled then begin
        if not FFPreview.Visible then FFPreview.Show;
        FFPreview.CreateLinkToFile(bs(FFShell.GetPath)+AppendExt(FFShell.Items[FFShell.ItemIndex], '.doc'), FFShell.Root.Name + FFShell.VPath);
        end;
     end;

procedure TFFMain.cmdHelpClick(Sender: TObject);
begin
     if cmdHelp.Enabled then Application.HelpCommand(HELP_FINDER, 0);
     end;

procedure TFFMain.FFShellKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
     case Key of
          46: docRemoveClick(Sender);
          45: docNewClick(Sender);
          end;
     end;

procedure TFFMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
     case Key of
          {37, 39,}38, 40: begin
                  ptPanel.Caption := '';
                  end;
          end;
     end;

function TFFMain.AppendExt(Name, Ext: string): string;
begin
     if ExtractFileExt(Name) <> Ext then Result := Name + Ext else Result := Name;
     end;

function TFFMain.RemoveExt(Name, Ext: string): string;
begin
     if ExtractFileExt(Name) = Ext then Result := Copy(Name, 0, Length(Name) - Length(Ext)) else Result := Name;
     end;


procedure TFFMain.cmdKillFolderClick(Sender: TObject);
begin
     if cmdKillFolder.Enabled then
        if (FFMessageBox.MessageDlg('Are you sure you wish to delete ' + FFShell.Items[FFShell.ItemIndex], mtConfirmation, [mbYes,mbNo], 0) = mrYes) then begin
           KillFolder;
           end;
     end;

procedure TFFMain.KillFolder;
var
   CName, OldName, OldPath: string;
   pSel: integer;
begin
     if FFShell.ItemStyle(FFSHell.ItemIndex) in [folder] then begin
        CName := FFShell.Items[FFShell.ItemIndex];
        OldName := CName;
        OldPath := bs(ExtractFilePath(FFShell.GetRealPath));
        CName[1] := '$';
        if CName <> OldName then
        if MoveFile(PChar(OldPath+OldName), PChar(OldPath+CName)) then begin
           pSel := FFShell.ItemIndex;
           FFShell.SelectParent;
           if FFShell.ItemIndex = pSel then begin
              FFShell.ItemIndex := FFShell.ItemIndex - 1;
              FFShell.OpenCurrent;
              end else FFShell.RefreshCurrent;
           FFShell.OpenLocked := 0;
           end else begin
        FFMessageBox.MessageDlg('Error deleting ' + FFShell.Items[FFShell.ItemIndex] + #13#10 + ErrorRaise(GetLastError), mtError, [mbOk], 0);
        end;
     end;
     end;

procedure TFFMain.StatusBarResize(Sender: TObject);
begin
     StatusBar.Panels[0].Width := StatusBar.ClientWidth - StatusBar.Panels[1].Width;
     end;

procedure TFFMain.GMTimerTimer(Sender: TObject);
begin
     if SemiBool then StatusBar.Panels[1].Text := FormatDateTime('hh mm', Now)
     else StatusBar.Panels[1].Text := FormatDateTime('hh:mm', Now);
     SemiBool := not SemiBool;
     end;

procedure TFFMain.VolumesListKeyPress(Sender: TObject; var Key: Char);
begin
     Key := Chr(0);
     FFShell.SetFocus;
     end;

procedure TFFMain.docOpenCopyAs(Document: string);
          procedure OpenChange(OpenAs: boolean);
          begin
               FFShell.Directory := ExtractFileDir(Document);
               SelectDocument(ExtractFileName(Document));
               if OpenAs then docOpenAsClick(Self) else docOpenClick(Self);
               end;
var
   CName, CWName: string;
   iRes: integer;
begin
     if (DocNew.Enabled) and (CompareText(FFShell.Directory,ExtractFileDir(Document)) <> 0) then begin
        CName := RemoveExt(ExtractFileName(Document), '.doc');
        iRes := FFMessageBox.InputQueryExt('Open a Copy in ' + FFShell.VPath, 'Please enter a new document name:', CName, [mbCancel], 'Open,Copy');
        if (iRes = 100) then OpenChange(False)
        else if (iRes = 101) and (Length(CName) > 0) then begin
              CWName := AppendExt(CName, '.doc');
              if FileCopyFile(Document, bs(FFShell.Directory)+CWName, False) then begin
                 FFShell.Root.AddtoRecent(bs(FFShell.Directory) + CWName);
                 FileExecute('open', bs(FFShell.Directory)+CWName);
                 FFShell.RefreshCurrent;
                 SelectDocument(RemoveExt(CWName, '.doc'));
                 end;
              end;
        end else OpenChange(True);
     end;

procedure TFFMain.txtPreviewClick(Sender: TObject);
begin
     if txtPreview.Enabled then begin
        if not FFTxtPreview.Visible then FFTxtPreview.Show;
        FFTxtPreview.ShowDocument(FFShell.GetItemPath(FFShell.ItemIndex), FFShell.Root.Name + FFShell.VPath);
        end;
     end;

end.
