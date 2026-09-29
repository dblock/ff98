program folder;

uses
  Forms,
  ff98 in 'ff98.pas' {FFMain},
  FFRoot in 'FFRoot.pas',
  FFSetup in 'FFSetup.pas' {FFSet},
  VVManager in 'VVManager.pas',
  FFCommon in 'FFCommon.pas',
  d32gen in '..\common.d32\d32gen.pas',
  d32reg in '..\common.d32\d32reg.pas',
  ffInit in 'ffInit.pas' {InitForm},
  ffbutton in 'ffbutton.pas',
  FFSelect in 'FFSelect.pas' {ffSel},
  ffProperties in 'ffProperties.pas' {FFProp},
  ffOlePreview in 'ffOlePreview.pas' {FFPreview},
  SysUtils,
  ExtManager in 'ExtManager.pas',
  FFMessage in 'FFMessage.pas' {FFMessageBox},
  ffDocPreview in 'ffDocPreview.pas' {FFTxtPreview};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'File & Folder 98';
  Application.CreateForm(TFFMain, FFMain);
  Application.CreateForm(TFFSet, FFSet);
  Application.CreateForm(TffSel, ffSel);
  Application.CreateForm(TFFProp, FFProp);
  Application.CreateForm(TFFPreview, FFPreview);
  Application.CreateForm(TFFMessageBox, FFMessageBox);
  Application.CreateForm(TFFTxtPreview, FFTxtPreview);
  Application.Run;
end.
