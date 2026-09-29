unit BrowseDr;

// Stand-in for the third-party TBrowseDirectoryDlg component that File & Folder 98
// used to pick a folder, built on the LCL's TSelectDirectoryDialog.

interface

uses Classes, Dialogs;

type
  TBrowseFlag = (bfDirectoriesOnly, bfDontGoBelowDomain, bfStatusText,
    bfFileSysAncestors, bfComputers, bfPrinters, bfIncludeFiles);
  TBrowseFlags = set of TBrowseFlag;

  TBrowseDirectoryDlg = class(TComponent)
  private
    FTitle: string;
    FOptions: TBrowseFlags;
    FSelected: string;
  public
    function Execute: Boolean;
  published
    property Title: string read FTitle write FTitle;
    property Options: TBrowseFlags read FOptions write FOptions;
    property Selected: string read FSelected write FSelected;
  end;

implementation

function TBrowseDirectoryDlg.Execute: Boolean;
var
  Dlg: TSelectDirectoryDialog;
begin
  Dlg := TSelectDirectoryDialog.Create(nil);
  try
    Dlg.Title := FTitle;
    Dlg.FileName := FSelected;
    Result := Dlg.Execute;
    if Result then FSelected := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;

end.
