unit AdrsBookUIHTML_BOM;

interface
uses
  tiBaseObject,
  Adrs_BOM;

type

  TAdrsBookUIHTML = class(TtiBaseObject)
  protected
    function DoExecute(const AParams: string): string;
    function PersonListToHTML(const APersonList: TPersonList): string;
    function PersonToHTML(const APerson: TPerson): string;
  public
    class function Execute(const AParams: string): string;
  end;

implementation
uses
  tiQueryIBX,
  tiOPFManager,
  tiUtils,
  Adrs_SrvAutoMap;

{ TAdrsBookUIHTML }

function TAdrsBookUIHTML.DoExecute(const AParams: string): string;
var
  LAdrs: TAdrsBook;
begin
  Adrs_SrvAutoMap.RegisterMappings;
  GTIOPFManager.ConnectDatabase(
    tiGetEXEPath +  '\..\adrs.fdb',
    'SYSDBA',
    'masterkey');
  LAdrs:= TAdrsBook.Create;
  try
    LAdrs.Read;
    Result:=
      '<html>' + tiLineEnd +
    PersonListToHTML(LAdrs.PersonList) +
      '</html>';
  finally
    LAdrs.Free;
  end;
end;

class function TAdrsBookUIHTML.Execute(const AParams: string): string;
var
  LO: TAdrsBookUIHTML;
begin
  LO:= TAdrsBookUIHTML.Create;
  try
    Result:= LO.DoExecute(AParams);
  finally
    LO.Free;
  end;
end;

function TAdrsBookUIHTML.PersonListToHTML(
  const APersonList: TPersonList): string;
var
  i: integer;
begin
  Result:=
    '<table border=1>' + tiLineEnd +
    '<tr><th>Title</th><th>First name</th><th>Last Name</th><th>Action</th></tr>';
  for i := 0 to APersonList.Count - 1 do
      Result:= Result + PersonToHTML(APersonList.Items[i]);
  Result:= Result + '</table>' + tiLineEnd;
end;

function TAdrsBookUIHTML.PersonToHTML(const APerson: TPerson): string;
begin
  result:=
    '<tr>' + 
    '<td>' + APerson.Title + '</td>' +
    '<td>' + APerson.FirstName + '</td>' +
    '<td>' + APerson.LastName + '</td>' +
    '<td><a href=''javascript:window.alert("ToDo: Implement Edit");''>Edit</a>' +
    '&nbsp;' +
    '<a href=''javascript:window.alert("ToDo: Implement Delete");''>Delete</a></td>' +
    '</tr>' + tiLineEnd;
end;



end.
