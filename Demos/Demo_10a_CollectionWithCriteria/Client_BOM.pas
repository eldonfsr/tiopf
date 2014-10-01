unit Client_BOM;

interface
uses
  tiObject
  ,tiFilteredObjectList
 ;

type

  TClient = class;
  TClients = class;

  TClientName = String[200];
  TClientID   = String[9];

  TClients = class(TtiFilteredObjectList)
  public
    procedure Read; override;
    procedure Save; override;
    // ToDo: Remove Criteria and HasCriteria and access them through ItiFiltered
    function HasCriteria: boolean;
    property Criteria;
  end;

  TClient = class(TtiObject)
  private
    FClientID: TClientID;
    FClientName: TClientName;
  public
    constructor CreateNew(const pDatabaseName: string = ''; const pPersistenceLayerName: string = ''); override;
  published
    property    ClientName: TClientName read FClientName write FClientName;
    property    ClientID  : TClientID read FClientID write FClientID;
  end;

implementation
uses
   tiOPFManager
  ,SysUtils
  ,Windows
 ;

{ TClient }

constructor TClient.CreateNew(const pDatabaseName: string = ''; const pPersistenceLayerName: string = '');
begin
  inherited;
  // Set some default values for the demo
  ClientID:= IntToStr(GetTickCount);

  ClientName:= Char(GetTickCount mod 26 + ord('A')) + DateTimeToStr(Now);
end;

{ TClients }

function TClients.HasCriteria: boolean;
begin
  result:= inherited HasCriteria;
end;

procedure TClients.Read;
begin
  inherited;
end;

procedure TClients.Save;
begin
  inherited;
end;

end.

