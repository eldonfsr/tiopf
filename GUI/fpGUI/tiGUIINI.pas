{
    This file is part of the tiOPF project.

    See the file license.txt, included in this distribution,
    for details about redistributing tiOPF.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    Description:
      This file contains some helper functions for use with the fpGUI
      Toolkit. Here we extended the INI support to save and restore the
      size and state of application forms.
}
unit tiGUIINI;

{$mode objfpc}{$H+}

interface
uses
  tiINI
  ,fpg_form
  ;

type

  TtiGuiINIFile = class(TtiINIFile)
  public
    procedure   ReadFormState(AForm: TfpgForm; AHeight: integer = -1; AWidth: integer = -1);
    procedure   WriteFormState(AForm : TfpgForm);
  end;

function gGUIINI(const AFileName: string = ''): TtiGuiINIFile;


implementation
uses
  fpg_main
  ,fpg_base
  ,tiUtils
  ;

var
  uGuiINI : TtiGuiINIFile;


function gGUIINI(const AFileName: string = ''): TtiGuiINIFile;
begin
  if uGuiINI = nil then
  begin
    uGuiINI := TtiGuiINIFile.CreateExt(AFileName);
    uGuiINI.CacheUpdates := False;
  end;
  result := uGuiINI;
end;

procedure TtiGuiINIFile.ReadFormState(AForm: TfpgForm; AHeight : integer = -1; AWidth : integer = -1);
var
  LINISection: string;
  LTop: integer;
  LLeft: integer;
  LHeight: integer;
  LWidth: integer;
begin
  Assert(AForm <> nil, 'AForm not assigned');
  LINISection := AForm.Name + 'State';
  // Read form position, -1 indicates that it was not stored before
  LTop := readInteger(LINISection, 'Top', -1);
  LLeft := readInteger(LINISection, 'Left', -1);
  // The form pos was found in the ini file
  if (LTop <> -1) and (LLeft <> -1) then
  begin
    AForm.Top   := tiIf(LTop >= 0, LTop, AForm.Top);
    AForm.Left  := readInteger(LINISection, 'Left',   AForm.Left);
    AForm.WindowPosition := wpUser;
  end
  else
  begin  // No form pos in the ini file, so default to screen center
    if Assigned(fpgApplication.MainForm) and (fpgApplication.MainForm <> AForm) then
      AForm.WindowPosition := wpAuto
    else
      AForm.WindowPosition := wpScreenCenter;
  end;

  // Only set the form size if a bsSizable window
  if AForm.Sizeable then
  begin
    if AHeight = -1 then
      LHeight := AForm.Height
    else
      LHeight := AHeight;
    if AWidth = -1 then
      LWidth := AForm.Width
    else
      LWidth := AWidth;
    AForm.Height  := readInteger(LINISection, 'Height', LHeight);
    AForm.Width   := readInteger(LINISection, 'Width',  LWidth);
  end;
  //AForm.WindowState := TfpgWindowState(ReadInteger(LINISection, 'WindowState', Ord(wsNormal)));

  // If the form is off screen (positioned outside all monitor screens) then
  // bring it back into view.
  if AForm.WindowPosition = wpUser then
  begin
    if (AForm.Top < 0) or (AForm.Top > fpgApplication.ScreenHeight) or
       (AForm.Left < 0) or (AForm.Left > fpgApplication.ScreenWidth) then
    begin
      AForm.Left := 0;
      AForm.Top := 0;
    end;
  end;
  AForm.UpdateWindowPosition;
end;

procedure TtiGuiINIFile.WriteFormState(AForm: TfpgForm);
var
  LINISection: string;
begin
  LINISection := AForm.Name + 'State';
  WriteInteger(LINISection, 'WindowState', Ord(AForm.WindowState));
  if AForm.WindowState = wsNormal then
  begin
    WriteInteger(LINISection, 'Top', AForm.Top);
    WriteInteger(LINISection, 'Left', AForm.Left);
    if AForm.Sizeable then
    begin
      WriteInteger(LINISection, 'Height', AForm.Height);
      WriteInteger(LINISection, 'Width', AForm.Width);
    end;
  end;
end;

initialization
  uGuiINI := nil;

finalization
  uGuiINI.Free;

end.








