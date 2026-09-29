unit ExtManager;

interface

uses FFRoot, Classes, FFcommon, d32reg, WinTypes, StdCtrls,
     ComCtrls, Sysutils, Dialogs;

type
    TExtManager = class
       public
             SetupNode: TTreeNode;
             constructor Create;
             destructor Destroy; override;
             procedure Add(Ext: string);
             function Count: integer;
             procedure ReadRegistry;
             procedure WriteRegistry;
             procedure CreateSetupNode(TreeView: TTreeView);
             procedure InheritFrom(ExtManager: TExtManager);
             function FindExt(Ext: string): boolean;
             procedure Remove(Ext: string);
             function Get(Index: integer): string;
       private
             Extensions : TStringList;
       end;

implementation

function TExtManager.Get(Index: integer): string;
begin
     Result := Extensions[Index];
     end;

constructor TExtManager.Create;
begin
     Extensions := TStringList.Create;
     ReadRegistry;
     end;

destructor TExtManager.Destroy;
begin
     Extensions.Destroy;
     inherited;
     end;

function TExtManager.Count: integer;
begin
     Result := Extensions.Count;
     end;

procedure TExtManager.Add(Ext: String);
begin
     Extensions.Add(Ext);
     end;

procedure TExtManager.ReadRegistry;
var
   KeyVolumes: TStringList;
   i: integer;
begin
     KeyVolumes := TStringList.Create;
     GetKeyValues(HKEY_CURRENT_USER, regRootExtensions, KeyVolumes);
     for i:=0 to KeyVolumes.Count - 1 do begin
         Add(QueryReg(HKEY_CURRENT_USER, regRootExtensions, KeyVolumes[i]));
         end;
     KeyVolumes.Destroy;
     if (Extensions.Count = 0) then Add('*.doc');
     end;

procedure TExtManager.WriteRegistry;
var
   i: integer;
begin
     DeleteKey(HKEY_CURRENT_USER, regRootExtensions, '');
     for i:=0 to Extensions.Count - 1 do begin
         AddReg(HKEY_CURRENT_USER, regRootExtensions, IntToStr(i), Extensions[i]);
         end;
     end;

procedure TExtManager.CreateSetupNode(TreeView: TTreeView);
var
   i: integer;
begin
     if not Assigned(SetupNode) then begin
        SetupNode := TreeView.Items.Add(nil, 'Extensions Manager');
        SetupNode.ImageIndex := 1;
        SetupNode.SelectedIndex := 0;
        end else SetupNode.DeleteChildren;
     for i:=0 to Extensions.Count - 1 do begin
         with TreeView.Items.AddChild(SetupNode, Extensions[i]) do begin
              ImageIndex := 5;
              SelectedIndex := 5;
              end;
         end;
     SetupNode.Expand(False);
     end;

procedure TExtManager.InheritFrom(ExtManager: TExtManager);
var
   i: integer;
begin
     Extensions.Clear;
     for i:=0 to ExtManager.Extensions.Count - 1 do begin
         Extensions.Add(ExtManager.Extensions[i]);
         end;
     end;

function TExtManager.FindExt(Ext: string): boolean;
begin
     Result := (Extensions.IndexOf(Ext) <> -1);
     end;

procedure TExtManager.Remove(Ext: string);
begin
     Extensions.Delete(Extensions.IndexOf(Ext));
     end;

end.
