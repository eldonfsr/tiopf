unit Client_BOM;

interface
uses
  tiObject
  ,Classes
 ;

const
  cErrorClientName    = 'Please enter a client name';
  cErrorClientSource  = 'Please select a client source';

type

  TClientSources = class;
  TClientSource  = class;
  TClient        = class;
  TClients       = class;

  TClientName = String[200];

  TClients = class(TtiObjectList)
  private
  protected
    function    GetItems(i: integer): TClient; reintroduce;
    procedure   SetItems(i: integer; const Value: TClient); reintroduce;
  public
    procedure   Read; override;
    procedure   Save; override;
    property    Items[i:integer]: TClient read GetItems write SetItems;
    procedure   Add(AObject: TClient); reintroduce;
  end;

  TClient = class(TtiObject)
  private
    FClientName: TClientName;
    FClientSource: TClientSource;
    function    GetClientSouceAsGUIString: string;
    function    GetClientSourceOIDAsString: string;
    procedure   SetClientSourceAsGUIString(const Value: string);
    procedure   SetClientSourceOIDAsString(const Value: string);
  protected
    function    GetOwner: TClients; reintroduce;
    procedure   SetOwner(const Value: TClients); reintroduce;
  public
    constructor Create; override;
    property    Owner      : TClients             read GetOwner      write SetOwner;
    function    IsValid(const AErrors: TtiObjectErrors): boolean; override;
    property    ClientSource: TClientSource read FClientSource write FClientSource;
  published
    property    ClientName: TClientName read FClientName write FClientName;
    property    ClientSourceOIDAsString : string read GetClientSourceOIDAsString write SetClientSourceOIDAsString;
    property    ClientSourceAsGUIString : string read GetClientSouceAsGUIString  write SetClientSourceAsGUIString;
  end;

  TClientSources = class(TtiObjectList)
  private
  protected
    function    GetItems(i: integer): TClientSource; reintroduce;
    procedure   SetItems(i: integer; const Value: TClientSource); reintroduce;
  public
    procedure   Read; override;
    procedure   Save; override;
    property    Items[i:integer]: TClientSource read GetItems write SetItems;
    procedure   Add(AObject: TClientSource); reintroduce;
    function    Find(pOIDToFindAsString: string): TClientSource;  reintroduce;
    function    FindByDisplayText(const pValue: string): TClientSource;
    function    Unknown: TClientSource;
  published
  end;

  TClientSource = class(TtiObject)
  private
    FDisplayText: string;
  protected
    function    GetOwner: TClientSources; reintroduce;
    procedure   SetOwner(const Value: TClientSources); reintroduce;
  public
    property    Owner      : TClientSources             read GetOwner      write SetOwner;
  published
    property    DisplayText: string read FDisplayText write FDisplayText;
  end;

procedure RegisterMappings;
function  gClientSources: TClientSources;

implementation
uses
  tiOPFManager
  ,tiAutoMap
  ,SysUtils
 ;

var
  uClientSources: TClientSources;


procedure RegisterMappings;
begin
  GTIOPFManager.ClassDBMappingMgr.RegisterMapping(TClientSource, 'Client_Source', 'OID', 'OID', [pktDB]);
  GTIOPFManager.ClassDBMappingMgr.RegisterMapping(TClientSource, 'Client_Source', 'DisplayText', 'Display_Text');
  GTIOPFManager.ClassDBMappingMgr.RegisterCollection(TClientSources, TClientSource);

  GTIOPFManager.ClassDBMappingMgr.RegisterMapping(TClient, 'Client', 'OID', 'OID', [pktDB]);
  GTIOPFManager.ClassDBMappingMgr.RegisterMapping(TClient, 'Client', 'ClientName', 'Client_Name');
  GTIOPFManager.ClassDBMappingMgr.RegisterMapping(TClient, 'Client', 'ClientSourceOIDAsString', 'Client_Source');
  GTIOPFManager.ClassDBMappingMgr.RegisterCollection(TClients, TClient);
end;

function  gClientSources: TClientSources;
begin
  if uClientSources = nil then
  begin
    uClientSources:= TClientSources.Create;
    uClientSources.Read;
  end;
  result:= uClientSources;
end;

{ TClients }

procedure TClients.Add(AObject: TClient);
begin
  inherited Add(AObject);
end;

function TClients.GetItems(i: integer): TClient;
begin
  result:= TClient(inherited GetItems(i));
end;

procedure TClients.Read;
begin
  inherited;
end;

procedure TClients.Save;
begin
  inherited;
end;

procedure TClients.SetItems(i: integer; const Value: TClient);
begin
  inherited SetItems(i, Value);
end;

{ TClient }

constructor TClient.create;
begin
  inherited;
  FClientSource:= nil;
end;

function TClient.GetClientSouceAsGUIString: string;
begin
  if FClientSource = nil then
    result:= ''
  else
    result:= FClientSource.DisplayText;
end;

function TClient.GetClientSourceOIDAsString: string;
begin
  if FClientSource = nil then
    result:= ''
  else
    result:= FClientSource.OID.AsString;
end;

function TClient.GetOwner: TClients;
begin
  result:= TClients(inherited GetOwner);
end;

function TClient.IsValid(const AErrors: TtiObjectErrors): boolean;
begin
  inherited IsValid(AErrors);

  if ClientName = '' then
    AErrors.AddError('ClientName', cErrorClientName);

  if (FClientSource = nil) or
     (FClientSource = gClientSources.Unknown) then
    AErrors.AddError('ClientSource', cErrorClientSource);

  result:= AErrors.Count = 0;

end;

procedure TClient.SetClientSourceAsGUIString(const Value: string);
begin
  FClientSource:= gClientSources.FindByDisplayText(Value);
end;

procedure TClient.SetClientSourceOIDAsString(const Value: string);
begin
  FClientSource:= gClientSources.Find(Value);
end;

procedure TClient.SetOwner(const Value: TClients);
begin
  inherited SetOwner(Value);
end;

{ TClientSources }

procedure TClientSources.Add(AObject: TClientSource);
begin
  inherited Add(AObject);
end;

function TClientSources.Find(pOIDToFindAsString: string): TClientSource;
begin
  if pOIDToFindAsString = '' then
    result:= nil
  else
    result:= TClientSource(inherited Find(pOIDToFindAsString));
end;

function TClientSources.FindByDisplayText(const pValue: string): TClientSource;
var
  i: integer;
begin
  result:= nil;
  for i:= 0 to Count - 1 do
    if SameText(Items[i].DisplayText, pValue) then
    begin
      result:= Items[i];
      Exit; //==>
    end;
end;

function TClientSources.GetItems(i: integer): TClientSource;
begin
  result:= TClientSource(inherited GetItems(i));
end;

procedure TClientSources.Read;
begin
  inherited;
end;

procedure TClientSources.Save;
begin
  inherited;
end;

procedure TClientSources.SetItems(i: integer; const Value: TClientSource);
begin
  inherited SetItems(i, Value);
end;

function TClientSources.Unknown: TClientSource;
var
  i: integer;
begin
  result:= nil;
  for i:= 0 to Count - 1 do
    if SameText(Items[i].DisplayText, 'Unknown') then
    begin
      result:= Items[i];
      Exit; //==>
    end;
end;

{ TClientSource }

function TClientSource.GetOwner: TClientSources;
begin
  result:= TClientSources(inherited GetOwner);
end;

procedure TClientSource.SetOwner(const Value: TClientSources);
begin
  inherited SetOwner(Value);
end;

initialization
finalization
  uClientSources.Free;

end.




