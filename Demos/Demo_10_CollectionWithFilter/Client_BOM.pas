unit Client_BOM;

interface
uses
  tiObject
  ,tiOIDGUID
 ;

type

  TClient = class;
  TClients = class;
  TClientsLike = class;

  TClientsLike = class(TtiObject)
  private
    FClientNameLike: string;
    FClients: TClients;
  public
    property ClientNameLike: string read FClientNameLike write FClientNameLike;
    property Clients: TClients read FClients write FClients;
    procedure Read; override;
  end;

  TClients = class(TtiObjectList)
  public
    procedure Save; override;
  end;

  TClient = class(TtiObject)
  private
    FClientID: string;
    FClientName: string;
  public
    constructor CreateNew(const pDatabaseName: string = ''; const pPersistenceLayerName: string = ''); override;
  published
    property    ClientName: string read FClientName write FClientName;
    property    ClientID  : string read FClientID write FClientID;
  end;

implementation
uses
   tiOPFManager
  ,tiConstants
  ,SysUtils
  ,Windows
 ;

{ TClient }

constructor TClient.CreateNew(const pDatabaseName: string = ''; const pPersistenceLayerName: string = '');
begin
  inherited;
  // Set some default values for the demo
  ClientName:= 'TEST ' + DateTimeToStr(Now);
  ClientID:= IntToStr(GetTickCount);
end;

{ TClientsLike }

procedure TClientsLike.Read;
begin
  Assert(FClients.TestValid, CTIErrorInvalidObject);
  Assert(ClientNameLike<>'', 'ClientNameLike not assigned');
  FClients.Clear;
  inherited;
end;

{ TClients }

procedure TClients.Save;
begin
  inherited;
end;

end.

