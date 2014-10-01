{
  Log to a window above the application's main form, but only if
  the -lv parameter is passed on the command line
  
  This in normally controlled by the tiLogReg unit.

  *** NOTE ***
  * If you application doesn't terminate when you activated LogToGUI, it probably
    means a TThread.WaitFor deadlock occured. In that case, call ReleaseLog()
    after fpgApplication.Run in you project's *.lpr file.
  * Alternatively, the LogToGUI form was accidentally set as Application.MainForm,
    because it was the first form created.
}
unit tiLogToGUI;

{$mode objfpc}{$H+}

interface
uses
  Classes,
  SysUtils,
  fpg_widget,
  fpg_form,
  fpg_memo,
  fpg_menu,
  fpg_panel,
  fpg_button,
  fpg_main,
  tiLog;

type
  TtiLogToGUI = class(TtiLogToCacheAbs)
  private
    FForm: TfpgForm;
    FMemoLog: TfpgMemo;
    FToolBar: TfpgBevel;
    FPopupMenu: TfpgPopupMenu;
    FViewLogMenuItem: TfpgMenuItem;
    FStatusBar: TfpgPanel;
    FScroll: boolean;
    function    GetFormParent: TfpgWidget;
    procedure   SetFormParent(const AValue: TfpgWidget);
    function    CreateForm: TfpgForm;
    procedure   FormClearMenuItemClick(Sender: TObject);
    procedure   FormWordWrapMenuItemClick(Sender: TObject);
    procedure   ScrollWithDataMenuItemClick(Sender: TObject);
    procedure   FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure   FormLogLevelButtonClick(Sender: TObject);
    procedure   DoViewLogFile(Sender: TObject);
    procedure   CopyToClipboardMenuItemClick(Sender: TObject);
    procedure   DoOnPopup(Sender: TObject);
    procedure   WriteToMemo(const AMessage: string);
    procedure   UpdateStatus(const AMessage: string);
  protected
    procedure   WriteToOutput; override;
    procedure   WorkingListToOutput; override;
    procedure   SetSevToLog(const AValue: TtiSevToLog); override;
  public
    constructor Create; override;
    destructor  Destroy; override;
    property    FormParent: TfpgWidget read GetFormParent; // write SetFormParent;
    procedure   Log(const ADateTime, AThreadID, AMessage: string; ASeverity: TtiLogSeverity); override;
  end;


implementation
uses
  fpg_base,
  tiUtils,
  tiCommandLineParams,
  tiDialogs;


{ TtiLogToGUI }

constructor TtiLogToGUI.Create;
begin
  // GUI output must be synchronized with the main thread.
  inherited CreateSynchronized;
  FScroll := True;
  FForm := CreateForm;
  FForm.Show;
  { Make sure the log form doesn't steal MainForm status }
  if fpgApplication.MainForm = FForm then
    fpgApplication.MainForm := nil;
  fpgApplication.ProcessMessages;
  ThrdLog.Resume;
end;

destructor TtiLogToGUI.Destroy;
begin
  { No need to free FForm, because fpgApplication will handle that for use }
  inherited Destroy;
end;

function TtiLogToGUI.CreateForm: TfpgForm;
var
  lMenuItem: TfpgMenuItem;
  lLogSev: TtiLogSeverity;
  lToolButton: TfpgButton;
  x: integer;
begin
  FForm                     := TfpgForm.Create(fpgApplication);
  FForm.WindowPosition      := wpUser;
  FForm.Top                 := 10;
  FForm.Left                := 10;
  FForm.Height              := 270;
  FForm.Width               := (fpgApplication.ScreenWidth div 3) * 2;
  FForm.WindowTitle         := 'Application event log - ' + ApplicationName;
  FForm.OnCloseQuery        := @FormCloseQuery;

  FPopupMenu                := TfpgPopupMenu.Create(FForm);
  FPopupMenu.Name           := 'PopupMenu';
  FPopupMenu.BeforeShow     := @DoOnPopup;

  FToolBar                  := TfpgBevel.Create(FForm);
  FToolBar.Name             := 'ToolBar';
  FToolBar.SetPosition(0, 0, FForm.Width, 30);
  FToolbar.Shape            := bsSpacer;
  FToolBar.Align            := alTop;
  FToolBar.TabOrder         := 1;

  FStatusBar                := TfpgPanel.Create(FForm);
  FStatusBar.Name           := 'FStatusBar';
  FStatusBar.Style          := bsLowered;
  FStatusBar.Alignment      := taLeftJustify;
  FStatusBar.Height         := 20;
  FStatusBar.Text           := '';
  FStatusBar.Align          := alBottom;

  FMemoLog                  := TfpgMemo.Create(FForm);
  FMemoLog.Name             := 'MemoLog';
  FMemoLog.Top              := 29;
  FMemoLog.Align            := alClient;
  FMemoLog.FontDesc         := '#Edit2';  // monospaced font
  FMemoLog.PopupMenu        := FPopupMenu;
//  FMemoLog.ReadOnly         := True;
//  FMemoLog.ScrollBars       := ssBoth;
  FMemoLog.TabOrder         := 0;
//  FMemoLog.WordWrap         := False;
  FMemoLog.Lines.Clear;

  { Setup popup menu items}
  FViewLogMenuItem          := FPopupMenu.AddMenuItem('View log file', '', @DoViewLogFile);
  FViewLogMenuItem.Name     := 'Viewlogfile1';
  lMenuItem                 := FPopupMenu.AddMenuItem('-', '', nil);
  lMenuItem.Name            := 'N1';
  lMenuItem                 := FPopupMenu.AddMenuItem('Clear', '', @FormClearMenuItemClick);
  lMenuItem.Name            := 'ClearMenuItem';
  lMenuItem                 := FPopupMenu.AddMenuItem('Copy to clipboard', '', @CopyToClipboardMenuItemClick);
  lMenuItem.Name            := 'CopyToClipboardMenuItem';
  lMenuItem                 := FPopupMenu.AddMenuItem('Word wrap', '', @FormWordWrapMenuItemClick);
  lMenuItem.Name            := 'WordWrapMenuItem';
  lMenuItem.Enabled         := False;
  lMenuItem                 := FPopupMenu.AddMenuItem('Scroll with data', '', @ScrollWithDataMenuItemClick);
  lMenuItem.Name            := 'ScrollWithDataMenuItem';
  lMenuItem.Checked         := FScroll;

  { Setup severity toolbar buttons }
  x := 1;
  for lLogSev := Low(TtiLogSeverity) to High(TtiLogSeverity) do
  begin
    lToolButton           := TfpgButton.Create(FToolBar);
    lToolButton.SetPosition(x, 1, 50, 28);
    lToolButton.Text      := cTILogSeverityStrings[lLogSev];
    lToolButton.Tag       := Ord(lLogSev);
    lToolButton.AllowAllUp := True; // enables toggle button mode
    lToolButton.GroupIndex := Ord(lLogSev) + 1; // enables toggle button mode
    lToolButton.Down      := lLogSev in GLog.SevToLog;
    lToolButton.OnClick   := @FormLogLevelButtonClick;
    lToolButton.Focusable := False;
    Inc(x, 51);
  end;
  
 Result := FForm;
end;

function TtiLogToGUI.GetFormParent: TfpgWidget;
begin
  result := FForm.Parent;
end;

procedure TtiLogToGUI.Log(const ADateTime, AThreadID, AMessage: string; ASeverity: TtiLogSeverity);
begin
  if Terminated then
    Exit; //==>
  if not FForm.HasHandle then
    FForm.Show;
  inherited Log(ADateTime, AThreadID, AMessage, ASeverity);
end;

procedure TtiLogToGUI.SetFormParent(const AValue: TfpgWidget);
begin
  {$Note This is untested!!! }
  FForm.Parent      := AValue;
  FForm.Align       := alClient;
  FForm.WindowAttributes := FForm.WindowAttributes + [waBorderless];
//  FForm.BorderStyle := bsNone;
end;

procedure TtiLogToGUI.SetSevToLog(const AValue: TtiSevToLog);
var
  i: integer;
  lLogSev: TtiLogSeverity;
begin
  // Let parent perform important task(s)
  inherited;
  // All we do here is reflect any changes to LogSeverity in the visual controls
  for i := 0 to FToolBar.ComponentCount - 1 do
  begin
    lLogSev := TtiLogSeverity(FToolBar.Components[i].Tag);
    if FToolBar.Components[i] is TfpgButton then
      TfpgButton(FToolBar.Components[i]).Down := lLogSev in AValue;
  end;
end;

procedure TtiLogToGUI.WriteToMemo(const AMessage: string);
var
  i: integer;
  LLine: string;
  LCount: integer;
begin
  LCount := tiNumToken(AMessage, tiLineEnd);
  FMemoLog.BeginUpdate;
  if LCount = 1 then
    FMemoLog.Lines.Add(tiTrimTrailingWhiteSpace(AMessage))
  else
  begin
    UpdateStatus('processing multiline log...');
    for i := 1 to LCount do
    begin
      LLine := tiTrimTrailingWhiteSpace(tiToken(AMessage, tiLineEnd, i));
      FMemoLog.Lines.Add(LLine);
    end;
  end;
  UpdateStatus('done');
  if FScroll then
    FMemoLog.CursorLine := FMemoLog.Lines.Count-1
  else
    FMemoLog.CursorLine := 0;
  FMemoLog.EndUpdate;
end;

procedure TtiLogToGUI.UpdateStatus(const AMessage: string);
begin
  FStatusBar.Text := AMessage;
  fpgApplication.ProcessMessages;
end;

procedure TtiLogToGUI.WriteToOutput;
begin
  if not ThrdLog.Terminated then
    inherited WriteToOutput;
end;

procedure TtiLogToGUI.WorkingListToOutput;
var
  i: integer;
  LLogEvent: TtiLogEvent;
  LPosStart: integer;
  LPosEnd: integer;
const
  ciMaxLineCount = 200;
begin
  if WorkingList.Count > (ciMaxLineCount * 2) then
  begin
    FMemoLog.Lines.Clear;
    LPosStart := WorkingList.Count - 1 - ciMaxLineCount;
    LPosEnd   := WorkingList.Count - 1;
  end
  else
  begin
    if FMemoLog.Lines.Count > ciMaxLineCount then
    begin
      for i := 0 to ciMaxLineCount div 2 do
        FMemoLog.Lines.Delete(0);
    end;
    LPosStart := 0;
    LPosEnd   := WorkingList.Count - 1;
  end;

  for i := LPosStart to LPosEnd do
  begin
    if ThrdLog.Terminated then
      Break; //==>
    LLogEvent := TtiLogEvent(WorkingList.Items[i]);
    WriteToMemo(LLogEvent.AsLeftPaddedString);
  end;
end;

procedure TtiLogToGUI.FormClearMenuItemClick(Sender: TObject);
begin
  FMemoLog.Lines.Clear;
end;

procedure TtiLogToGUI.FormWordWrapMenuItemClick(Sender: TObject);
begin
  //FMemoLog.WordWrap        := not FMemoLog.WordWrap;
  //FWordWrapMenuItem.Checked := FMemoLog.WordWrap;
  //if FMemoLog.WordWrap then
    //FMemoLog.ScrollBars := ssVertical
  //else
    //FMemoLog.ScrollBars := ssBoth;
end;

procedure TtiLogToGUI.ScrollWithDataMenuItemClick(Sender: TObject);
begin
  FScroll := not (Sender as TfpgMenuItem).Checked;
  (Sender as TfpgMenuItem).Checked := FScroll;
end;

procedure TtiLogToGUI.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
end;

procedure TtiLogToGUI.FormLogLevelButtonClick(Sender: TObject);
var
  lLogSev: TtiLogSeverity;
  lLogChecked: boolean;
begin
  if not (Sender is TfpgButton) then
    Exit; //==>

  lLogSev := TtiLogSeverity(TfpgWidget(Sender).Tag);
  lLogChecked := TfpgButton(Sender).Down;
  if lLogChecked then
    GLog.SevToLog := GLog.SevToLog + [lLogSev]
  else
    GLog.SevToLog := GLog.SevToLog - [lLogSev];
end;

procedure TtiLogToGUI.DoViewLogFile(Sender: TObject);
var
  sl: TStringList;
begin
  if (GLog.LogToFileName <> '') and
     (FileExists(GLog.LogToFileName)) then
  begin
    sl := TStringList.Create;
    try
      sl.LoadFromFile(GLog.LogToFilename);
      tiShowStringList(sl, GLog.LogToFilename);
//      tiEditFile(GLog.LogToFileName);
    finally
      sl.Free;
    end;
  end;
end;

procedure TtiLogToGUI.CopyToClipboardMenuItemClick(Sender: TObject);
begin
  FMemoLog.CopyToClipboard;
end;

procedure TtiLogToGUI.DoOnPopup(Sender: TObject);
begin
  { If we are logging to file as well, then enable the menu option }
  FViewLogMenuItem.Enabled :=
    (GLog.LogToFileName <> '') and
    (FileExists(GLog.LogToFileName));
end;


end.

