unit contactmanager;

interface

uses
  model;
  
type

  { TContactManager }

  TContactManager = class(TMarkObject)
  private
    FAddressTypeList: TAddressTypeList;
    FCityList: TCityList;
    FContactList: TContactList;
    FCountryList: TCountryList;
    procedure PopulateCountries;
    procedure PopulateCities;
    procedure PopulateAddressTypes;
    function GenPhone: string;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure PopulateContacts;
  published
    property AddressTypeList: TAddressTypeList read FAddressTypeList;
    property CountryList: TCountryList read FCountryList;
    property CityList: TCityList read FCityList;
    property ContactList: TContactList read FContactList;
  end;


// Global singleton
function gContactManager: TContactManager;


implementation

uses
  SysUtils, tiObject;

var
  uContactManager: TContactManager;
  
const
  LastNames: array[1..10] of string = ('Geldenhuys', 'Botha', 'Johnson', 'Fourie',
      'Louw', 'Bougas', 'van der Mescht', 'Waskanski', 'Welgens', 'Viljoen');

  FirstNames: array[1..10] of string = ('Graeme', 'Johan', 'Debbie', 'Freda',
      'Jack', 'Ryno', 'Dirkus', 'Angela', 'Denise', 'Daniel');
      
  StreetNames: array[1..11] of string = ('Stellenberg Rd', 'Stellendal Rd',
      'Abelia', 'Main Rd', 'Links Drive', 'Short Street',
      'Long Street', 'Loop Street', 'Hillside Rd', 'Mountain Rd', 'Beach Drive');

function gContactManager: TContactManager;
begin
  if not Assigned(uContactManager) then
    uContactManager:= TContactManager.Create;
  result:= uContactManager;
end;

{ TContactManager }

procedure TContactManager.PopulateCountries;
var
  i: integer;
begin
  FCountryList.Add(TCountry.CreateNew('za', 'South Africa'));
  FCountryList.Add(TCountry.CreateNew('gb', 'Great Britain'));
  FCountryList.Add(TCountry.CreateNew('uk', 'Ukrain'));
  FCountryList.Add(TCountry.CreateNew('fr', 'France'));
  FCountryList.Add(TCountry.CreateNew('us', 'United States'));
  FCountryList.Add(TCountry.CreateNew('gr', 'Germany'));

  { reset ObjectState property }
  for i := 0 to FCountryList.Count - 1 do
    FCountryList[i].ObjectState := posClean;
end;

procedure TContactManager.PopulateCities;
var
  c: TCity;
  i: integer;
begin
  c:= TCity.CreateNew;
  c.Name:= 'Somerset West';
  c.ZIP := '7130';
  c.Country:= TCountry(FCountryList.FindByProps(['ISO'], ['za'], True));
  FCityList.Add(c);

  c:= TCity.CreateNew;
  c.Name:= 'Cape Town';
  c.ZIP := '8000';
  c.Country:= TCountry(FCountryList.FindByProps(['ISO'], ['za'], True));
  FCityList.Add(c);

  c:= TCity.CreateNew;
  c.Name:= 'Pretoria';
  c.ZIP := '0001';
  c.Country:= TCountry(FCountryList.FindByProps(['ISO'], ['za'], True));
  FCityList.Add(c);

  c:= TCity.CreateNew;
  c.Name:= 'Durban';
  c.ZIP := '2000';
  c.Country:= TCountry(FCountryList.FindByProps(['ISO'], ['za'], True));
  FCityList.Add(c);

  c:= TCity.CreateNew;
  c.Name:= 'London';
  c.ZIP := 'EC9 5NW';
  c.Country:= TCountry(FCountryList.FindByProps(['ISO'], ['gb'], True));

  FCityList.Add(c);
  c:= TCity.CreateNew;
  c.Name:= 'Watford';
  c.ZIP := 'NW9 7BJ';
  c.Country:= TCountry(FCountryList.FindByProps(['ISO'], ['gb'], True));
  FCityList.Add(c);

  c:= TCity.CreateNew;
  c.Name:= 'Frankfurt';
  c.ZIP := 'FK2000';
  c.Country:= TCountry(FCountryList.FindByProps(['ISO'], ['gr'], True));
  FCityList.Add(c);

  c:= TCity.CreateNew;
  c.Name:= 'New York';
  c.ZIP := 'NY2008';
  c.Country:= TCountry(FCountryList.FindByProps(['ISO'], ['us'], True));
  FCityList.Add(c);

  c:= TCity.CreateNew;
  c.Name:= 'San Fransisco';
  c.ZIP := 'SF2500';
  c.Country:= TCountry(FCountryList.FindByProps(['ISO'], ['us'], True));
  FCityList.Add(c);

  c:= TCity.CreateNew;
  c.Name:= 'Paris';
  c.ZIP := 'PRS007';
  c.Country:= TCountry(FCountryList.FindByProps(['ISO'], ['fr'], True));
  FCityList.Add(c);

  c:= TCity.CreateNew;
  c.Name:= 'Big City';
  c.ZIP := 'BC5 7WN';
  c.Country:= TCountry(FCountryList.FindByProps(['ISO'], ['uk'], True));
  FCityList.Add(c);

  { reset ObjectState property }
  for i := 0 to FCityList.Count - 1 do
    FCityList[i].ObjectState := posClean;
end;

procedure TContactManager.PopulateAddressTypes;
var
  a: TAddressType;
  i: integer;
begin
  a := TAddressType.CreateNew;
  a.Name := 'Home';
  FAddressTypeList.Add(a);

  a := TAddressType.CreateNew;
  a.Name := 'Work';
  FAddressTypeList.Add(a);

  a := TAddressType.CreateNew;
  a.Name := 'Postal';
  FAddressTypeList.Add(a);

  { reset ObjectState property }
  for i := 0 to FAddressTypeList.Count - 1 do
    FAddressTypeList[i].ObjectState := posClean;
end;

function TContactManager.GenPhone: string;
begin
  result:= '+27 ' + IntToStr(Random(9)) + IntToStr(Random(9)) + ' '
    + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + '-'
    + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9));
end;

constructor TContactManager.Create;
begin
  inherited Create;
  FAddressTypeList := TAddressTypeList.Create;
  FAddressTypeList.Owner := self;
  FCountryList := TCountryList.Create;
  FCountryList.Owner := self;
  FCityList := TCityList.Create;
  FCityList.Owner := self;
  FContactList := TContactList.Create;
  FContactList.Owner := self;
end;

destructor TContactManager.Destroy;
begin
  FContactList.Free;
  FCityList.Free;
  FCountryList.Free;
  FAddressTypeList.Free;
  inherited Destroy;
end;

procedure TContactManager.PopulateContacts;
var
  C: TContact;
  I,J: Integer;
  A: TAddress;
  lDay,
  lMonth,
  lYear : Word;
begin
  PopulateCountries;
  PopulateCities;
  PopulateAddressTypes;
  for I:= 1 to 10 do
  begin
    C:= TContact.CreateNew;
    C.FirstName:= FirstNames[I];
    C.LastName := LastNames[I];
    C.Mobile   := GenPhone;
    C.Email    := LowerCase(FirstNames[i])+ '@freepascal.org';
    lDay := Random(27) + 1;
    lMonth:= Random(11) + 1;
    lYear := 1960 + Random(25) + 1;
    C.DateOfBirth := EncodeDate(lYear, lMonth, lDay);
    for J:= 1 to 1+Random(2) do
    begin
      A:= TAddress.CreateNew;
      A.AddressType := FAddressTypeList[Random(3)];
      A.Street := StreetNames[1+Random(10)];
      A.Nr     := Random(100)+1;
      A.City   := FCityList[Random(10)];
      A.Fax    := GenPhone;
      A.Telephone1:= GenPhone;
      If Random(2)>0 then
         A.Telephone2:= GenPhone;
      A.Dirty := False;
      C.AddressList.Add(A);
    end;
    C.Comments := 'My name is ' + C.FirstName + '.';
    C.ObjectState := posClean;
    FContactList.Add(C);
  end;
end;


initialization
  uContactManager:= nil;
  
finalization
  uContactManager.Free;

end.

