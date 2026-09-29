unit FFRoot;

interface

uses Classes, Menus, Forms, d32gen, Dialogs, ShellApi, Sysutils, Windows;

type
    TFFRoot = class
    private
       FPath: String;
       FName: String;
       FRecent: TStringList;
       procedure SetPath(Value: string);
       procedure SetName(Value: string);
       function AppendExt(Name, Ext: string): string;
       function RemoveExt(Name, Ext: string): string;
    public
       constructor Create(cName, cPath: String);
       constructor CreateClone(FRoot: TFFRoot);
       procedure AddToRecent(FullPath: string);
       destructor Destroy; override;
       procedure RecentToMenu(Menu: TMenu);
       procedure RecentSelect(Sender: TObject);
       procedure WriteRegistry;
       procedure ReadRegistry;
    published
       property Path: string read FPath write SetPath;
       property Name: string read FName write SetName;
       property Recent: TStringList read FRecent;

       end;

implementation

uses FFCommon, d32reg, FFMessage, ff98;

procedure TFFRoot.WriteRegistry;
var
   i: integer;
begin
     DeleteKey(HKEY_CURRENT_USER, regRootVolumes+'\Recent\'+Name, '');
     for i:=0 to FRecent.Count - 1 do
         AddReg(HKEY_CURRENT_USER, regRootVolumes+'\Recent\'+Name,IntToStr(i),FRecent[i]);
     end;

procedure TFFRoot.ReadRegistry;
var
   KeyVolumes: TStringList;
   i: integer;
begin
     KeyVolumes := TStringList.Create;
     GetKeyValues(HKEY_CURRENT_USER, regRootVolumes+'\Recent\'+Name, KeyVolumes);
     for i:=0 to KeyVolumes.Count - 1 do
         FRecent.Add(QueryReg(HKEY_CURRENT_USER, regRootVolumes+'\Recent\'+Name, IntToStr(i)));
     KeyVolumes.Destroy;
     end;

procedure TFFRoot.RecentSelect(Sender: TObject);
var
   CurrentDoc: string;
begin
     if (Sender is TMenuItem) then begin
        CurrentDoc := AppendExt(FRecent[(Sender as TMenuItem).Tag], '.doc');
        if FileExists(CurrentDoc) then begin
           FFMain.docOpenCopyAs(CurrentDoc);
           end else begin
                FFMessageBox.MessageDlg('Sorry, unable to find ' + CurrentDoc + ', it might have been renamed, deleted or moved.', mtError, [mbOk], 0);
                (Sender as TMenuItem).Parent.Remove(TMenuItem(Sender));
                FRecent.Delete((Sender as TMenuItem).Tag);
                end;
        end;
     end;

procedure TFFRoot.RecentToMenu(Menu: TMenu);
var
   NewMenuItem: TMenuItem;
   i: integer;
begin
     while Menu.Items.Count > 0 do Menu.Items.Remove(Menu.Items[0]);
     for i:=0 to FRecent.Count - 1 do begin
         NewMenuItem := TMenuItem.Create(Application.Mainform);
         with NewMenuItem do begin
              Tag := i;
              Caption := RemoveExt(Name + Copy(FRecent[i], Length(bs(FPath))+1, LEngth(FRecent[i])), '.doc');
              OnClick := RecentSelect;
              end;
         Menu.Items.Add(NewMenuItem);
         end;
     end;

procedure TFFRoot.AddToRecent(FullPath: string);
var
   iStr: string;
begin
     iStr:=RemoveExt(FullPath, '.doc');
     if FRecent.IndexOf(iStr) = -1 then begin
        if FRecent.Count >= 10 then FRecent.Delete(0);
        FRecent.Add(iStr);
        end;
     end;

constructor TFFroot.CreateClone(FRoot: TFFRoot);
begin
     FPath := FRoot.FPath;
     FName := FRoot.FName;
     FRecent := FRoot.FRecent;
     end;

destructor TFFRoot.Destroy;
begin
     FRecent.Destroy;
     inherited;
     end;

procedure TFFRoot.SetPath(Value: string);
begin
     if FPath <> Value then FPath := Value;
     end;

procedure TFFRoot.SetName(Value: string);
begin
     if FName <> Value then FName := Value;
     end;

constructor TFFRoot.Create(cName, cPath: String);
begin
     FPath := cPath;
     FName := cName;
     FRecent := TStringList.Create;
     ReadRegistry;
     end;

function TFFRoot.AppendExt(Name, Ext: string): string;
begin
     if ExtractFileExt(Name) <> Ext then Result := Name + Ext else Result := Name;
     end;

function TFFRoot.RemoveExt(Name, Ext: string): string;
begin
     if ExtractFileExt(Name) = Ext then Result := Copy(Name, 0, Length(Name) - Length(Ext)) else Result := Name;
     end;


end.
