unit FFDirListBox;

{$R-}

interface

uses Windows, Messages, SysUtils, Classes, Controls, Graphics, Forms,
     Menus, StdCtrls, Buttons, FFRoot, Dialogs, d32gen, FileCtrl, ExtManager;

type

  TItemStyle = (volume, folder, worddoc, undefined);

  TFFDirListBox = class(TCustomListBox)
  private
    FOpenLocked: integer;
    FExtManager: TExtManager;
    FRoot: TFFRoot;
    FCaseSensitive: Boolean;
    FPreserveCase: Boolean;
    FDirectory: string;
    FSubRoot: boolean;
    procedure ResetItemHeight;
    procedure BuildList;
    function  ReadDirectoryNames(const ParentDirectory: string; DirectoryList: TStringList): Integer;
    function ReadFileNames(const Ext: string; const ParentDirectory: string; DirectoryList: TStringList): Integer;
    procedure DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState); override;
  protected
    OpenedIndex: integer;
    FShowDocuments: boolean;
    LastIndex: integer;
    LastLevel: integer;
    ClosedBMP, OpenedBMP, CurrentBMP, VolumeBMP, WordDocBMP, VoidBMP: TBitmap;
    FOnChange: TNotifyEvent;
    FDocumentsCount : integer;
    FFoldersCount : integer;
    procedure Change; virtual;
    procedure ReadBitmaps; virtual;
    procedure DblClick; override;
    procedure Click; override;
    procedure KeyPress(var Key: Char); override;
    procedure SetExtManager(Value: TExtManager);
  public
    HaveKeyPressed: boolean;
    procedure SetDirectory(Value: string);
    function GetItemPath(Index: Integer): string;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetRoot(Root: TFFRoot);
    function  DisplayCase(const S: String): String;
    procedure OpenCurrent;
    property PreserveCase: Boolean read FPreserveCase;
    property CaseSensitive: Boolean read FCaseSensitive;
    property Directory: string read FDirectory write SetDirectory;
    function ItemStyle(Index: integer): TItemStyle;
    procedure KeyDown(var Key: word; ShiftState: TShiftState); override;
    procedure KeyUp(var Key: word; ShiftState: TShiftState); override;
    procedure SelectParent;
    procedure RefreshCurrent;
    function GetPath: string;
    procedure SelectCloser(Pattern: string);
    procedure SetShowDocuments(Value: boolean);
    function VirtualPath(Index: Integer): string;
    function RealPath(Index: Integer): string;
    function GetVirtualPath: string;
    function GetRealPath: string;
    procedure SetOpenLocked(Value: integer);
  published
    property OpenLocked: integer read FOpenLocked write SetOpenLocked;
    property SubRoot: boolean read FSubRoot;
    property VPath: string read GetVirtualPath;
    property Root: TFFRoot read FRoot;
    property ShowDocuments: boolean read FShowDocuments write SetShowDocuments;
    property DocumentsCount : integer read FDocumentsCount;
    property FoldersCount : integer read FFoldersCount;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Align;
    property Color;
    property Columns;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Font;
    property IntegralHeight;
    property ItemHeight;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property MultiSelect;
    property ExtManager: TExtManager read FExtManager write SetExtManager;
  end;

procedure Register;

implementation

{$R ffshell.res}

procedure Register;
begin
  RegisterComponents('Shell', [TFFDirListBox]);
  end;

function DirLevel(const PathName: string): Integer;  { counts '\' in path }
var
   P: PChar;
begin
     Result := 0;
     P := AnsiStrScan(PChar(PathName), '\');
     while P <> nil do begin
           Inc(Result);
           Inc(P);
           P := AnsiStrScan(P, '\');
           end;
     end;


function SlashSep(const Path, S: String): String;
begin
     if AnsiLastChar(Path)^ <> '\' then
     Result := Path + '\' + S
     else
     Result := Path + S;
     end;

function FontItemHeight(Font: TFont): Integer;
var
   DC: HDC;
   SaveFont: HFont;
   Metrics: TTextMetric;
begin
     DC := GetDC(0);
     SaveFont := SelectObject(DC, Font.Handle);
     GetTextMetrics(DC, Metrics);
     SelectObject(DC, SaveFont);
     ReleaseDC(0, DC);
     Result := Metrics.tmHeight;
     end;

constructor TFFDirListBox.Create(AOwner: TComponent);
begin
     inherited Create(AOwner);
     OpenedIndex := -1;
     FOpenLocked := 0;
     FShowDocuments := True;
     Width := 145;
     Style := lbOwnerDrawFixed;
     Sorted := False;
     ReadBitmaps;
     ResetItemHeight;
     end;

procedure TFFDirListBox.ResetItemHeight;
var
   nuHeight: Integer;
begin
     nuHeight :=  FontItemHeight(Font);
     if nuHeight < (OpenedBMP.Height + 1) then nuHeight := OpenedBmp.Height + 1;
     ItemHeight := nuHeight;
     end;

procedure TFFDirListBox.ReadBitmaps;
begin
     OpenedBMP := TBitmap.Create;
     OpenedBMP.LoadFromResourceName(HInstance, 'FOLDER_OPEN');
     ClosedBMP := TBitmap.Create;
     ClosedBMP.LoadFromResourceName(HInstance, 'FOLDER_CLOSED');
     CurrentBMP := TBitmap.Create;
     CurrentBMP.LoadFromResourceName(HInstance, 'FOLDER_OPEN');
     VolumeBMP := TBitmap.Create;
     VolumeBMP.LoadFromResourceName(HInstance, 'VOLUME');
     WordDocBMP := TBitmap.Create;
     WordDocBMP.LoadFromResourceName(HInstance, 'WORDDOC');
     VoidBMP := TBitmap.Create;
     VoidBMP.LoadFromResourceName(HInstance, 'VOIDBMP');
     end;

destructor TFFDirListBox.Destroy;
begin
     ClosedBMP.Free;
     OpenedBMP.Free;
     CurrentBMP.Free;
     VolumeBMP.Free;
     WordDocBMP.Free;
     VoidBMP.Free;
     inherited Destroy;
     end;

procedure TFFDirListBox.SetOpenLocked(Value: integer);
begin
     if Value <> FOpenLocked then begin
        FOpenLocked := Value;
        end;
     end;

procedure TFFDirListBox.SetRoot(Root: TFFRoot);
begin
     FRoot := Root;
     FDirectory := Root.Path;
     BuildList;
     end;

procedure TFFDirListBox.RefreshCurrent;
begin
     BuildList;
     end;

procedure TFFDirListBox.BuildList;
var
   TempPath: string;
   DirName: string;
   IndentLevel, BackSlashPos, i: Integer;
   MaxLen, VolFlags: DWORD;
   Siblings: TStringList;
   NewSelect: Integer;
   Root: String;
   LOnChange: TNotifyEvent;
begin
  LOnChange:=FOnChange;
  FOnChange := nil;
  try
    Items.BeginUpdate;
    Change;
    Items.Clear;
    OpenedIndex := ItemIndex;
    IndentLevel := 0;
    Root := bs(ExtractFileDrive(Directory));
    GetVolumeInformation(PChar(Root), nil, 0, nil, MaxLen, VolFlags, nil, 0);
    FPreserveCase := VolFlags and (FS_CASE_IS_PRESERVED or FS_CASE_SENSITIVE) <> 0;
    FCaseSensitive := (VolFlags and FS_CASE_SENSITIVE) <> 0;
    Items.AddObject(FRoot.Name, VolumeBMP);
    Inc(IndentLevel);
    TempPath := Copy(Directory, Length(bs(FRoot.Path))+1, Length(Directory));
    if (Length(TempPath) > 0) then begin
       if AnsiLastChar(TempPath)^ <> '\' then begin
          BackSlashPos := AnsiPos('\', TempPath);
          while BackSlashPos <> 0 do begin
                DirName := Copy(TempPath, 1, BackSlashPos - 1);
                if IndentLevel = 0 then DirName := DirName + '\';
                Delete(TempPath, 1, BackSlashPos);
                Items.AddObject(DirName, OpenedBMP);
                Inc(IndentLevel);
                BackSlashPos := AnsiPos('\', TempPath);
                end;
          end;
       Items.AddObject(TempPath, CurrentBMP);
       end;
    NewSelect := Items.Count - 1;
    Siblings := TStringList.Create;
    try
      Siblings.Sorted := True;
      FSubRoot := True;
      FDocumentsCount := 0;
      FFoldersCount := 0;
      FFoldersCount := ReadDirectoryNames(Directory, Siblings);
      LastLevel := Items.Count;
      if (FFoldersCount = 0) then begin
         LastIndex := Items.Count;
         FSubRoot := False;
         if FShowDocuments then begin
            if Assigned(ExtManager) then begin
               for i:=0 to ExtManager.Count-1 do
                   FDocumentsCount := FDocumentsCount + ReadFileNames(ExtManager.Get(i), Directory, Siblings);
               end else FDocumentsCount := ReadFileNames('*.doc', Directory, Siblings);
            if FDocumentsCount = 0 then Items.AddObject('(no documents found)', VoidBMP)
            else for i := 0 to Siblings.Count - 1 do
             Items.AddObject(Siblings[i], WordDOCBMP);
            end;
         end else begin
         LastIndex := -1;
         for i := 0 to Siblings.Count - 1 do
             Items.AddObject(Siblings[i], ClosedBMP);
         end;

    finally
      Siblings.Free;
    end;
  finally
  Items.EndUpdate;
  end;
  if HandleAllocated then ItemIndex := NewSelect;
  FOnChange:=LOnChange;
  end;

function TFFDirListBox.ReadFileNames(const Ext: string; const ParentDirectory: string; DirectoryList: TStringList): Integer;
var
   Status: Integer;
   SearchRec: TSearchRec;
begin
     Result := 0;
     Status := FindFirst(SlashSep(ParentDirectory, Ext), faReadOnly+faHidden, SearchRec);
     try
     while Status = 0 do begin
           if (SearchRec.Attr and faDirectory <> faDirectory) then begin
              DirectoryList.Add(Copy(SearchRec.Name, 0, Length(SearchRec.Name) - Length(Ext) + 1));
              Inc(Result);
              end;
           Status := FindNext(SearchRec);
           end;
     finally
         FindClose(SearchRec);
     end;
     end;

function TFFDirListBox.ReadDirectoryNames(const ParentDirectory: string; DirectoryList: TStringList): Integer;
var
   Status: Integer;
   SearchRec: TSearchRec;
begin
     Result := 0;
     Status := FindFirst(SlashSep(ParentDirectory, '*.*'), faDirectory, SearchRec);
     try
     while Status = 0 do begin
           if (SearchRec.Attr and faDirectory = faDirectory) then begin
              if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') and (SearchRec.Name[1] <> '$') then begin
                 DirectoryList.Add(SearchRec.Name);
                 Inc(Result);
                 end;
              end;
           Status := FindNext(SearchRec);
           end;
     finally
        FindClose(SearchRec);
     end;
     end;


procedure TFFDirListBox.DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
   Bitmap: TBitmap;
   bmpWidth: Integer;
   dirOffset: Integer;
begin
     with Canvas do begin
          FillRect(Rect);
          bmpWidth  := 16;
          if (LastIndex <> -1) and (Index > LastIndex) then
             dirOffset := LastIndex * 4 + 2
             else dirOffset := Index * 4 + 2;
          Bitmap := TBitmap(Items.Objects[Index]);
          if Bitmap <> nil then begin
             if Bitmap = ClosedBMP then dirOffset := (DirLevel(Directory) + 1) * 4 + 2;
             bmpWidth := Bitmap.Width;
             BrushCopy(Bounds(Rect.Left + dirOffset,
             (Rect.Top + Rect.Bottom - Bitmap.Height) div 2,
             Bitmap.Width, Bitmap.Height),
             Bitmap, Bounds(0, 0, Bitmap.Width, Bitmap.Height),
             Bitmap.Canvas.Pixels[0, Bitmap.Height - 1]);
             end;
          TextOut(Rect.Left + bmpWidth + dirOffset + 4, Rect.Top, DisplayCase(Items[Index]))
          end;
     end;

function TFFDirListBox.DisplayCase(const S: String): String;
begin
     if FPreserveCase or FCaseSensitive then Result := S else Result := AnsiLowerCase(S);
     end;

procedure TFFDirListBox.Change;
begin
     if Assigned(FOnChange) then FOnChange(Self);
     end;

procedure TFFDirListBox.DblClick;
begin
     inherited DblClick;
     OpenCurrent;
     Change;     
     end;

procedure TFFDirListBox.KeyPress(var Key: Char);
begin
     //inherited KeyPress(Key);
     if Assigned(OnKeyPress) then OnKeyPress(Self, Key);
     if (Word(Key) = VK_RETURN) then OpenCurrent;
     end;

procedure TFFDirListBox.OpenCurrent;
var
   NewFdirectory: string;
begin
     if not (ItemStyle(ItemIndex) in [undefined, worddoc]) then begin
        NewFDirectory := GetItemPath(ItemIndex);
        if (FDirectory <> NewFDirectory) then begin
           FDirectory := NewFDirectory;
           BuildList;
           end;
        end;
     end;

procedure TFFDirListBox.Click;
begin
     Change;
     if not HaveKeyPressed and (ItemIndex >= 0) and (ItemStyle(ItemIndex) <> worddoc) then
        DblClick;
     end;

function TFFDirListBox.GetItemPath (Index: Integer): string;
var
   i: Integer;
begin
     Result := FRoot.Path;
     i:=1;
     while(i <= Index) do begin
        if Directory = Result then begin
           Result := bs(Result) + Items[Index];
           exit;
           end else begin
           Result := bs(Result) + Items[i];
           inc(i);
           end;
        end;
     end;

function TFFDirListBox.VirtualPath(Index: Integer): string;
begin
     Result := GetItemPath(Index);
     Result := Copy(Result, Length(FRoot.Path)+1, Length(Result));
     end;

function TFFDirListBox.RealPath(Index: Integer): string;
begin
     Result := GetItemPath(Index);
     end;
     
function TFFDirListBox.ItemStyle(Index: integer): TItemStyle;
begin
     if Index = -1 then Result := undefined
     else if Items.Objects[Index] = WordDocBMP then Result := worddoc
     else if Items.Objects[Index] = VolumeBMP then Result := volume
     else if Items.Objects[Index] = VoidBmp then Result := undefined
     else Result := folder;
     end;

procedure TFFDirListBox.KeyDown(var Key: word; ShiftState: TShiftState);
begin
     Application.ProcessMessages; // processing main form KeyDown
     if Assigned(OnKeyDown) then OnKeyDown(Self, Key, ShiftState);
     if (not (ssShift in ShiftState)) and
        (not (ssCtrl in ShiftState)) and
        (not (ssAlt in ShiftState)) then
     case Key of
          13, 10:           begin
                            HaveKeyPressed := False;
                            if (OpenLocked = 0) then OpenCurrent else OpenLocked := OpenLocked - 1;
                            end;
          {37:               begin
                            SelectParent;
                            end;}
          {39:               begin
                            OpenCurrent;
                            Key := 0;
                            end;}
          else              begin
                            HaveKeyPressed := True;
                            end;
          end;

     end;

procedure TFFDirListBox.SelectParent;
var
   i: Integer;
   tStr: string;
begin
     tStr := FRoot.Path;
     i:=1;
     while(i <= ItemIndex) do begin
        if Directory = tStr then begin
           ItemIndex := i-1;
           exit;
           end else begin
           tStr := bs(tStr) + Items[i];
           inc(i);
           end;
        end;
     end;

procedure TFFDirListBox.KeyUp(var Key: word; ShiftState: TShiftState);
begin
     //HaveKeyPressed := False;
     //inherited;
     if Assigned(OnKeyUp) then OnKeyUp(Self, Key, ShiftState);
     end;

function TFFDirListBox.GetPath: string;
begin
     Result := Directory;
     end;

procedure TFFDirListBox.SelectCloser(Pattern: string);
          function Min(First, Second: integer): integeR;
          begin
               if First > Second then Result := Second else Result := First;
               end;
          function Matching(First, Second: string): integer;
          begin
               for Result:=1 to Min(Length(First), Length(Second)) do
                   if UpCase(First[Result]) <> UpCase(Second[Result]) then begin
                      exit;
                      end;
               Result := Min(Length(First), Length(Second))+1;
               end;

var
   i: integer;
   MinLen, CurLen, Current: integer;
begin
     MinLen := 0;
     Current := ItemIndex;
     for i:=Items.Count - 1 downto 0 do begin
         CurLen := Matching(Pattern, Items[i])-1;
         if CurLen >= MinLen then begin
            MinLen := CurLen;
            Current := i;
            end;
         end;
     if MinLen = 0 then SelectParent else
     if ItemIndex <> Current then begin
        ItemIndex := Current;
        Change;
        end;   
     end;

procedure TFFDirListBox.SetShowDocuments(Value: boolean);
begin
     if Value <> FShowDocuments then begin
        FShowDocuments := Value;
        end;
     end;

procedure TFFDirListBox.SetDirectory(Value: string);
begin
     if FDirectory <> Value then begin
        if DirectoryExists(Value) and (CompareText(Root.Path, Copy(Directory, 1, Length(Root.Path))) = 0) then begin
           FDirectory := Value;
           BuildList;
           end;
        end;
     end;

function TFFdirListBox.GetVirtualPath: string;
begin
     if (ItemIndex >= LastLevel) and (ItemStyle(ItemIndex) <> folder) then Result := VirtualPath(LastLevel-1)
     else Result := VirtualPath(ItemIndex);
     end;

function TFFDirListBox.GetRealPath: string;
begin
     if (ItemIndex >= LastLevel) and (ItemStyle(ItemIndex) <> folder) then Result := RealPath(LastLevel-1)
     else Result := RealPath(ItemIndex);
     end;

procedure TFFDirListBox.SetExtManager(Value: TExtManager);
begin
     if FExtManager <> Value then begin
        FExtManager := Value;
        end;
     end;


end.
