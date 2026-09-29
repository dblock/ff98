unit FFSetup;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  VVManager, ffButton, ComCtrls, ToolWin, BrowseDr, FFRoot, ExtCtrls, ExtManager,
  StdCtrls, Spin, Buttons, Menus;

type
  TFFSet = class(TForm)
    SetupView: TTreeView;
    SetupImages: TImageList;
    FFPathSelector: TBrowseDirectoryDlg;
    FFSetImages: TImageList;
    cmdPanel: TPanel;
    cmdToolBar: TToolBar;
    cmdCreateVolume: TToolButton;
    cmdSaveClose: TToolButton;
    cmdClose: TToolButton;
    cmdDeleteVolume: TToolButton;
    cmdBottomBar: TToolBar;
    cmdButtonEnableDisable: TToolButton;
    ColCount: TSpinEdit;
    Label1: TLabel;
    FFLogo: TSpeedButton;
    popVolumes: TPopupMenu;
    popAddVolume: TMenuItem;
    popDeleteVolume: TMenuItem;
    N1: TMenuItem;
    popButtonEnableDisable: TMenuItem;
    N2: TMenuItem;
    popSaveClose: TMenuItem;
    popClose: TMenuItem;
    procedure FormShow(Sender: TObject);
    procedure cmdCreateVolumeClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure cmdSaveCloseClick(Sender: TObject);
    procedure cmdCloseClick(Sender: TObject);
    procedure cmdDeleteVolumeClick(Sender: TObject);
    procedure InitVManager;
    procedure InitBManager;
    procedure InitEManager;
    procedure cmdButtonEnableDisableClick(Sender: TObject);
    procedure SetupViewChange(Sender: TObject; Node: TTreeNode);
    procedure SetupViewDblClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ColCountEnter(Sender: TObject);
    procedure popVolumesPopup(Sender: TObject);
  private
    VManager: TVVManager;
    BManager: TFFButtonManager;
    EManager: TExtManager;
    procedure WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo); message WM_GetMinMaxInfo;
    procedure WMwindowposchanging(var M: TWMwindowposchanging); message wm_windowposchanging;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SysCommand;
    procedure UpdateEnableDisable;
  public
  end;

var
  FFSet: TFFSet;

implementation

uses ff98, d32reg, FFCommon, FFMessage;

{$R *.DFM}

procedure TFFSet.FormShow(Sender: TObject);
var
   ColCountReg: integer;
begin
     SetupView.Items.Clear;
     InitVManager;
     InitBManager;
     InitEManager;
     ColCountReg := QueryReg(HKEY_CURRENT_USER, regRootGeneral, 'Shell.ColumnCount');
     if (ColCountReg > ColCount.MinValue) and (ColCountReg <= ColCount.MaxValue) then ColCount.Value := ColCountReg;
     end;

procedure TFFSet.InitVManager;
begin
     VManager := TVVManager.Create;
     with VManager do begin
          InheritFrom(FFMain.VManager);
          CreateSetupNode(SetupView);
          end;
     end;

procedure TFFSet.InitEManager;
begin
     EManager := TExtManager.Create;
     with EManager do begin
          InheritFrom(FFMain.EManager);
          //CreateSetupNode(SetupView);
          end;
     end;

procedure TFFSet.InitBManager;
begin
     BManager := TFFButtonManager.Create;
     with BManager do begin
          EnabledIndex := 7;
          DisabledIndex := 8;
          GroupSelIndex := 5;
          GroupIndex := 5;
          CreateSetupNode(SetupView);
          InheritFrom(FFMain.BManager);
          end;
     end;


procedure TFFSet.cmdCreateVolumeClick(Sender: TObject);
var
   CVName: string;
begin
     if FFPathSelector.Execute then
        if Length(FFPathSelector.Selected) > 0 then begin
           CVName := ExtractFileName(FFPathSelector.Selected);
           if Length(CVName) = 0 then CVName := FFPathSelector.Selected;
           if InputQuery('File & Folder Volume', 'Please enter a new volume name:', CVName) then
           if Length(CVName) > 0 then
              if VManager.FindVolume(FFPathSelector.Selected, CVName) = nil then begin
                 VManager.Add(CVName, FFPathSelector.Selected);
                 VManager.CreateSetupNode(SetupView);
                 end else MessageDlg('Sorry, such a volume is already in the list.', mtError, [mbOk], 0);
           end;
     end;


procedure TFFSet.FormClose(Sender: TObject; var Action: TCloseAction);
begin
     VManager.Destroy;
     BManager.Destroy;
     EManager.Destroy;
     end;

procedure TFFSet.cmdSaveCloseClick(Sender: TObject);
begin
     FFMain.VManager.InheritFrom(VManager);
     FFMain.BManager.InheritFrom(BManager);
     FFMain.EManager.InheritFrom(EManager);
     AddReg(HKEY_CURRENT_USER, regRootGeneral, 'Shell.ColumnCount', ColCount.Value);
     FFMain.FFShell.Columns := ColCount.Value;
     Close;
     end;

procedure TFFSet.cmdCloseClick(Sender: TObject);
begin
     Close;
     end;


procedure TFFSet.cmdDeleteVolumeClick(Sender: TObject);
begin
     if (SetupView.Selected.Parent <> VManager.SetupNode) then
        FFMessageBox.MessageDlg('Please select a valid Virtual Volume!', mtError, [mbOk], 0)
        else begin
        VManager.Remove(TFFRoot(SetupView.Selected.Data));
        VManager.CreateSetupNode(SetupView);
        end;
     end;

procedure TFFSet.WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo);
begin
   inherited;
   with Msg.MinMaxInfo^ do begin
      if ptMaxTrackSize.x>Screen.Width then ptMaxTrackSize.x:=Screen.Width;
      if ptMaxTrackSize.y>Screen.Height then ptMaxTrackSize.y:=Screen.Height;
      end;
   end;

procedure TFFSet.WMSysCommand(var Msg: TWMSysCommand);
begin
   if Msg.CmdType=SC_MINIMIZE then begin
      Application.Minimize;
      end else inherited;
   end;

procedure TFFSet.WMwindowposchanging(var M: TWMwindowposchanging);
begin
   inherited;
   with M.WindowPos^ do begin
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

procedure TFFSet.cmdButtonEnableDisableClick(Sender: TObject);
begin
     BManager.ToggleEnabled(TFFButton(SetupView.Selected.Data));
     UpdateEnableDisable;
     end;

procedure TFFSet.UpdateEnableDisable;
begin
     cmdButtonEnableDisable.Enabled := Assigned(SetupView.Selected.Parent) and
                                        Assigned(SetupView.Selected.Parent.Parent) and
                                        (SetupView.Selected.Parent.Parent = BManager.SetupNode);
     if cmdButtonEnableDisable.Enabled then
        if TFFButton(SetupView.Selected.Data).Enabled then cmdButtonEnableDisable.Caption := '&Disable Button'
        else cmdButtonEnableDisable.Caption := '&Enable Button';
     end;

procedure TFFSet.SetupViewChange(Sender: TObject; Node: TTreeNode);
begin
     cmdDeleteVolume.Enabled := (Node.Parent = VManager.SetupNode);
     UpdateEnableDisable;
     end;

procedure TFFSet.SetupViewDblClick(Sender: TObject);
begin
     UpdateEnableDisable;
     if cmdButtonEnableDisable.Enabled then begin
        BManager.ToggleEnabled(TFFButton(SetupView.Selected.Data));
        UpdateEnableDisable;
        end;
     end;

procedure TFFSet.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
     case Key of
          27: cmdCloseClick(Sender);
          end;
     end;

procedure TFFSet.ColCountEnter(Sender: TObject);
begin
     SetupView.SetFocus;
     end;

procedure TFFSet.popVolumesPopup(Sender: TObject);
begin
     popAddVolume.Enabled := cmdCreateVolume.Enabled;
     popDeleteVolume.Enabled := cmdDeleteVolume.Enabled;
     popButtonEnableDisable.Enabled := cmdButtonEnableDisable.Enabled;
     popButtonEnableDisable.Caption := cmdButtonEnableDisable.Caption;
     popSaveClose.Enabled := cmdSaveClose.Enabled;
     popClose.Enabled := cmdClose.Enabled;
     end;

end.

