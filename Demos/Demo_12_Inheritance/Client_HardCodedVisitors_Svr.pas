unit Client_HardCodedVisitors_Svr;

{$I tiDefines.inc}

interface

uses
  tiVisitorDB
 ;

type

  // TClientAbs
  TVisClientAbs_Update = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
  end;

  TVisClientAbs_Create = class(TVisClientAbs_Update)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
  end;

  TVisClientAbs_Delete = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
  end;

  // TClientCompany
  TVisClientCompany_Read = class(TtiVisitorSelect)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
    procedure MapRowToObject; override;
  end;

  TVisClientCompany_Update = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
  end;

  TVisClientCompany_Create = class(TVisClientCompany_Update)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
  end;

  TVisClientCompany_Delete = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init         ; override;
    procedure SetupParams  ; override;
  end;

  // TClientPerson
  TVisClientPerson_Read = class(TtiVisitorSelect)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
    procedure MapRowToObject; override;
  end;

  TVisClientPerson_Update = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
  end;

  TVisClientPerson_Create = class(TVisClientPerson_Update)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
  end;

  TVisClientPerson_Delete = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init         ; override;
    procedure SetupParams  ; override;
  end;

procedure RegisterVisitors;

implementation
uses
   tiOPFManager
  ,tiObject 
  ,Client_BOM 
 ;

procedure RegisterVisitors;
begin

  // Note: Registration order is important
  GTIOPFManager.RegReadVisitor(TVisClientCompany_Read);
  GTIOPFManager.RegReadVisitor(TVisClientPerson_Read);

  GTIOPFManager.RegSaveVisitor(TVisClientPerson_Delete);
  GTIOPFManager.RegSaveVisitor(TVisClientCompany_Delete);
  GTIOPFManager.RegSaveVisitor(TVisClientAbs_Delete);

  GTIOPFManager.RegSaveVisitor(TVisClientAbs_Create);
  GTIOPFManager.RegSaveVisitor(TVisClientAbs_Update);

  GTIOPFManager.RegSaveVisitor(TVisClientPerson_Create);
  GTIOPFManager.RegSaveVisitor(TVisClientPerson_Update);

  GTIOPFManager.RegSaveVisitor(TVisClientCompany_Create);
  GTIOPFManager.RegSaveVisitor(TVisClientCompany_Update);

end;

{ TVisClientPerson_Read }

function TVisClientPerson_Read.AcceptVisitor: boolean;
begin
  result:= (Visited is TClients) and
            (Visited.ObjectState = posEmpty);
end;

procedure TVisClientPerson_Read.Init;
begin
  Query.SQL.Text:=
    'select ' +
    '   ca.oid          as oid ' +
    '  ,ca.Client_ID    as Client_id ' +
    '  ,cp.Given_Name   as Given_Name ' +
    '  ,cp.Family_Name  as Family_Name ' +
    'from ' +
    '          client_abs  ca ' +
    'join client_person cp on cp.oid = ca.oid ' +
    'order by ' +
    'family_name, given_name ';
end;

procedure TVisClientPerson_Read.MapRowToObject;
var
  lClient: TClientPerson;
begin
  lClient:= TClientPerson.Create;
  lClient.OID.AssignFromTIQuery('OID', Query);
  lClient.ClientID:= Query.FieldAsString['Client_ID'];
  lClient.GivenName:= Query.FieldAsString['Given_Name'];
  lClient.FamilyName:= Query.FieldAsString['Family_Name'];
  lClient.ObjectState:= posClean;
  TClients(Visited).Add(lClient);
end;

procedure TVisClientPerson_Read.SetupParams;
begin
  // Do nothing
end;

{ TVisClientPerson_Create }

function TVisClientPerson_Create.AcceptVisitor: boolean;
begin
  result:= (Visited is TClientPerson) and
            (Visited.ObjectState = posCreate);
end;

procedure TVisClientPerson_Create.Init;
begin
  Query.SQL.Text:=
    'Insert into Client_Person (OID, Given_Name, Family_Name) ' +
    'Values ' +
    '(:OID,:Given_Name,:Family_Name) ';
end;

{ TVisClientPerson_Update }

function TVisClientPerson_Update.AcceptVisitor: boolean;
begin
  result:= (Visited is TClientPerson) and
            (Visited.ObjectState = posUpdate);
end;

procedure TVisClientPerson_Update.Init;
begin
  Query.SQL.Text:=
    'Update Client_Person Set ' +
    '  ,Given_Name  =:Given_Name ' +
    '  ,Family_Name =:Family_Name ' +
		'where ' +
		' OID =:OID';
end;

procedure TVisClientPerson_Update.SetupParams;
var
  lData: TClientPerson;
begin
  lData:= Visited as TClientPerson;
  lData.OID.AssignToTIQuery('OID', Query);
	Query.ParamAsString['Given_Name']:= lData.GivenName;
	Query.ParamAsString['Family_Name']:= lData.FamilyName;
end;

{ TVisClientPerson_Delete }

function TVisClientPerson_Delete.AcceptVisitor: boolean;
begin
  result:= (Visited is TClientPerson) and
            (Visited.ObjectState = posDelete);
end;

procedure TVisClientPerson_Delete.Init;
begin
  Query.SQL.Text:=
    'delete from client_person where oid =:oid';
end;

procedure TVisClientPerson_Delete.SetupParams;
var
  lData: TClientPerson;
begin
  lData:= Visited as TClientPerson;
	lData.OID.AssignToTIQuery('OID', Query);
end;

{ TVisClientAbs_Create }

function TVisClientAbs_Create.AcceptVisitor: boolean;
begin
  result:= (Visited is TClientAbs) and
            (Visited.ObjectState = posCreate);
end;

procedure TVisClientAbs_Create.Init;
begin
  Query.SQL.Text:=
    'Insert into Client_Abs ' +
    '(OID, Client_ID) ' +
    'Values ' +
    '(:OID,:Client_ID)';
end;

{ TVisClientCompany_Read }

function TVisClientCompany_Read.AcceptVisitor: boolean;
begin
  result:= (Visited is TClients);
end;

procedure TVisClientCompany_Read.Init;
begin
  Query.SQL.Text:=
    'select ' +
    '   ca.oid          as oid ' +
    '  ,ca.Client_ID    as Client_id ' +
    '  ,cc.Company_Name as Company_Name ' +
    'from ' +
    '          client_abs  ca ' +
    'join client_company cc on cc.oid = ca.oid ' +
    'order by ' +
    'company_name ';
end;

procedure TVisClientCompany_Read.MapRowToObject;
var
  lClient: TClientCompany;
begin
  lClient:= TClientCompany.Create;
  lClient.OID.AssignFromTIQuery('OID', Query);
  lClient.ClientID:= Query.FieldAsString['Client_ID'];
  lClient.CompanyName:= Query.FieldAsString['Company_Name'];
  lClient.ObjectState:= posClean;
  TClients(Visited).Add(lClient);
end;

procedure TVisClientCompany_Read.SetupParams;
begin
  // Do nothing
end;

{ TVisClientAbs_Update }

function TVisClientAbs_Update.AcceptVisitor: boolean;
begin
  result:= (Visited is TClientAbs) and
            (Visited.ObjectState = posUpdate);
end;

procedure TVisClientAbs_Update.Init;
begin
  Query.SQL.Text:=
    'Update Client_Abs ' +
    'Set ' +
    '  Client_ID =:Client_ID ' +
    'where ' +
    '  OID =:OID';
end;

procedure TVisClientAbs_Update.SetupParams;
var
  lData: TClientAbs;
begin
  lData:= Visited as TClientAbs;
  lData.OID.AssignToTIQuery('OID', Query);
  Query.ParamAsString['Client_ID']:= lData.ClientID;
end;

{ TVisClientAbs_Delete }

function TVisClientAbs_Delete.AcceptVisitor: boolean;
begin
  result:= (Visited is TClientAbs) and
            (Visited.ObjectState = posDelete);
end;

procedure TVisClientAbs_Delete.Init;
begin
  Query.SQL.Text:=
    'Delete from Client_Abs where OID =:OID';
end;

procedure TVisClientAbs_Delete.SetupParams;
var
  lData: TClientAbs;
begin
  lData:= Visited as TClientAbs;
  lData.OID.AssignToTIQuery('OID', Query);
end;

{ TVisClientCompany_Create }

function TVisClientCompany_Create.AcceptVisitor: boolean;
begin
  result:= (Visited is TClientCompany) and
            (Visited.ObjectState = posCreate);
end;

procedure TVisClientCompany_Create.Init;
begin
  Query.SQL.Text:=
    'Insert into Client_Company ' +
    '(OID, Company_Name) ' +
    'Values ' +
    '(:OID,:Company_Name) ';
end;

{ TVisClientCompany_Update }

function TVisClientCompany_Update.AcceptVisitor: boolean;
begin
  result:= (Visited is TClientCompany) and
            (Visited.ObjectState = posUpdate);
end;

procedure TVisClientCompany_Update.Init;
begin
  Query.SQL.Text:=
    'Update Client_Company set ' +
    '  Company_Name =:Company_Name ' +
    'where ' +
    '  OID =:OID';
end;

procedure TVisClientCompany_Update.SetupParams;
var
  lData: TClientCompany;
begin
  lData:= Visited as TClientCompany;
  lData.OID.AssignToTIQuery('OID', Query);
  Query.ParamAsString['Company_Name'] := lData.CompanyName;
end;

{ TVisClientCompany_Delete }

function TVisClientCompany_Delete.AcceptVisitor: boolean;
begin
  result:= (Visited is TClientCompany) and
            (Visited.ObjectState = posDelete);
end;

procedure TVisClientCompany_Delete.Init;
begin
  Query.SQL.Text:=
    'delete from client_company where oid =:oid';
end;

procedure TVisClientCompany_Delete.SetupParams;
var
  lData: TClientCompany;
begin
  lData:= Visited as TClientCompany;
  lData.OID.AssignToTIQuery('OID', Query);
end;

end.

