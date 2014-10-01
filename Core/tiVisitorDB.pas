{

  // Templates
  // Code template key combination: VR
  TVisXXX_Read = class(TtiVisitorSelect)
  protected
    function  AcceptVisitor : boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
    procedure MapRowToObject; override;
  end;

  // Code template key combination: VC
  TVisXXX_Create = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor : boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
  end;

  // Code template key combination: VU
  TVisXXX_Update = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor : boolean; override;
    procedure Init          ; override;
    procedure SetupParams   ; override;
  end;

  // Code template key combination: VD
  TVisXXX_Delete = class(TtiVisitorUpdate)
  protected
    function  AcceptVisitor : boolean; override;
    procedure Init         ; override;
  end;

}


unit tiVisitorDB;

{$I tiDefines.inc}

interface

uses
  tiBaseObject,
  tiVisitor,
  tiObject,
  tiPersistenceLayers,
//  tiDBConnectionPool,
  tiQuery,
  SysUtils,
  Classes;

const
  CErrorDefaultPersistenceLayerNotAssigned =
    'Attempt to connect to the default persistence layer, but the default persistence layer has not been assigned.';
  CErrorDefaultDatabaseNotAssigned         =
    'Attempt to connect to the default database but the default database has not been assigned.';
  CErrorAttemptToUseUnRegisteredPersistenceLayer =
    'Attempt to use unregistered persistence layer "%s"';
  CErrorAttemptToUseUnConnectedDatabase    = 'Attempt to use unconnected database "%s"';

type

  // A visitor manager for TVisDBAbs visitors
  TtiObjectVisitorController = class(TtiVisitorController)
  private
    FPersistenceLayer: TtiPersistenceLayer;
    FDatabase:         TtiDatabase;
  protected
    function TIOPFManager: TtiBaseObject; virtual;
    function PersistenceLayerName: string;
    function DatabaseName: string;
    property Database: TtiDatabase read FDatabase;
  public
    procedure BeforeExecuteVisitorGroup; override;
    procedure BeforeExecuteVisitor(const AVisitor: TtiVisitor); override;
    procedure AfterExecuteVisitor(const AVisitor: TtiVisitor); override;
    procedure AfterExecuteVisitorGroup(const ATouchedByVisitorList: TtiTouchedByVisitorList); override;
    procedure AfterExecuteVisitorGroupError; override;
  end;

  TtiObjectVisitorControllerConfig = class(TtiVisitorControllerConfig)
  private
    FDatabaseName:         string;
    FPersistenceLayerName: string;
  protected
    function TIOPFManager: TtiBaseObject; virtual;
  public
    property PersistenceLayerName: string read FPersistenceLayerName;
    property DatabaseName: string read FDatabaseName;
    procedure SetDatabaseAndPersistenceLayerNames(const APersistenceLayerName, ADBConnectionName: string);
  end;

  TtiObjectVisitorManager = class(TtiVisitorManager)
  public
    procedure Execute(const AGroupName: string; const AVisited: TtiVisited;
      const ADBConnectionName: string; const APersistenceLayerName: string = ''); reintroduce; overload;
    procedure Execute(const AGroupName: string; const AVisited: TtiVisited); reintroduce; overload;
  end;


  // Adds an owned query object
  // Note: It is not necessary to manually lock and unlock DBConnections
  // from this level and below - TtiObjectVisitorController does this for you.
  // Adds a pooled database connection
  TtiObjectVisitor = class(TtiVisitor)
  private
    FDatabase: TtiDatabase;
    FQuery:    TtiQuery;
    FPersistenceLayer: TtiPersistenceLayer;
    function GetQuery: TtiQuery;
    procedure SetQuery(const AValue: TtiQuery);
  protected
    function GetVisited: TtiObject; reintroduce;
    procedure SetVisited(const AValue: TtiObject); reintroduce; virtual;
    procedure LogQueryTiming(const AQueryName: string; const AQueryTime: integer;
      const AScanTime: integer);
    property PersistenceLayer: TtiPersistenceLayer read FPersistenceLayer write FPersistenceLayer;
    property Database: TtiDatabase read FDatabase write FDatabase;
    property Query: TtiQuery read GetQuery write SetQuery;

    // Override in your code
    procedure Init; virtual;
    procedure SetupParams; virtual;
    procedure UnInit; virtual;
    procedure Final(const AVisited: TtiObject); virtual;

  public
    constructor Create; override;
    destructor Destroy; override;
    class function VisitorControllerClass: TtiVisitorControllerClass; override;
    property Visited: TtiObject read GetVisited write SetVisited;
  end;

  // Don't use TVisOwnedQrySelectAbs as the parent for any of your visitors,
  // it's for internal tiOPF use only.
  TVisOwnedQrySelectAbs = class(TtiObjectVisitor)
  protected
    procedure BeforeRow; virtual;
    procedure MapRowToObject; virtual;
    procedure AfterRow; virtual;
    procedure OpenQuery; virtual; abstract;
  public
    procedure Execute(const AData: TtiVisited); override;
  end;


  TtiVisitorSelect = class(TVisOwnedQrySelectAbs)
  protected
    procedure OpenQuery; override;
  end;


  TtiVisitorUpdate = class(TtiObjectVisitor)
  protected
    procedure AfterExecSQL(const pRowsAffected:integer); virtual;
  public
    procedure Execute(const AData: TtiVisited); override;
  end;



implementation

uses
  tiUtils,
  tiLog,
  tiOPFManager,
  tiConstants,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF MSWINDOWS}
  tiExcept;


constructor TtiObjectVisitor.Create;
begin
  inherited;
end;

destructor TtiObjectVisitor.Destroy;
begin
  FQuery.Free;
  inherited;
end;

procedure TtiObjectVisitor.Final(const AVisited: TtiObject);
begin
  Assert(AVisited.TestValid, CTIErrorInvalidObject);
  case AVisited.ObjectState of
    posDeleted: ; // Do nothing
    posDelete: AVisited.ObjectState := posDeleted;
    else
      AVisited.ObjectState          := posClean;
  end;
end;

function TtiObjectVisitor.GetQuery: TtiQuery;
begin
  Assert(FQuery <> nil, 'FQuery not assigned');
  Result := FQuery;
end;

function TtiObjectVisitor.GetVisited: TtiObject;
begin
  Result := TtiObject(inherited GetVisited);
end;

procedure TtiObjectVisitor.Init;
begin
  // Do nothing
end;

procedure TtiObjectVisitor.UnInit;
begin
  // Do nothing
end;

procedure TtiObjectVisitor.LogQueryTiming(const AQueryName: string;
  const AQueryTime: integer; const AScanTime: integer);
var
  lClassName: string;
begin

  lClassName := ClassName;

  // We don't want to log access to the SQLManager queries, and this
  // is one possible way of blocking this.
  if SameText(lClassName, 'TVisReadGroupPK') or
    SameText(lClassName, 'TVisReadQueryPK') or
    SameText(lClassName, 'TVisReadQueryDetail') or
    SameText(lClassName, 'TVisReadParams') or
    SameText(lClassName, 'TVisReadQueryByName') then
    Exit; //==>

  Log(    {tiPadR(lClassName, cuiQueryTimingSpacing) +}
    tiPadR(AQueryName, 20) + ' ' +
    tiPadR(IntToStr(AQueryTime), 7) +
    tiPadR(IntToStr(AScanTime), 7),
    lsQueryTiming);

end;

procedure TtiObjectVisitor.SetQuery(const AValue: TtiQuery);
begin
  Assert(FQuery = nil, 'FQuery already assigned');
  FQuery := AValue;
end;

procedure TtiObjectVisitor.SetupParams;
begin
  // Do nothing
end;

procedure TtiObjectVisitor.SetVisited(const AValue: TtiObject);
begin
  inherited SetVisited(AValue);
end;

class function TtiObjectVisitor.VisitorControllerClass: TtiVisitorControllerClass;
begin
  Result := TtiObjectVisitorController;
end;

procedure TtiObjectVisitorController.AfterExecuteVisitorGroup(
  const ATouchedByVisitorList: TtiTouchedByVisitorList);
var
  i: integer;
  LTouchedByVisitor: TtiTouchedByVisitor;
  LVisitor: TtiObjectVisitor;
  LVisited: TtiObject;
begin
  FDatabase.Commit;
  for i := 0 to ATouchedByVisitorList.Count - 1 do
  begin
    LTouchedByVisitor := ATouchedByVisitorList.Items[i];
    LVisitor:= LTouchedByVisitor.Visitor as TtiObjectVisitor;
    LVisited:= LTouchedByVisitor.Visited as TtiObject;
    LVisitor.Final(LVisited);
  end;
  FPersistenceLayer.DBConnectionPools.UnLock(DatabaseName, FDatabase);
  FDatabase := nil;
end;

procedure TtiObjectVisitorController.AfterExecuteVisitorGroupError;
begin
  Assert(FDatabase.TestValid, CTIErrorInvalidObject);
  Assert(FPersistenceLayer.TestValid, CTIErrorInvalidObject);
  FDatabase.RollBack;
  FPersistenceLayer.DBConnectionPools.UnLock(DatabaseName, FDatabase);
  FDatabase := nil;
end;

procedure TtiObjectVisitorController.AfterExecuteVisitor(const AVisitor: TtiVisitor);
var
  LVisitor: TtiObjectVisitor;
begin
  Assert(AVisitor.TestValid(TtiObjectVisitor), CTIErrorInvalidObject);
  Assert(FDatabase.TestValid, CTIErrorInvalidObject);
  // ToDo: Refactor with SetDatabase method replacing AttachDatabase & DetachDatabase
  LVisitor          := AVisitor as TtiObjectVisitor;
  {$IFNDEF FPC}
  // Todo: This causes a "Transaction is not active" error using FBLib. Not sure
  //   if this error occurs with Delphi + FBLib as well.
  LVisitor.Query.DetachDatabase;
  {$ENDIF}
  LVisitor.Database := nil;
  LVisitor.PersistenceLayer:= nil;
end;

procedure TtiObjectVisitorController.BeforeExecuteVisitorGroup;
begin
  FPersistenceLayer := (TIOPFManager as TtiOPFManager).PersistenceLayers.FindByPersistenceLayerName(
    PersistenceLayerName);
  Assert(FPersistenceLayer <> nil, 'Unable to find RegPerLayer <' + PersistenceLayerName + '>');
  FDatabase         := FPersistenceLayer.DBConnectionPools.Lock(DatabaseName);
  FDatabase.StartTransaction;
end;

function TtiObjectVisitorController.DatabaseName: string;
begin
  Assert(Config.TestValid(TtiObjectVisitorControllerConfig), CTIErrorInvalidObject);
  Result := (Config as TtiObjectVisitorControllerConfig).DatabaseName;
end;

function TtiObjectVisitorController.PersistenceLayerName: string;
begin
  Assert(Config.TestValid(TtiObjectVisitorControllerConfig), CTIErrorInvalidObject);
  Result := (Config as TtiObjectVisitorControllerConfig).PersistenceLayerName;
end;

function TtiObjectVisitorController.TIOPFManager: TtiBaseObject;
begin
  Assert(VisitorManager.TestValid, CTIErrorInvalidObject);
  Result := VisitorManager.TIOPFManager;
end;

procedure TtiObjectVisitorController.BeforeExecuteVisitor(const AVisitor: TtiVisitor);
var
  LVisitor: TtiObjectVisitor;
begin
  Assert(AVisitor.TestValid(TtiObjectVisitor), CTIErrorInvalidObject);
  Assert(FDatabase.TestValid, CTIErrorInvalidObject);
  LVisitor          := AVisitor as TtiObjectVisitor;
  LVisitor.PersistenceLayer:= FPersistenceLayer;
  LVisitor.Database := FDatabase;
  LVisitor.Query    := FDatabase.CreateTIQuery;
  LVisitor.Query.AttachDatabase(FDatabase);
end;

procedure TVisOwnedQrySelectAbs.Execute(const AData: TtiVisited);

  procedure _ScanQuery;
  begin
    Query.ContinueScan := True;
    while (not Query.EOF) and
      (Query.ContinueScan) and
      (not GTIOPFManager.Terminated) do
    begin
      BeforeRow;
      MapRowToObject;
      AfterRow;
      Query.Next;
    end;
    Query.Close;
  end;

var
  liStart:     DWord;
  liQueryTime: DWord;
begin
  if GTIOPFManager.Terminated then
    Exit; //==>

  inherited Execute(AData);

  if not AcceptVisitor then
    Exit; //==>

  Assert(Database <> nil, 'DBConnection not set in ' + ClassName);

  if AData <> nil then
    Visited := TtiObject(AData)
  else
    Visited := nil;

  Init;
  try
    SetupParams;
    liStart := tiGetTickCount;
    OpenQuery;
    try
      liQueryTime := tiGetTickCount - liStart;
      liStart := tiGetTickCount;
      _ScanQuery;
      LogQueryTiming(ClassName, liQueryTime, tiGetTickCount - liStart);
    finally
      Query.Close;
    end;
  finally
    UnInit;
  end;
end;

procedure TVisOwnedQrySelectAbs.BeforeRow;
begin
  // Do nothing
end;

procedure TVisOwnedQrySelectAbs.MapRowToObject;
begin
  raise Exception.Create('MapRowToObject has not been ' +
    'overridden in the concrete: ' + ClassName);
end;

procedure TVisOwnedQrySelectAbs.AfterRow;
begin
  // Do nothing
end;

procedure TtiVisitorUpdate.AfterExecSQL(const pRowsAffected: integer);
begin
  // this gets called only if FQuery.SupportsRowsAffected

  // implement in concrete visitor
  // You can do something like:
  // if pRowsAffected=0 then raise ERecordAlreadyChanged.Create('Another user changed row.');
end;

procedure TtiVisitorUpdate.Execute(const AData: TtiVisited);
var
  lStart: DWord;
  lRowsAffected: integer;
begin
  if GTIOPFManager.Terminated then
    Exit; //==>
  inherited Execute(AData);
  if not AcceptVisitor then
    exit; //==>
  Init;
  try
    lStart := tiGetTickCount;
    SetupParams;
    lRowsAffected := Query.ExecSQL;
    if FQuery.SupportsRowsAffected then AfterExecSQL(lRowsAffected);
    LogQueryTiming(ClassName, tiGetTickCount - lStart, 0);
  finally
    UnInit;
  end;
end;

procedure TtiVisitorSelect.OpenQuery;
begin
  if GTIOPFManager.Terminated then
    Exit; //==>
  Query.Open;
end;

{ TtiObjectVisitorManager }

procedure TtiObjectVisitorManager.Execute(const AGroupName: string;
  const AVisited: TtiVisited; const ADBConnectionName: string;
  const APersistenceLayerName: string);
var
  FVisitorControllerConfig: TtiObjectVisitorControllerConfig;
begin
  FVisitorControllerConfig := TtiObjectVisitorControllerConfig.Create(Self);
  try
    FVisitorControllerConfig.SetDatabaseAndPersistenceLayerNames(APersistenceLayerName,
      ADBConnectionName);
    ProcessVisitors(AGroupName, AVisited, FVisitorControllerConfig);
  finally
    FVisitorControllerConfig.Free;
  end;
end;

procedure TtiObjectVisitorManager.Execute(const AGroupName: string;
  const AVisited: TtiVisited);
begin
  Execute(AGroupName, AVisited, '', '');
end;

{ TtiObjectVisitorControllerConfig }

procedure TtiObjectVisitorControllerConfig.SetDatabaseAndPersistenceLayerNames(
  const APersistenceLayerName, ADBConnectionName: string);
var
  LTIOPFManager: TtiOPFManager;
begin
  LTIOPFManager := TtiOPFManager(TIOPFManager);

  if APersistenceLayerName = '' then
  begin
    if not Assigned(TtiOPFManager(TIOPFManager).DefaultPerLayer) then
      raise EtiOPFDataException.Create(CErrorDefaultPersistenceLayerNotAssigned);
    FPersistenceLayerName := LTIOPFManager.DefaultPerLayer.PersistenceLayerName;
  end
  else
    FPersistenceLayerName := APersistenceLayerName;

  if ADBConnectionName = '' then
  begin
    if not Assigned(TtiOPFManager(TIOPFManager).DefaultDBConnectionPool) then
      raise EtiOPFDataException.Create(CErrorDefaultDatabaseNotAssigned);
    FDatabaseName := LTIOPFManager.DefaultDBConnectionName;
  end
  else
    FDatabaseName := ADBConnectionName;

  if not LTIOPFManager.PersistenceLayers.IsLoaded(FPersistenceLayerName) then
    raise EtiOPFDataException.CreateFmt(CErrorAttemptToUseUnRegisteredPersistenceLayer,
      [FPersistenceLayerName])
  else if not LTIOPFManager.PersistenceLayers.FindByPersistenceLayerName(
    FPersistenceLayerName).DBConnectionPools.IsConnected(FDatabaseName) then
    raise EtiOPFDataException.CreateFmt(CErrorAttemptToUseUnConnectedDatabase, [FDatabaseName]);

end;

function TtiObjectVisitorControllerConfig.TIOPFManager: TtiBaseObject;
begin
  Assert(VisitorManager.TestValid, CTIErrorInvalidObject);
  Result := VisitorManager.TIOPFManager;
end;

end.
