unit frmMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpg_form, fpg_button, fpg_label, fpg_edit, fpg_trackbar,
  fpg_combobox, fpg_checkbox, fpg_listbox, Model,
  tiMediators, tiListMediators;

type
  TMainForm = class(TfpgForm)
  private
    btnClose: TfpgButton;
    btnViaCode: TfpgButton;
    btnAddViaCode: TfpgButton;
    btnShowModel: TfpgButton;
    btnDeleted: TfpgButton;
    lblName: TfpgLabel;
    edtName: TfpgEdit;
    lblAge: TfpgLabel;
//    edtAge: TSpinEdit;
    AgeTrackBar: TfpgTrackBar;
    cbPeople: TfpgComboBox;
    lbPeople: TfpgListBox;
    lblPerson: TfpgLabel;
//    gbPerson: TGroupBox;
    chkShowDeleted: TfpgCheckBox;
    { The object we will be working with. }
    FPersonList: TPersonList;

    { Mediators }
    FComboBoxMediator: TtiComboBoxMediatorView;
    FListBoxMediator: TtiListBoxMediatorView;
    FNameMediator: TtiEditMediatorView;
//    FAgeMediator: TMediatorSpinEditView;
    FTrackBarAgeMediator: TtiTrackBarMediatorView;

    procedure   btnCloseClick(Sender: TObject);
    procedure   btnShowModelClick(Sender: TObject);
    procedure   btnViaCodeClick(Sender: TObject);
    procedure   btnDeleteClick(Sender: TObject);
    procedure   btnViaCodeAddClick(Sender: TObject);
    procedure   lbSelectionChanged(Sender: TObject);
    procedure   cbSelectionChanged(Sender: TObject);
    procedure   chkShowDeletedChange(Sender: TObject);

    procedure   InitializeComponents;
    procedure   SetupMediators;
    procedure   SetupEventHandlers;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   AfterConstruction; override;
  end;

implementation

uses
  Model_View
  ,fpg_base
  ,tiObject
  ,tiDialogs
  ;

{ TMainForm }

procedure TMainForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.btnShowModelClick(Sender: TObject);
begin
  tiShowString(FPersonList.AsDebugString);
end;

procedure TMainForm.btnViaCodeClick(Sender: TObject);
begin
  { The BeginUpdate/EndUpdate will let the Item notify its observers
    only once, even though two change where made.
    Note:
    This is for observers to the Item, not the List that the Item belongs to! }
  FPersonList.Items[1].BeginUpdate;
  FPersonList.Items[1].Name := 'I have changed via code';
  FPersonList.Items[1].Age  := 99;
  FPersonList.Items[1].EndUpdate;
  { This notifies observers of the List, that something has changed. }
  FPersonList.NotifyObservers;
end;

{ This toggles the Deleted state of an object. Not really the correct way of
  doing things. It is for demonstration purposes only! }
procedure TMainForm.btnDeleteClick(Sender: TObject);
begin
  if FListBoxMediator.SelectedObject.Deleted then
    FListBoxMediator.SelectedObject.ObjectState := posCreate
  else
    FListBoxMediator.SelectedObject.Deleted := True;
  FPersonList.NotifyObservers;
end;

procedure TMainForm.btnViaCodeAddClick(Sender: TObject);
var
  lData: TPerson;
begin
  lData := TPerson.Create;
  lData.Name := 'I am new';
  lData.Age := 44;
  FPersonList.Add(lData);
end;

procedure TMainForm.lbSelectionChanged(Sender: TObject);
var
  backup: TNotifyEvent;
begin
  FListBoxMediator.HandleSelectionChanged;
  { This is only done to keep the ComboBox and ListBox in sync. This would not
    be done or needed in a real application }
  backup := cbPeople.OnChange;
  cbPeople.OnChange := nil;
  cbPeople.FocusItem := lbPeople.FocusItem;
  cbpeople.OnChange := backup;
end;

procedure TMainForm.cbSelectionChanged(Sender: TObject);
var
  backup: TNotifyEvent;
begin
  FComboBoxMediator.HandleSelectionChanged;
  { This is only done to keep the ComboBox and ListBox in sync. This would not
    be done or needed in a real application }
  backup := lbPeople.OnChange;
  lbPeople.OnChange := nil;
  lbPeople.FocusItem := cbPeople.FocusItem;
  lbPeople.OnChange := backup;
end;

procedure TMainForm.chkShowDeletedChange(Sender: TObject);
begin
  FComboBoxMediator.ShowDeleted := chkShowDeleted.Checked;
  FListBoxMediator.ShowDeleted  := chkShowDeleted.Checked;
end;

procedure TMainForm.InitializeComponents;
var
  lbl: TfpgLabel;
begin
  btnClose := CreateButton(self, 416, 370, 75, 'Close', @btnCloseClick);
  btnClose.ImageName := 'stdimg.Close';
  btnClose.ShowImage := True;

  btnViaCode := CreateButton(self, 7, btnClose.Top, 150, 'Change via Code', @btnViaCodeClick);
  btnViaCode.Hint := 'This changes a object via code, and magically the list views are updated.';

  btnAddViaCode := CreateButton(self, 7, btnViaCode.Top - btnViaCode.Height - 5, 150, 'Add via Code', @btnViaCodeAddClick);
  btnAddViaCode.Hint := 'This adds a object via code, and magically the list views are updated.';

  btnShowModel := CreateButton(self, btnViaCode.Right + 7, btnViaCode.Top, 100, 'Show Model', @btnShowModelClick);
  btnShowModel.Hint := 'Show the internal state of all objects';

  btnDeleted := CreateButton(self, btnShowModel.Right + 7, btnClose.Top, 75, 'Delete', @btnDeleteClick);
  btnDeleted.Hint := 'Toggle the Deleted state of seleted object in ListBox';

  lblPerson := CreateLabel(self, 7, 20, 'Details of selected object in ComboBox');
  lblPerson.FontDesc := '#Label2';

  lblName := CreateLabel(self, 25, lblPerson.Bottom + 7, 'Name:');
  edtName := CreateEdit(self, lblName.Right + 7, lblPerson.Bottom + 5, 150, 20);
  edtName.Enabled := False;
  
  lblAge := CreateLabel(self, 25, edtName.Bottom + 7, 'Age:');
  AgeTrackBar := TfpgTrackbar.Create(self);
  AgeTrackBar.Left := edtName.Left;
  AgeTrackBar.Top := lblAge.Top-4;
  AgeTrackBar.Width := edtName.Width;
  AgeTrackBar.ShowPosition := True;
  AgeTrackBar.Enabled := False;

  lbl := CreateLabel(self, edtName.Right + 30, edtName.Top, 'These components observe the selected item of ComboBox', 200, AgeTrackBar.Top-5);
  lbl.TextColor := clBlue;
  lbl.WrapText := True;

  lbPeople := TfpgListBox.Create(self);
  lbPeople.Top          := AgeTrackBar.Bottom + 17;
  lbPeople.Left         := 7;
  lbPeople.Height       := 200;
  lbPeople.Width        := 200;
  lbPeople.Hint := 'Shows objects from the object list';

  cbPeople := TfpgComboBox.Create(self);
  cbPeople.Top          := AgeTrackBar.Bottom + 17;
  cbPeople.Left         := lbPeople.Right + 15;
  cbPeople.Width        := 200;
  cbPeople.Hint := 'Shows objects from the object list';

  chkShowDeleted := CreateCheckBox(self, cbPeople.Left, lbPeople.Bottom-20, 'Show Deleted');

end;

procedure TMainForm.SetupMediators;
begin
  { list mediators }
  FComboBoxMediator := TPersonList_ComboBox_Mediator.CreateCustom(FPersonList, cbPeople);
  FListBoxMediator  := TListBoxMediator.CreateCustom(FPersonList, lbPeople);

  { property/edit mediators }
  FNameMediator     := TPerson_Name_TextEdit_View.CreateCustom(edtName, FComboBoxMediator.SelectedObject, 'Name', 'Text');
  FTrackBarAgeMediator := TPerson_Age_TrackBar_Mediator.CreateCustom(AgeTrackBar, FComboBoxMediator.SelectedObject, 'Age', 'Position');

  { By default we creating mediators, they are not updated automatically. This
    allows us to notify all observers at once. This behaviour can be changed. }
  FPersonList.NotifyObservers;
end;

procedure TMainForm.SetupEventHandlers;
begin
  lbPeople.OnChange         := @lbSelectionChanged;
  cbPeople.OnChange         := @cbSelectionChanged;
  chkShowDeleted.OnChange   := @chkShowDeletedChange;
end;

constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  WindowTitle := 'List Mediators Demo';
  WindowPosition := wpUser;
  SetPosition(100, 100, 500, 400);
  
  InitializeComponents;
  FPersonList := GeneratePersonList;
  SetupEventHandlers;
end;

destructor TMainForm.Destroy;
begin
  FNameMediator.Free;
  FTrackBarAgeMediator.Free;
  FComboBoxMediator.Free;
  FListBoxMediator.Free;
  FPersonList.Free;
  inherited Destroy;
end;

procedure TMainForm.AfterConstruction;
begin
  inherited AfterConstruction;
  { The only trick here is to not let the OnChange events fire
    before the mediators are not set up!! }
  SetupMediators;
end;

end.

