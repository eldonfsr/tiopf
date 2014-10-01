unit tiObjectCacheAbs;

interface
uses
  // tiOPF
  tiBaseObject
  ,tiDBConnectionPool
  ,tiQuery
  ,tiINI
  ,tiCGIParams
  // Delphi
  ,SysUtils
  ;

const
  cDBFileDateFieldName  = 'file_date' ;
  cCacheIndexFileName   = 'CacheIndex.ini' ;
  cCacheIndexINISection = 'CacheIndex';

type

  TtiObjectCacheAbs = class( TtiBaseObject )
  private
    FCacheIndex: TtiINIFile ;
    FCacheDirectoryRoot: String;
  protected
    property    CacheDirectoryRoot: string read FCacheDirectoryRoot;
    // ToDo: Rename to CacheIndexINIFile
    property    CacheIndex   : TtiINIFile read FCacheIndex;
    function    GetCachedFileDirAndName: string; virtual;
    function    MustUpdateCacheFile(const ADatabaseDate, AFileDate: TDateTime): Boolean; virtual;

    procedure   Init; virtual;
    function    GetDBFileDate: TDateTime ; virtual ;

    function    GetCachedFileDate: TDateTime ; virtual ;
    function    GetCachedFileSize: Longint ; virtual ;
    procedure   SetCachedFileDate(const AData: TDateTime); virtual;
    function    LockDBConnectionCreateQuery(var ADatabase: TtiDatabase): TtiQuery;

    // You MAY override these
    function    CacheDirectory: string ; virtual ;

    // You MUST override these
    procedure   RefreshCacheFromDB(const ACacheFileDate: TDateTime); virtual ; abstract ;
    function    CachedFileName: string ; virtual ;
    function    GetDBFileDataSQL: string ; virtual ;

  public
    constructor Create(const ACacheDirectoryRoot: string) ; virtual ;
    destructor  Destroy ; override ;
  end ;

implementation
uses
  //tiOPF
   tiOPFManager
  ,tiUtils
  ,tiExcept
  ,tiCGIExcept
  ,tiWebServerConstants
  ,tiConstants
  ;

{ TtiCGIOjectCacheAbs }

constructor TtiObjectCacheAbs.Create(const ACacheDirectoryRoot: string);
begin
  inherited Create;
  if ACacheDirectoryRoot <> '' then
    FCacheDirectoryRoot:= ACacheDirectoryRoot
  else
    FCacheDirectoryRoot:= ExpandFileName(tiAddTrailingSlash(tiGetEXEPath) + PathDelim + CPathToCachedDataRoot);
end;

destructor TtiObjectCacheAbs.Destroy;
begin
  FCacheIndex.Free ;
  inherited;
end;

function TtiObjectCacheAbs.GetCachedFileDate: TDateTime;
var
  lFileName: string;
begin
  Assert( FCacheIndex <> nil, 'FCacheIndex not assigned');
  lFileName := CachedFileName;
  Assert( lFileName <> '', 'CachedFileName not assigned');
  lFileName := ChangeFileExt(ExtractFileName(lFileName),'');
  Result := FCacheIndex.ReadDateTime(cCacheIndexINISection, lFileName, CMinFileDate);
end;

function TtiObjectCacheAbs.GetCachedFileSize: Longint;
begin
  result := tiGetFileSize(GetCachedFileDirAndName);
end;

procedure TtiObjectCacheAbs.SetCachedFileDate(const AData: TDateTime);
var
  lFileName: string;
begin
  Assert( FCacheIndex <> nil, 'FCacheIndex not assigned');
  lFileName := CachedFileName;
  Assert( lFileName <> '', 'CachedFileName not assigned');
  lFileName := ChangeFileExt(ExtractFileName(lFileName),'');
  FCacheIndex.WriteDateTime(cCacheIndexINISection, lFileName, AData);
  if AData <> 0 then
    tiSetFileDate(GetCachedFileDirAndName, AData);
end;

function TtiObjectCacheAbs.CachedFileName: string;
begin
  Assert(False, 'CachedFileName not overridden in ' + ClassName);
end;

function TtiObjectCacheAbs.CacheDirectory: string;
begin
  Result:= FCacheDirectoryRoot;
end;

function TtiObjectCacheAbs.LockDBConnectionCreateQuery(
  var ADatabase: TtiDatabase ): TtiQuery;
begin
  if not Assigned(GTIOPFManager.DefaultPerLayer) then
    raise EtiOPFProgrammerException.Create(
        'Default persistence layer not set. Add the appropriate tiQuery* ' +
        'unit(s) to your uses clause');

  if not Assigned(GTIOPFManager.DefaultPerLayer.DefaultDBConnectionPool) then
    raise EtiOPFProgrammerException.Create(
        'Default DB connection pool not set. Is a connection established?');

  ADatabase := GTIOPFManager.DefaultPerLayer.DefaultDBConnectionPool.Lock ;
  Assert(ADatabase.TestValid(TtiDatabase), CTIErrorInvalidObject);
  result := ADatabase.CreateTIQuery;
  Assert(result.TestValid(TtiQuery), CTIErrorInvalidObject);
  result.AttachDatabase(ADatabase);
end;

function TtiObjectCacheAbs.MustUpdateCacheFile(const ADatabaseDate,
  AFileDate: TDateTime): Boolean;
begin
  result:=
    (ADatabaseDate <> AFileDate) or
    (not FileExists(GetCachedFileDirAndName));
end;

function TtiObjectCacheAbs.GetDBFileDataSQL: string;
begin
  Assert(False, 'GetDBFileDataSQL not overridden in ' + ClassName);
end;

function TtiObjectCacheAbs.GetCachedFileDirAndName: string;
begin
  Assert( tiExtractExtension( CachedFileName ) <> '', 'CachedFileName missing a file extension');
  Result := tiAddTrailingSlash(CacheDirectory) + CachedFileName ;
end;

function TtiObjectCacheAbs.GetDBFileDate: TDateTime;
var
  LQuery    : TtiQuery;
  LDatabase : TtiDatabase;
begin
  LQuery := LockDBConnectionCreateQuery(LDatabase);
  try
    LQuery.SQLText := GetDBFileDataSQL ;
    LDatabase.StartTransaction;
    try
      LQuery.Open;
      try
        if LQuery.EOF then
        begin
          Result := 0 ;
          raise EtiCGIException.Create(cTICGIExitCodeNoDataReturnedFromGetLatestDateQuery);
        end;
        Result := LQuery.FieldAsDateTime[cDBFileDateFieldName];
      finally
        LQuery.Close ;
      end;
    finally
      LDatabase.Commit;
    end;
  finally
    LQuery.Free;
    GTIOPFManager.DefaultPerLayer.DefaultDBConnectionPool.UnLock(LDatabase) ;
  end;
end;

procedure TtiObjectCacheAbs.Init;
var
  lFileName : string;
begin
  lFileName := tiAddTrailingSlash(CacheDirectory) + cCacheIndexFileName;
  FCacheIndex := TtiINIFile.Create(lFileName);
end;

end.
