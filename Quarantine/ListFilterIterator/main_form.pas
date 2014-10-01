unit main_form;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls

  ,person
  ,tiObjectListFilterIterator

  ;

type
  TForm3 = class(TForm)
    memOutput: TMemo;
    btnIterate: TButton;
    btnClose: TButton;
    memFilter: TMemo;
    lblFilter: TLabel;
    btn1: TButton;
    btn2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnIterateClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);  private
  private
    FPersonList: TPersonList;
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}


procedure TForm3.btn1Click(Sender: TObject);
var
  lIterator: IListFilterIterator; // Declare as Interface
  lPerson: TPerson;
begin

  memOutput.Clear;

  memOutput.Lines.Add('--------------------------------');
  memOutput.Lines.Add('Reference Counted Iterator.  Destroy Automatically.');
  memOutput.Lines.Add('--------------------------------');

  // Notice the "I" suffix on GetIterator?  Stands for "Interfaced".
  lIterator := gListIteratorMgr.GetIteratorI('', FPersonList); // empty filter returns all

  while lIterator.Next do
    begin
      lPerson := TPerson(lIterator.Current); // Ref counted, interface kind returns only TtiObject
      memOutput.Lines.Add(lPerson.FirstName + ' ' + lPerson.LastName);
    end;

end;

procedure TForm3.btn2Click(Sender: TObject);
var
  lIterator: IListFilterIterator; // Declare as Interface
  lPerson: TPerson;
begin

  memOutput.Clear;

  memOutput.Lines.Add('--------------------------------');
  memOutput.Lines.Add('Stop On Fail - Filter = LastName LIK J*');
  memOutput.Lines.Add('--------------------------------');

  // First we sort the list
  FPersonList.SortByProps(['LastName']);

  // Now we get a filtered iterator based on "J*" filter.  Should stop checking after last "J" last name found.
  lIterator := gListIteratorMgr.GetIteratorI('LastName LIKE J*', FPersonList, True);

  while lIterator.Next do
    begin
      lPerson := TPerson(lIterator.Current); // Ref counted, interface kind returns only TtiObject
      memOutput.Lines.Add(lPerson.LastName + ', ' + lPerson.FirstName);
    end;
end;

procedure TForm3.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TForm3.btnIterateClick(Sender: TObject);
var
  lListIterator: TPersonListIterator;
  lPerson: TPerson;
  lFilter: string;
begin
  memOutput.Clear;

  lFilter := memFilter.Text;

  lListIterator :=
    TPersonListIterator(gListIteratorMgr.GetIterator(lFilter, FPersonList));

  try

    memOutput.Lines.Add('--------------------------------');
    memOutput.Lines.Add('Iterating from First to Last');
    memOutput.Lines.Add('--------------------------------');

    while lListIterator.Next do
      begin
        memOutput.Lines.Add(lListIterator.Current.FirstName + ' ' +
          lListIterator.Current.LastName);
      end;

    memOutput.Lines.Add('--------------------------------');
    memOutput.Lines.Add('Iterating from Last to First');
    memOutput.Lines.Add('--------------------------------');

    lListIterator.GoToEnd;
    while lListIterator.Previous do
      begin
        lPerson := TPerson(lListIterator.Current);
        memOutput.Lines.Add(lPerson.FirstName + ' ' + lPerson.LastName);
      end;

  finally
    lListIterator.free;
  end;

end;

procedure TForm3.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FPersonList.Free;
end;

procedure TForm3.FormCreate(Sender: TObject);
var
  lPerson: TPerson;
begin
  // Create some sample objects
  FPersonList := TPersonList.Create;

  lPerson := TPerson.Create;
  lPerson.FirstName := 'ImFrom';
  lPerson.LastName := 'Balmer';
  lPerson.Age := 14;
  lPerson.DateOfHire := EncodeDate(1999, 8, 20);
  lPerson.Alive := true;
  lPerson.Gender := pgMale;
  FPersonList.Add(lPerson);

  lPerson := TPerson.Create;
  lPerson.FirstName := 'John';
  lPerson.LastName := 'Johnson';
  lPerson.Age := 42;
  lPerson.DateOfHire := EncodeDate(2002, 1, 15);
  lPerson.Alive := true;
  lPerson.Gender := pgMale;
  FPersonList.Add(lPerson);

  lPerson := TPerson.Create;
  lPerson.FirstName := 'Beverely';
  lPerson.LastName := 'Johansen';
  lPerson.Age := 28;
  lPerson.DateOfHire := EncodeDate(2002, 1, 15);
  lPerson.Alive := true;
  lPerson.Gender := pgFemale;
  FPersonList.Add(lPerson);

  lPerson := TPerson.Create;
  lPerson.FirstName := 'Eric';
  lPerson.LastName := 'Roberts';
  lPerson.Age := 67;
  lPerson.DateOfHire := EncodeDate(2008, 6, 30);
  lPerson.Alive := true;
  lPerson.Gender := pgMale;
  FPersonList.Add(lPerson);

  lPerson := TPerson.Create;
  lPerson.FirstName := 'Napolean';
  lPerson.LastName := 'Hill';
  lPerson.Age := 87;
  lPerson.DateOfHire := EncodeDate(2002, 1, 15);
  lPerson.Alive := False;
  lPerson.Gender := pgMale;
  FPersonList.Add(lPerson);

  lPerson := TPerson.Create;
  lPerson.FirstName := 'Anatoli';
  lPerson.LastName := 'Jergensen';
  lPerson.Age := 22;
  lPerson.DateOfHire := EncodeDate(2007, 1, 15);
  lPerson.Alive := True;
  lPerson.Gender := pgMale;
  FPersonList.Add(lPerson);

  lPerson := TPerson.Create;
  lPerson.FirstName := 'Angela';
  lPerson.LastName := 'Baker';
  lPerson.Age := 32;
  lPerson.DateOfHire := EncodeDate(2005, 9, 15);
  lPerson.Alive := true;
  lPerson.Gender := pgFemale;
  FPersonList.Add(lPerson);

end;

end.
