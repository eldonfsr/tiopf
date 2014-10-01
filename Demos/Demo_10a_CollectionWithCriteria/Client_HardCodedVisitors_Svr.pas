unit Client_HardCodedVisitors_Svr;

interface
uses
  tiVisitorDB
 ;

type

  TVisClient_Read = class(TtiVisitorSelect)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
    procedure MapRowToObject; override;
  end;

  TVisClient_Create = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
  end;

  TVisClient_Update = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
  end;

  TVisClient_Delete = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor: boolean; override;
    procedure Init         ; override;
    procedure SetupParams   ; override;
  end;

procedure RegisterVisitors;

implementation
uses
  Client_BOM
  ,tiOPFManager
  ,tiObject
  ,tiLog
  ,tiCriteria
  ,tiVisitorCriteria
 ;

procedure RegisterVisitors;
begin
  GTIOPFManager.RegReadVisitor(TVisClient_Read);
  GTIOPFManager.RegSaveVisitor(TVisClient_Create);
  GTIOPFManager.RegSaveVisitor(TVisClient_Update);
  GTIOPFManager.RegSaveVisitor(TVisClient_Delete);
end;

{ TVisClient_Read }

function TVisClient_Read.AcceptVisitor: boolean;
begin
  result:= (Visited is TClients) and
            (Visited.ObjectState = posEmpty);
  Log([ClassName, Visited.ClassName, Visited.ObjectStateAsString, Result ]);
end;

procedure TVisClient_Read.Init;
var lCriteriaWhere: string;
  lClients: TClients;
begin
  lClients:= (Visited as TClients);
  if lClients.HasCriteria then
    lCriteriaWhere:= ' WHERE ' + tiCriteriaAsSQL(lClients.Criteria)
  else
    lCriteriaWhere:= '';

  Query.SQLText:=
    'select OID, Client_Name, Client_ID from Client' + lCriteriaWhere;
end;

procedure TVisClient_Read.MapRowToObject;
var
  lClient: TClient;
begin
  lClient:= TClient.Create;
  lClient.OID.AssignFromTIQuery('OID',Query);
  lClient.ClientName:= Query.FieldAsString['Client_Name'];
  lClient.ClientID:= Query.FieldAsString['Client_ID'];
  lClient.ObjectState:= posClean;
  TClients(Visited).Add(lClient);
end;

procedure TVisClient_Read.SetupParams;
begin
  // Do nothing
end;

{ TVisClient_Create }

function TVisClient_Create.AcceptVisitor: boolean;
begin
  result:= (Visited is TClient) and
            (Visited.ObjectState = posCreate);
  Log([ClassName, Visited.ClassName, Visited.ObjectStateAsString, Result ]);
end;

procedure TVisClient_Create.Init;
begin
  Query.SQLText:=
    'Insert into Client (OID, Client_Name, Client_ID) ' +
    'Values ' +
    '(:OID,:Client_Name,:Client_ID)';
end;

procedure TVisClient_Create.SetupParams;
var
  lData: TClient;
begin
  lData:= Visited as TClient;
  lData.OID.AssignToTIQuery('OID', Query);
  Query.ParamAsString['Client_Name']:= lData.ClientName;
  Query.ParamAsString['Client_ID']:= lData.ClientID;
end;

{ TVisClient_Update }

function TVisClient_Update.AcceptVisitor: boolean;
begin
  result:= (Visited is TClient) and
            (Visited.ObjectState = posUpdate);
  Log([ClassName, Visited.ClassName, Visited.ObjectStateAsString, Result ]);
end;

procedure TVisClient_Update.Init;
begin
  Query.SQLText:=
    'Update Client Set ' +
    '  Client_Name =:Client_Name ' +
    ' ,Client_ID =:Client_ID ' +
    'where ' +
    ' OID =:OID';
end;

procedure TVisClient_Update.SetupParams;
var
  lData: TClient;
begin
  lData:= Visited as TClient;
  lData.OID.AssignToTIQuery('OID', Query);
  Query.ParamAsString['Client_Name']:= lData.ClientName;
  Query.ParamAsString['Client_ID']:= lData.ClientID;
end;

{ TVisClient_Delete }

function TVisClient_Delete.AcceptVisitor: boolean;
begin
  result:= (Visited is TClient) and
            (Visited.ObjectState = posDelete);
  Log([ClassName, Visited.ClassName, Visited.ObjectStateAsString, Result ]);
end;

procedure TVisClient_Delete.Init;
begin
  Query.SQLText:=
    'delete from client where oid =:oid';
end;

procedure TVisClient_Delete.SetupParams;
var
  lData: TClient;
begin
  lData:= Visited as TClient;
  lData.OID.AssignToTIQuery('OID', Query);
end;

end.

