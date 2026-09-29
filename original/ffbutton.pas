unit ffButton;

interface

uses Classes, ComCtrls, Controls, SysUtils, Dialogs, d32reg, d32gen, ffCommon;

type

    TFFButton = class
       private
          FComponent: TWinControl;
          FNode: TTreeNode;
          FCaption: string;
          FEnabled: boolean;
          FSync: boolean;
          FCategory: string;
          procedure SetEnabled(Value: boolean);
       public
          constructor Create(Component: TWinControl; Caption, Category: string);
          constructor CreateSync(Component: TWinControl; Caption, Category: string);
          procedure Attach(Node: TTreeNode);
          procedure SetImageIndex(Enabled, Hidden: integer);
          procedure SetGroupIndex(Normal, Selected: integer);
          procedure SyncForward;
          procedure SyncBackward;
       published
          property Category: string read FCategory;
          property Enabled: boolean read FEnabled write SetEnabled;
          property Caption: string read FCaption;
       end;

    TFFButtonManager = class
       public
             procedure CreateSetupNode(TreeView: TTreeView);
             constructor Create;
             destructor Destroy; override;
             function AddButton(Control: TObject; Caption, Category: string): TFFButton;
             procedure AddButtonSync(Control: TObject; Caption, Category: string);
             procedure AddButtonObject(FButton: TFFButton);
             procedure Attach(Node: TTReeNode);
             procedure SetEnabled(Button: TFFButton; Value: boolean);
             procedure ToggleEnabled(Button: TFFButton);
             procedure ReadRegistry;
             procedure WriteRegistry;
             procedure InheritFrom(Manager: TFFButtonManager);
             procedure UpdateButtons;
             function isEnabled(Button: TObject): boolean;
       private
             FButtons: TList;
             FNode: TTreeNode;
             FEnabledIndex, FDisableDIndex, FGroupIndex, FGroupSelIndex: integer;
             procedure SetEnabledIndex(Value: integer);
             procedure SetDisabledIndex(Value: integer);
             procedure SetGroupIndex(Value: integer);
             procedure SetGroupSelIndex(Value: integer);
             procedure UpdateIndex;
             procedure UpdateButton(Caption: string; Enabled: boolean);
             procedure AdjustExpand;
       published
             property EnabledIndex: integer read FEnabledIndex write SetEnabledIndex;
             property DisabledIndex: integer read FDisabledIndex write SetDisabledIndex;
             property GroupIndex: integer read FGroupIndex write SetGroupIndex;
             property GroupSelIndex: integer read FGroupSelIndex write SetGroupSelIndex;
             property SetupNode : TTreeNode read FNode;
       end;

implementation

uses WinTypes;

procedure TFFButtonManager.SetGroupIndex(Value: integer);
begin
     if FGroupIndex <> Value then begin
        FGroupIndex := Value;
        end;
     end;

procedure TFFButtonManager.SetGroupSelIndex(Value: integer);
begin
     if FGroupIndex <> Value then begin
        FGroupSelIndex := Value;
        UpdateIndex;
        end;
     end;

function TFFButtonManager.isEnabled(Button: TObject): boolean;
var
   i: integer;
begin
     for i:=0 to FButtons.Count - 1 do
         if Button = TFFButton(FButtons[i]).FComponent then begin
            Result := TFFButton(FButtons[i]).FEnabled;
            exit;
            end;
     Result := True;
     end;

procedure TFFButton.SyncBackward;
begin
     if FComponent.Enabled <> FEnabled then FEnabled := FComponent.Enabled;
     end;

procedure TFFButton.SyncForward;
begin
     if FSync and (FComponent.Enabled <> FEnabled)  then FComponent.Enabled := FEnabled;
     end;

procedure TFFButtonManager.InheritFrom(Manager: TFFButtonManager);
var
   i: integer;
begin
     FButtons.Clear;
     for i:=0 to Manager.FButtons.Count - 1 do
         AddButtonObject(TFFButton(Manager.FButtons[i]));
     AdjustExpand;
     end;

procedure TFFButtonManager.AdjustExpand;
begin
     if Assigned(FNode) then begin
        FNode.Collapse(True);
        FNode.Expand(False);
        end;
     end;

procedure TFFButtonManager.AddButtonObject(FButton: TFFButton);
var
   Button: TFFButton;
begin
     Button := TFFButton.Create(FButton.FComponent, FButton.FCaption, FButton.FCategory);
     if Assigned(FNode) then Button.Attach(FNode);
     Button.FEnabled := FButton.FEnabled;
     Button.SetGroupIndex(FGroupIndex, FGroupSelIndex);
     Button.SetImageIndex(FEnabledIndex, FDisabledIndex);
     Button.FSync := FButton.FSync;
     Fbuttons.Add(Button);
     end;

procedure TFFButtonManager.UpdateButtons;
var
   i: integer;
begin
     for i:=0 to FButtons.Count - 1 do
         TFFButton(FButtons[i]).SyncForward;
     end;

procedure TFFButtonManager.UpdateButton(Caption: string; Enabled: boolean);
var
   i: integer;
begin
     for i:=0 to FButtons.Count - 1 do
         if CompareText(Caption, TFFButton(FButtons[i]).Category + '.' + TFFButton(FButtons[i]).Caption) = 0 then begin
            TFFButton(FButtons[i]).Enabled := Enabled;
            exit;
            end;
     end;

procedure TFFButtonManager.ReadRegistry;
var
   KeyVolumes: TStringList;
   i: integer;
begin
     KeyVolumes := TStringList.Create;
     GetKeyValues(HKEY_CURRENT_USER, regRootButtons, KeyVolumes);
     for i:=0 to KeyVolumes.Count - 1 do
         UpdateButton(KeyVolumes[i], QueryReg(HKEY_CURRENT_USER, regRootButtons, KeyVolumes[i]));
     KeyVolumes.Destroy;
     UpdateButtons;
     end;

procedure TFFButtonManager.WriteRegistry;
var
   i: integer;
begin
     DeleteKey(HKEY_CURRENT_USER, regRootButtons, '');
     for i:=0 to FButtons.Count - 1 do begin
         AddReg(HKEY_CURRENT_USER, regRootButtons, TFFButton(FButtons[i]).Category + '.' + TFFButton(FButtons[i]).Caption, TFFButton(FButtons[i]).Enabled);
         end;
     end;

procedure TFFButtonManager.Attach(Node: TTreeNode);
var
   i: integer;
begin
     FNode := Node;
     for i:=0 to FButtons.Count - 1 do
         TFFButton(FButtons[i]).Attach(Node);
     AdjustExpand;
     end;

procedure TFFButtonManager.ToggleEnabled(Button: TFFButton);
begin
     SetEnabled(Button, not Button.Enabled);
     end;

procedure TFFButtonManager.SetEnabled(Button: TFFButton; Value: boolean);
begin
     Button.Enabled := Value;
     Button.SetImageIndex(FEnableDIndex, FDisabledIndex);
     Button.SetGroupIndex(FGroupIndex, FGroupSelIndex);
     end;

procedure TFFButtonManager.UpdateIndex;
var
   i: integer;
begin
     if Assigned(fNode) then
     for i:=0 to FButtons.Count - 1 do begin
         TFFButton(FButtons[i]).SetImageIndex(FEnabledIndex, FDisabledIndex);
         TFFButton(FButtons[i]).SetGroupIndex(FGroupIndex, FGroupSelIndex);
         end;
     end;

procedure TFFButtonManager.SetEnabledIndex(Value: integer);
begin
     if Value <> FEnabledIndex then begin
        FEnabledIndex := Value;
        UpdateIndex;
        end;
     end;

procedure TFFButtonManager.SetDisabledIndex(Value: integer);
begin
     if Value <> FDisabledIndex then begin
        FDisabledIndex := Value;
        UpdateIndex;
        end;
     end;

procedure TFFButtonManager.AddButtonSync(Control: TObject; Caption, Category: string);
begin
     AddButton(Control, Caption, Category).FSync := True;
     end;

function TFFButtonManager.AddButton(Control: TObject; Caption, Category: string): TFFButton;
begin
     Result := TFFButton.Create(TwinControl(Control), Caption, Category);
     if Assigned(FNode) then Result.Attach(FNode);
     Result.SetImageIndex(FEnabledIndex, FDisabledIndex);
     Result.SetGroupIndex(FGroupIndex, FGroupSelIndex);
     Fbuttons.Add(Result);
     end;

constructor TFFButtonManager.Create;
begin
     FButtons := TList.Create;
     end;

destructor TFFButtonManager.Destroy;
begin
     FButtons.Destroy;
     end;

constructor TFFButton.Create(Component: TWinControl; Caption, Category: string);
begin
     FComponent := Component;
     FCaption := Caption;
     FEnabled := True;
     FSync := False;
     FCategory := Category;
     end;

constructor TFFButton.CreateSync(Component: TWinControl; Caption, Category: string);
begin
     Create(Component, Caption, Category);
     FSync:=True;
     end;

procedure TFFButton.SetEnabled(Value: boolean);
begin
     if Value <> FEnabled then FEnabled := Value;
     end;

procedure TFFButton.Attach(Node: TTreeNode);
begin
     FNode := Node.GetFirstChild;
     while FNode <> nil do begin
           if CompareText(FNode.Text, Category) = 0 then break;
           FNode := FNode.GetNextSibling;
           end;
     if FNode = nil then begin
        FNode := Node.Owner.AddChild(Node, Category);
        end;
     FNode := FNode.Owner.AddChild(FNode, Caption);
     with FNode do begin
         Data := Self;
         end;
     end;

procedure TFFButton.SetImageIndex(Enabled, Hidden: integer);
begin
     if Assigned(FNode) then begin
        if FEnabled then FNode.ImageIndex := Enabled else FNode.ImageIndex := Hidden;
        FNode.SelectedIndex := FNode.ImageIndex;
        end;
     end;

procedure TFFButton.SetGroupIndex(Normal, Selected: integer);
begin
     if Assigned(FNode) and Assigned(FNode.Parent) then begin
        FNode.Parent.ImageIndex := Normal;
        FNode.Parent.SelectedIndex := Selected;
        end;
     end;

procedure TFFButtonManager.CreateSetupNode(TreeView: TTreeView);
begin
     if not Assigned(fNode) then begin
        fNode := TreeView.Items.Add(nil, 'Buttons');
        fNode.ImageIndex := 9;
        fNode.SelectedIndex := 9;
        end else fNode.DeleteChildren;
     end;


end.
