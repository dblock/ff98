program folder;

uses
  {$IFDEF FF98DEBUG}SysUtils,{$ENDIF}
  Interfaces,
  Forms,
  ff98 in 'ff98.pas' {FFMain},
  FFRoot in 'FFRoot.pas',
  FFSetup in 'FFSetup.pas' {FFSet},
  VVManager in 'VVManager.pas',
  FFCommon in 'FFCommon.pas',
  d32gen,
  d32reg,
  ffInit in 'ffInit.pas' {InitForm},
  ffbutton in 'ffbutton.pas',
  FFSelect in 'FFSelect.pas' {ffSel},
  ffProperties in 'ffProperties.pas' {FFProp},
  ffOlePreview in 'ffOlePreview.pas' {FFPreview},
  ExtManager in 'ExtManager.pas',
  FFMessage in 'FFMessage.pas' {FFMessageBox},
  ffDocPreview in 'ffDocPreview.pas' {FFTxtPreview};

{$R folder.res}

{$IFDEF FF98DEBUG}
type
  TDebugHandler = class
    procedure OnException(Sender: TObject; E: Exception);
  end;

procedure TDebugHandler.OnException(Sender: TObject; E: Exception);
begin
  WriteLn(ErrOutput, E.ClassName, ': ', E.Message);
  DumpExceptionBackTrace(ErrOutput);
  Application.ShowException(E);
end;
{$ENDIF}

begin
  {$IFDEF FF98DEBUG}
  try
  {$ENDIF}
  Application.Initialize;
  {$IFDEF FF98DEBUG}
  Application.OnException := TDebugHandler.Create.OnException;
  {$ENDIF}
  Application.Title := 'File & Folder 98';
  // The expiry check in TFFMain.FormCreate may show a message, so create the
  // message box first, without making it the main form.
  FFMessageBox := TFFMessageBox.Create(Application);
  Application.CreateForm(TFFMain, FFMain);
  Application.CreateForm(TFFSet, FFSet);
  Application.CreateForm(TffSel, ffSel);
  Application.CreateForm(TFFProp, FFProp);
  Application.CreateForm(TFFPreview, FFPreview);
  Application.CreateForm(TFFTxtPreview, FFTxtPreview);
  Application.Run;
  {$IFDEF FF98DEBUG}
  except
    on E: Exception do begin
      WriteLn(ErrOutput, E.ClassName, ': ', E.Message);
      DumpExceptionBackTrace(ErrOutput);
    end;
  end;
  {$ENDIF}
end.
