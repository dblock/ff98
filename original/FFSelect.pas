unit FFSelect;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, ComCtrls, StdCtrls, Buttons, FFDirListBox;

type
  TffSel = class(TForm)
    OpPanel: TPanel;
    FFSOk: TBitBtn;
    FFSCancel: TBitBtn;
    FFSelDir: TFFDirListBox;
    procedure OpPanelResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FFSelDirChange(Sender: TObject);
  private
    FDirectoryName: string;
    MinHeight, MinWidth: integer;
    procedure WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo); message WM_GetMinMaxInfo;
    procedure WMwindowposchanging(var M: TWMwindowposchanging); message wm_windowposchanging;
  public
    function Execute: integer;
  published
    property Directory: string read FDirectoryName;
  end;

var
  FFSel: TFFSel;

implementation

{$R *.DFM}

function TFFSel.Execute: integer;
begin
     FdirectoryName := '';
     Result := Self.ShowModal;
     end;

procedure TFFSel.WMGetMinMaxInfo(var Msg: TWMGetMinMaxInfo);
begin
   inherited;
   with Msg.MinMaxInfo^ do begin
      if ptMinTrackSize.x< minWidth then ptMinTrackSize.x:= minWidth;
      if ptMinTrackSize.y< minHeight then ptMinTrackSize.y:= minHeight;
      if ptMaxTrackSize.x>Screen.Width then ptMaxTrackSize.x:=Screen.Width;
      if ptMaxTrackSize.y>Screen.Height then ptMaxTrackSize.y:=Screen.Height;
      end;
   end;

procedure TFFSel.WMwindowposchanging(var M: TWMwindowposchanging);
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

procedure TffSel.OpPanelResize(Sender: TObject);
begin
     FFSOk.Left := OpPanel.ClientWidth - FFSOk.Width - 2;
     FFSCancel.Left := FFSOk.Left - FFSCancel.Width - 2;
     end;

procedure TffSel.FormCreate(Sender: TObject);
begin
     MinHeight := Self.Height;
     MinWidth := Self.Width;
     end;

procedure TffSel.FFSelDirChange(Sender: TObject);
begin
     FFSOk.Enabled := not FFSelDir.SubRoot;
     if FFSOk.Enabled then FDirectoryName := FFSelDir.Directory;
     end;

end.
