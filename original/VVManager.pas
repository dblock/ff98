unit VVManager;

interface

uses FFRoot, Classes, FFcommon, d32reg, WinTypes, StdCtrls,
     ComCtrls, Sysutils, Dialogs;

type
    TVVManager = class
       public
             SetupNode: TTreeNode;
             constructor Create;
             destructor Destroy; override;
             procedure Add(Alias, Physical: String);
             function Count: integer;
             procedure ReadRegistry;
             procedure WriteRegistry;
             procedure PopulateCombo(cBox: TComboBox);
             procedure CreateSetupNode(TreeView: TTreeView);
             procedure InheritFrom(VManager: TVVManager);
             function FindVolume(Physical, Alias: string): TFFRoot;
             function FindVolumePhysical(Physical: string): TFFRoot;
             procedure Remove(Vol: TFFRoot);
       private
             Box: TComboBox;
             VVolumes : TList;
       end;

implementation

constructor TVVManager.Create;
begin
     VVolumes := TList.Create;
     ReadRegistry;
     end;

destructor TVVManager.Destroy;
begin
     VVolumes.Destroy;
     inherited;
     end;

function TVVManager.Count: integer;
begin
     Result := VVolumes.Count;
     end;

procedure TVVManager.Add(Alias, Physical: String);
begin
     VVolumes.Add(TFFRoot.Create(Alias, Physical));
     end;

procedure TVVManager.ReadRegistry;
var
   KeyVolumes: TStringList;
   i: integer;
begin
     KeyVolumes := TStringList.Create;
     GetKeyValues(HKEY_CURRENT_USER, regRootVolumes, KeyVolumes);
     for i:=0 to KeyVolumes.Count - 1 do
         Add(KeyVolumes[i], QueryReg(HKEY_CURRENT_USER, regRootVolumes, KeyVolumes[i]));
     KeyVolumes.Destroy;
     end;

procedure TVVManager.WriteRegistry;
var
   i: integer;
begin
     DeleteKey(HKEY_CURRENT_USER, regRootVolumes, '');
     for i:=0 to VVolumes.Count - 1 do begin
         AddReg(HKEY_CURRENT_USER, regRootVolumes, TFFRoot(VVolumes[i]).Name, TFFRoot(VVolumes[i]).Path);
         TFFRoot(VVolumes[i]).WriteRegistry;
         end;
     end;

procedure TVVManager.PopulateCombo(cBox: TComboBox);
var
   i: integer;
begin
     Box := cBox;
     Box.Items.Clear;
     if VVolumes.Count > 0 then begin
        for i:=0 to VVolumes.Count - 1 do Box.Items.AddObject(TFFRoot(VVolumes[i]).Name, VVolumes[i]);
        Box.ItemIndex := 0;
        end;
     Box.OnChange(self);
     Box.Visible := (Box.Items.Count > 1);
     end;

procedure TVVManager.CreateSetupNode(TreeView: TTreeView);
var
   i: integer;
begin
     if not Assigned(SetupNode) then begin
        SetupNode := TreeView.Items.Add(nil, 'Volumes Manager');
        SetupNode.ImageIndex := 1;
        SetupNode.SelectedIndex := 0;
        end else SetupNode.DeleteChildren;
     for i:=0 to VVolumes.Count - 1 do begin
         with TreeView.Items.AddChildObject(SetupNode, TFFRoot(VVolumes[i]).Name + ' -> ' + TFFRoot(VVolumes[i]).Path, VVolumes[i]) do begin
              ImageIndex := 2;
              SelectedIndex := 3;
              end;
         end;
     SetupNode.Expand(False);
     end;

procedure TVVManager.InheritFrom(VManager: TVVManager);
var
   i: integer;
begin
     VVolumes.Clear;
     for i:=0 to VManager.VVolumes.Count - 1 do begin
         VVolumes.Add(TFFRoot.CreateClone(VManager.VVolumes[i]));
         end;
     if Assigned(Box) then PopulateCombo(Box);
     end;

function TVVManager.FindVolume(Physical, Alias: string): TFFRoot;
var
   i: integer;
begin
     for i:=0 to VVolumes.Count - 1 do begin
         if (CompareText(TFFRoot(VVolumes[i]).Name, Alias) = 0) and
            (CompareText(TFFRoot(VVolumes[i]).Path, Physical) = 0) then begin
               Result := TFFRoot(VVolumes[i]);
               exit;
               end;
         end;
     Result := nil;
     end;

function TVVManager.FindVolumePhysical(Physical: string): TFFRoot;
var
   i: integer;
begin
     for i:=0 to VVolumes.Count - 1 do begin
        if (TFFRoot(VVolumes[i]).Path = Physical) then begin
               Result := TFFRoot(VVolumes[i]);
               exit;
               end;
         end;
     Result := nil;
     end;


procedure TVVManager.Remove(Vol: TFFRoot);
begin
     VVolumes.Remove(Vol);
     if Assigned(Box) then PopulateCombo(Box);
     end;

end.
