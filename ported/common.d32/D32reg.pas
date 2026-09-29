unit d32reg;

interface

uses Windows, Classes, Registry, d32gen, d32debug, SysUtils, Dialogs, Variants;

   procedure GetKeyValues(RegSection: HKey; RegMain: string; List: TStringList);
   function QueryReg(RegSection: HKey; RegMain, RegKey : String): Variant;
   function QueryRegExt(RegSection: HKey; RegMain, RegKey : String; var DataType: integer): Variant;
   procedure AddReg(RegSection: HKey; RegMain, RegKey : string; const RegValue : Variant);
   procedure AddKey(RegSection: Hkey; RegMain, RegKey: string);
   procedure DeleteKey(RegSection: HKey; RegMain, RegKey : string);
   procedure DeleteValue(RegSection: HKey; RegMain, RegKey : string);
   procedure CopyRegKey(SRegSection: HKey; SRegMain, SRegKey : String; TRegSection: HKey; TRegMain, TRegKey : String);
   function GetKeyNames(RegSection: Hkey; RegKey: string; iStrings: TStrings): TStrings;
   function HasSubKeys(RegSection: HKEY; RegMain, RegKey: string): boolean;
   function HasSubKeysHKEY(RegHKEY: HKEY; Info: TRegKeyInfo): boolean;
   function QueryRegExtHKEY(RegHKEY:HKEY; RegKey: string; var DataType: integer; Info: TRegKeyInfo; var ExportData: Variant; var DataSize: integer): Variant;
   function OpenKeyExt(RegSection: HKEY; RegMain: string): HKEY;
   procedure GetKeyValuesHKEY(RegHKEY: HKey; Info: TRegKeyInfo; List: TStringList);
   procedure GetKeyNamesHKEY(RegHKEY: Hkey; Info: TRegKeyInfo; iStrings: TStrings);

const
     FDeleted : string = '(deleted)';
     FAdded : string = '(added)';
     FModified : string = '(modified)';

implementation

uses d32errors;

function HasSubKeysHKEY(RegHKEY: HKEY; Info: TRegKeyInfo): boolean;
begin
     Result := (Info.NumSubKeys > 0);
     end;

function HasSubKeys(RegSection: HKEY; RegMain, RegKey: string): boolean;
var
   lpcSubKeys: integer;
   RegHKEY: HKEY;
begin
     Result := False;
     if ((RegMain <> '') and (RegMain[1] = '\')) then Delete(RegMain, 1, 1);
     if RegOpenKeyEx(RegSection, PChar(RegMain+RegKey), 0, KEY_EXECUTE, RegHKEY) = ERROR_SUCCESS then begin
        if RegQueryInfoKey(RegHKEY, nil,nil,nil,@lpcSubKeys, nil,nil,nil,nil,nil,nil,nil) = ERROR_SUCCESS then begin
           Result := (lpcSubKeys > 0);
           end;
        end;
   end;

function OpenKeyExt(RegSection: HKEY; RegMain: string): HKEY;
begin
     if ((Length(RegMain) > 0) and (RegMain[1] = '\')) then Delete(RegMain, 1, 1);
     if ((Length(RegMain) > 0) and (RegMain[Length(RegMain)] = '\')) then Delete(RegMain, Length(RegMain), 1);
     RegOpenKeyEx(RegSection, PChar(RegMain), 0, KEY_EXECUTE, Result);
     end;

function QueryRegExt(RegSection: HKey; RegMain, RegKey : String; var DataType: integer): Variant;
var
   RegHKEY: HKEY;
   Info: TRegKeyInfo;
   DataSize: integer;
begin
     RegHKEY := OpenKeyExt(RegSection, RegMain);
     FillChar(Info, SizeOf(TRegKeyInfo), 0);
     RegQueryInfoKey(RegHKEY, nil, nil, nil, @Info.NumSubKeys,
        @Info.MaxSubKeyLen, nil, @Info.NumValues, @Info.MaxValueLen,
        @Info.MaxDataLen, nil, @Info.FileTime);
     Result := QueryRegExtHKEY(RegHKEY, RegKey, DataType, Info, Result, DataSize);
     end;

function QueryRegExtHKEY(RegHKEY: HKEY; RegKey: string; var DataType: integer; Info: TRegKeyInfo; var ExportData: Variant; var DataSize: integer): Variant;
         function ToHex(i: integer): char;
         begin
              if i>9 then Result:=Chr(i+Ord('a')-10) else Result:=Chr(i+Ord('0'));
              end;
var
   SecondBuffer, Buffer : PByte;
   Res: integer;

   function ReadBinaryData: string;
   var
      i: integer;
   begin
        Result := '';
        if DataSize = 0 then begin
           Result := '(zero length binary value)';
           ExportData := '';
           exit;
           end;
        Buffer := AllocMem(DataSize);
        if RegQueryValueEx(RegHKEY, PChar(RegKey), nil, @Res, Buffer, @DataSize) = ERROR_SUCCESS then begin
           SecondBuffer := PByte(StrAlloc(DataSize * 3));
           for i:=0 to DataSize - 1 do begin
               PChar(SecondBuffer)[3*i] := ToHex(Ord(PChar(Buffer)[i]) div 16);
               PChar(SecondBuffer)[3*i+1] := ToHex(Ord(PChar(Buffer)[i]) mod 16);
               PChar(SecondBuffer)[3*i+2] := ' ';
               end;
           PChar(SecondBuffer)[(DataSize)*3-1] := Chr(0);
           Result := StrPas(PChar(SecondBuffer));
           for i:=0 to DataSize - 1 do begin
               PChar(SecondBuffer)[3*i+2] := ',';
               end;
           PChar(SecondBuffer)[(DataSize)*3-1] := Chr(0);
           ExportData := StrPas(PChar(SecondBuffer));
           StrDispose(PChar(SecondBuffer));
           end else Result := '(error reading binary data)';
        FreeMem(Buffer);
        end;

   function ReadIntData: integer;
   begin
        RegQueryValueEx(RegHKEY, PChar(RegKey), nil, @DataType, @Res, @DataSize);
        Result := Res;
        ExportData := Result;
        end;

   function ReadSZData: string;
   begin
        Buffer := PByte(StrAlloc(DataSize));
        RegQueryValueEx(RegHKEY, PChar(RegKey), nil, @DataType, PByte(Buffer), @DataSize);
        Result := StrPas(PChar(Buffer));
        ExportData := Result;
        StrDispose(PChar(Buffer));
        end;

   function ReadSZExpandData: string;
   begin
        Buffer := PByte(StrAlloc(DataSize));
        RegQueryValueEx(RegHKEY, PChar(RegKey), nil, @DataType, PByte(Buffer), @DataSize);
        Res := ExpandEnvironmentStrings(PChar(Buffer), nil, 0);
        Result := StrPas(PCHar(Buffer));
        if (Res > 0) then begin
           SecondBuffer := PByte(StrAlloc(Res));
           ExpandEnvironmentStrings(PChar(Buffer), PChar(SecondBuffer), Res);
           Result := '"'+ StrPas(PChar(SecondBuffer)) + '" (' + Result + ')';
           StrDispose(PChar(SecondBuffer));
           end;
        StrDispose(PChar(Buffer));
        ReadBinaryData;        
        end;

begin
     if RegQueryValueEx(RegHKEY, PChar(RegKey), nil, @DataType, nil, @DataSize) = ERROR_SUCCESS then begin
            case DataType of
             REG_DWORD_BIG_ENDIAN: Result := Swap(ReadIntData);
             REG_DWORD:            Result := ReadIntData;
             REG_SZ:               Result := ReadSZData;
             REG_LINK, REG_NONE, REG_RESOURCE_LIST, REG_BINARY:
                       Result := ReadBinaryData;
             REG_EXPAND_SZ: Result := ReadSZExpandData;
             else Result := ReadBinaryData;
             end;
        end;
   end;

function QueryReg(RegSection: HKey; RegMain, RegKey : String): Variant;
var
   Reg: TRegistry;
   DataType: TRegDataType;
begin
   Reg := TRegistry.Create;
   try
      {$ifdef Debug} DebugForm.Debug('tReg::quering registry for '+Bs(RegMain)+RegKey); {$endif}
      Reg.RootKey :=RegSection;
      if not Reg.OpenKey(nBs(RegMain), False) then begin
           QueryReg:=-1;
           {$ifdef Debug} DebugForm.Debug('tReg::reported failure.'); {$endif}
           end else begin
           {$ifdef Debug} DebugForm.Debug('tReg::reported data.'); {$endif}
            DataType := Reg.GetDataType(RegKey);
            case DataType of
             rdinteger:
                       begin
                       try
                       QueryReg := Reg.ReadInteger(RegKey);
                       except
                       QueryReg := 0;
                       end;
                       {$IFDEF Debug}DebugForm.Debug('TReg::Data:'+IntToStr(Result));{$ENDIF}
                       end;
             rdstring: begin
                       try
                       QueryReg := Reg.ReadString(RegKey);
                       except
                       QueryReg := '';
                       end;
                       {$IFDEF Debug}DebugForm.Debug('TReg::Data:'+Result);{$ENDIF}
                       end;
             rdbinary: begin
                       Result := '(binary data)';
                       {$IFDEF Debug}DebugForm.Debug('TReg::Data: binary.');{$ENDIF}
                       end;
             rdexpandstring:
                       begin
                       try
                       QueryReg:=Reg.ReadString(RegKey);
                       except
                       QueryReg:='';
                       end;
                       {$IFDEF Debug}DebugForm.Debug('TReg::Data:'+Result);{$ENDIF}
                       end;
             else begin
                {$ifdef Debug} DebugForm.Debug('tReg::unsupported reg data type.'); {$endif}
                QueryReg:=-1;
                end;
             end;
             {$ifdef Debug} DebugForm.Debug('tReg::reported successful.'); {$endif}
            end;
   finally
   Reg.Free;
   {$ifdef Debug} DebugForm.Debug('tReg::reg object disposed.'); {$endif}
   end;
   end;

procedure CopyRegKey(SRegSection: HKey; SRegMain, SRegKey : String;
                     TRegSection: HKey; TRegMain, TRegKey : String);
begin
   AddReg(TRegSection, TRegMain, TRegKey, QueryReg(SRegSection, SRegMain, SRegKey));
   end;

procedure DeleteKey(RegSection: HKey; RegMain, RegKey : string);
var
   Reg: Tregistry;
   iList: TStringList;
   i: integer;
begin
   Reg := TRegistry.Create;
   try
     Reg.RootKey := RegSection;
     if Reg.OpenKey(RegMain, False) then begin

        if RegKey <> '' then begin
           Reg.DeleteValue(RegKey);
           end else begin
           iList := TStringList.Create;
           if Reg.HasSubKeys and (RegKey = '') then begin
              GetKeyNames(RegSection, BS(RegMain) + RegKey,iList);
              for i:=0 to ilist.Count - 1 do DeleteKey(RegSection, BS(RegMain) + RegKey, iList[i]);
              end;
           iList.Clear;
           GetKeyValues(RegSection, RegMain, iList);
           for i:=0 to iList.Count - 1 do begin
               Reg.DeleteValue(iList[i]);
               end;
           iList.Destroy;
           RegDeleteKey(HKEY_CURRENT_USER, PChar(BS(RegMain) + RegKey));
           end;

        end;
   finally
   Reg.Free;                                                                     {$ifdef Debug} DebugForm.Debug('tReg::reg object disposed.'); {$endif}
   end;
   end;

procedure GetKeyValuesHKEY(RegHKEY: HKey; Info: TRegKeyInfo; List: TStringList);
var
  I, Len: Integer;
  S: string;
begin
    SetString(S, nil, Info.MaxValueLen + 1);
    for I := 0 to Info.NumValues - 1 do begin
      Len := Info.MaxValueLen + 1;
      if RegEnumValue(RegHKEY, I, PChar(S), LPDWORD(@Len)^, nil, nil, nil, nil) = ERROR_SUCCESS then
         List.Add(PChar(S));
    end;
end;

procedure GetKeyValues(RegSection: HKey; RegMain: string; List: TStringList);
var
   Reg: Tregistry;
begin
   Reg := TRegistry.Create;
   try
     Reg.RootKey := RegSection;
     if Reg.OpenKey(RegMain, False) then Reg.GetValueNames(List);
   finally
   Reg.Free;
   end;
   end;


procedure DeleteValue(RegSection: HKey; RegMain, RegKey : string);
var
   Reg: Tregistry;
begin
   Reg := TRegistry.Create;
   try
     Reg.RootKey := RegSection;
     if Reg.OpenKey(RegMain, False) then begin
        Reg.DeleteValue(BS(RegMain) + RegKey);
        end;
   finally
   Reg.Free;                                                                     {$ifdef Debug} DebugForm.Debug('tReg::reg object disposed.'); {$endif}
   end;
   end;

procedure GetKeyNamesHKEY(RegHKEY: Hkey; Info: TRegKeyInfo; iStrings: TStrings);
var
   I, Len: Integer;
   S: string;
begin
        SetString(S, nil, Info.MaxSubKeyLen + 1);
        for I := 0 to Info.NumSubKeys - 1 do begin
            Len := Info.MaxSubKeyLen + 1;
            if RegEnumKeyEx(RegHKEY, I, PChar(S), LPDWORD(@Len)^, nil, nil, nil, nil) = ERROR_SUCCESS then
               iStrings.Add(PChar(S));
            end;
     end;

function GetKeyNames(RegSection: Hkey; RegKey: string; iStrings: TStrings): TStrings;
var
   Reg: TRegistry;
   I, Len: Integer;
   Info: TRegKeyInfo;
   S: string;
begin
     Reg:=TRegistry.Create;
     try
     Reg.RootKey :=RegSection;
     if Reg.OpenKey(RegKey, FALSE) then
     if Reg.GetKeyInfo(Info) then begin
        SetString(S, nil, Info.MaxSubKeyLen + 1);
        for I := 0 to Info.NumSubKeys - 1 do begin
            Len := Info.MaxSubKeyLen + 1;
            if RegEnumKeyEx(Reg.CurrentKey, I, PChar(S), LPDWORD(@Len)^, nil, nil, nil, nil) = ERROR_SUCCESS then
               iStrings.Add(PChar(S));
            end;
        end;

     finally
     Result:=iStrings;
     Reg.Free;
     {$ifdef Debug} DebugForm.Debug('tReg::reg object disposed.'); {$endif}
     end;
     end;


procedure AddKey(RegSection: Hkey; RegMain, RegKey: string);
var
   Reg: Tregistry;
begin
   Reg := TRegistry.Create;
   try
     Reg.RootKey :=RegSection;
     Reg.OpenKey(RegMain, TRUE);
     Reg.CreateKey(RegKey);
   finally
     Reg.Free;
     {$ifdef Debug} DebugForm.Debug('tReg::reg object disposed.'); {$endif}
   end;
   end;

procedure AddReg(RegSection: HKey; RegMain, RegKey : string; const RegValue : Variant);
var
   Reg: Tregistry;
begin
   {$ifdef Debug}DebugForm.Debug('Creating reg object: '+RegMain+Bs(RegKey)+String(RegValue)); {$endif}
   Reg := TRegistry.Create;
   try
      Reg.RootKey :=RegSection;
      Reg.OpenKey(RegMain, TRUE);

   case VarType(RegValue) of
(*      varEmpty,
      varNull:*)
      varInteger,
      varSingle,
      varDouble,
      varByte,
      VarSmallInt: Reg.WriteInteger(RegKey,RegValue);
(*      varCurrency:
      varDate:
      varOleStr:
      varDispatch:
      varError:      *)
      varBoolean: Reg.WriteBool(RegKey,RegValue);
(*      varVariant:
      varUnknown: *)
      varString: Reg.WriteString(RegKey,RegValue);
(*      varTypeMask:
      varArray:
      varByRef: *)
      else
       {$ifdef Debug} DebugForm.Debug('tReg::variant object not written!'); {$endif}
      end;
      {$ifdef Debug} DebugForm.Debug('tReg::reg reported successful.'); {$endif}
   finally
      Reg.Free;
      {$ifdef Debug} DebugForm.Debug('tReg::reg object disposed.'); {$endif}
   end;
   end;

end.
