{
  This persistence layer uses the FBLib 0.85 Firebird Library of components.
  See [http://fblib.altervista.org] for more details.

  FBLib runs under Delphi, Kylix and Free Pascal.  FBLib also has support for
  the Firebird Services. Remote backup and restore, Stats, User maintenance,
  etc...

  eg:
    GTIOPFManager.ConnectDatabase('192.168.0.20:E:\Databases\Test.fdb',
        'sysdba', 'masterkey', '');
   or

    GTIOPFManager.ConnectDatabase('192.168.0.20:/data/test.fdb',
        'sysdba', 'masterkey', '');


  Author:  Graeme Geldenhuys (graemeg@gmail.com) - Feb 2006
}
unit tiQueryFBL;

{$I tiDefines.inc}

// The modified FBLib 0.85 is now available in the Source/3rdParty directory
{$Define FBL_Params_Mod}

interface
uses
  tiQuery
  ,Classes
  ,FBLDatabase
  ,FBLParamDsql
  ,FBLTransaction
  ,ibase_h
  ,tiDBConnectionPool
  ,tiObject
  ,tiPersistenceLayers
 ;

type

  TtiPersistenceLayerFBL = class(TtiPersistenceLayer)
  protected
    function GetPersistenceLayerName: string; override;
    function GetDatabaseClass: TtiDatabaseClass; override;
    function GetQueryClass: TtiQueryClass; override;
  public
    procedure AssignPersistenceLayerDefaults(const APersistenceLayerDefaults: TtiPersistenceLayerDefaults); override;
  end;

  TtiDatabaseFBL = class(TtiDatabaseSQL)
  private
    FDBase: TFBLDatabase;
    FTrans: TFBLTransaction;
  protected
    procedure   SetConnected(AValue: boolean); override;
    function    GetConnected: boolean; override;
    function    FieldMetaDataToSQLCreate(const AFieldMetaData: TtiDBMetaDataField): string; override;
  public
    constructor Create; override;
    destructor  Destroy; override;
    class function  DatabaseExists(const ADatabaseName, AUserName, APassword: string; const AParams: string = ''): boolean; override;
    class procedure CreateDatabase(const ADatabaseName, AUserName, APassword: string; const AParams: string = ''); override;
    class procedure DropDatabase(const ADatabaseName, AUserName, APassword: string; const AParams: string = ''); override;
    property    IBDatabase: TFBLDatabase read FDBase write FDBase;
    procedure   StartTransaction; override;
    function    InTransaction: boolean; override;
    procedure   Commit; override;
    procedure   RollBack; override;
    procedure   ReadMetaDataTables(AData: TtiDBMetaData); override;
    procedure   ReadMetaDataFields(AData: TtiDBMetaDataTable); override;
    function    Test: boolean; override;
    function    TIQueryClass: TtiQueryClass; override;
  end;


  TtiQueryFBL = class(TtiQuerySQL)
  private
    FQuery: TFBLParamDsql;    // handles params as names
    FbActive: boolean;
    function  IBFieldKindToTIFieldKind(AData: TXSQLVar): TtiQueryFieldKind;
    procedure Prepare;
    procedure LogParams;
  protected
    function  GetFieldAsString(const AName: string): string; override;
    function  GetFieldAsFloat(const AName: string): extended; override;
    function  GetFieldAsBoolean(const AName: string): boolean; override;
    function  GetFieldAsInteger(const AName: string): Int64; override;
    function  GetFieldAsDateTime(const AName: string): TDateTime; override;

    function  GetFieldAsStringByIndex(AIndex: Integer): string; override;
    function  GetFieldAsFloatByIndex(AIndex: Integer): extended; override;
    function  GetFieldAsBooleanByIndex(AIndex: Integer): boolean; override;
    function  GetFieldAsIntegerByIndex(AIndex: Integer): Int64; override;
    function  GetFieldAsDateTimeByIndex(AIndex: Integer): TDateTime; override;
    function  GetFieldIsNullByIndex(AIndex: Integer): Boolean; override;

    function  GetSQL: TStrings; override;
    procedure SetSQL(const AValue: TStrings); override;
    function  GetActive: boolean; override;
    procedure SetActive(const AValue: boolean); override;
    function  GetEOF: boolean; override;
    function  GetParamAsString(const AName: string): string; override;
    function  GetParamAsBoolean(const AName: string): boolean; override;
    function  GetParamAsFloat(const AName: string): extended; override;
    function  GetParamAsInteger(const AName: string): Int64; override;
    function  GetParamAsDateTime(const AName: string): TDateTime; override;
    function  GetParamAsTextBLOB(const AName: string): string; override;
    function  GetParamIsNull(const AName: string): Boolean; override;
    procedure SetParamAsString(const AName, AValue: string); override;
    procedure SetParamAsBoolean(const AName: string; const AValue: boolean); override;
    procedure SetParamAsFloat(const AName: string; const AValue: extended); override;
    procedure SetParamAsInteger(const AName: string; const AValue: Int64); override;
    procedure SetParamAsDateTime(const AName: string; const AValue: TDateTime); override;
    procedure SetParamAsTextBLOB(const AName, AValue: string); override;
    procedure SetParamIsNull(const AName: string; const AValue: Boolean); override;
    function  GetFieldIsNull(const AName: string): Boolean; override;
  public
    constructor Create; override;
    destructor  Destroy; override;
    procedure   Open; override;
    procedure   Close; override;
    procedure   Next; override;
    function    ExecSQL: integer; override;

    function    ParamCount: integer; override;
    function    ParamName(AIndex: integer): string; override;
    function    ParamsAsStringList: TStringList;

    procedure   AssignParamFromStream(const AName: string; const AStream: TStream); override;
    procedure   AssignParamToStream(const AName: string; const AStream: TStream); override;
    procedure   AssignFieldAsStream(const AName: string; const AStream: TStream); override;
    procedure   AssignFieldAsStreamByIndex(AIndex: integer; const AValue: TStream); override;
    procedure   AssignParams(const AParams: TtiQueryParams; const AWhere: TtiQueryParams = nil); override;

    procedure   AttachDatabase(ADatabase: TtiDatabase); override;
    procedure   DetachDatabase; override;
    procedure   Reset; override;

    function    FieldCount: integer; override;
    function    FieldName(AIndex: integer): string; override;
    function    FieldIndex(const AName: string): integer; override;
    function    FieldKind(AIndex: integer): TtiQueryFieldKind; override;
    function    FieldSize(AIndex: integer): integer; override;
    function    HasNativeLogicalType: boolean; override;
  end;


implementation
uses
   tiUtils
  ,tiLog
  ,TypInfo
  ,tiOPFManager
  ,tiConstants
  ,tiExcept
  ,SysUtils
  ,Variants
  ,FBLExcept
 ;


{ TtiQueryFBL }

constructor TtiQueryFBL.Create;
begin
  inherited;
  FQuery := TFBLParamDsql.Create(nil);
end;

destructor TtiQueryFBL.Destroy;
begin
  FQuery.Free;
  inherited;
end;

procedure TtiQueryFBL.Close;
begin
  Active := false;
end;

function TtiQueryFBL.ExecSQL: integer;
begin
  Log(ClassName + ': [Prepare] ' + tiNormalizeStr(self.SQLText), lsSQL);
  Prepare;
  LogParams;
  FQuery.ExecSQL;
  Result := -1;
  { TODO :
When implementing RowsAffected,
please return correct result
and put FSupportsRowsAffected := True; in TtiQueryXXX.Create;}
end;

function TtiQueryFBL.GetFieldAsBoolean(const AName: string): boolean;
var
  lsValue: string;
begin
  lsValue := Trim(upperCase(FQuery.FieldByNameAsString(UpperCase(AName))));
  result := (lsValue = 'T') or
    (lsValue = 'TRUE') or
    (lsValue = 'Y') or
    (lsValue = 'YES') or
    (lsValue = '1');
end;

function TtiQueryFBL.GetFieldAsDateTime(const AName: string): TDateTime;
begin
  result := FQuery.FieldByNameAsDateTime(UpperCase(AName));
end;

function TtiQueryFBL.GetFieldAsFloat(const AName: string): extended;
begin
  result := FQuery.FieldByNameAsDouble(UpperCase(AName));
end;

function TtiQueryFBL.GetFieldAsInteger(const AName: string): Int64;
begin
  result := FQuery.FieldByNameAsInt64(UpperCase(AName));
end;

function TtiQueryFBL.GetFieldAsString(const AName: string): string;
begin
  result := FQuery.FieldByNameAsString(UpperCase(AName));
end;

function TtiQueryFBL.GetFieldAsStringByIndex(AIndex: Integer): string;
begin
  Result := FQuery.FieldAsString(AIndex);
end;

function TtiQueryFBL.GetFieldAsFloatByIndex(AIndex: Integer): extended;
begin
  Result := FQuery.FieldAsFloat(AIndex);
end;

function TtiQueryFBL.GetFieldAsBooleanByIndex(AIndex: Integer): boolean ;
var
  lsValue: string;
begin
  lsValue := Trim(FQuery.FieldAsString(AIndex));
  result := (lsValue = 'T') or
    (lsValue = 'TRUE') or
    (lsValue = 'Y') or
    (lsValue = 'YES') or
    (lsValue = '1');
end;

function TtiQueryFBL.GetFieldAsIntegerByIndex(AIndex: Integer): Int64;
begin
  Result := FQuery.FieldAsInt64(AIndex);
end;

function TtiQueryFBL.GetFieldAsDateTimeByIndex(AIndex: Integer): TDateTime;
begin
  Result := FQuery.FieldAsDateTime(AIndex);
end;

function TtiQueryFBL.GetFieldIsNullByIndex(AIndex: Integer): Boolean;
begin
  Result := FQuery.FieldIsNull(AIndex);
end;

function TtiQueryFBL.GetActive: boolean;
begin
  result := FbActive;
end;

function TtiQueryFBL.GetEOF: boolean;
begin
  result := FQuery.EOF;
end;

function TtiQueryFBL.GetParamAsBoolean(const AName: string): boolean;
var
  i: integer;
  lBoolStr: string;
begin
  i := FQuery.ParamNameToIndex(AName);
  lBoolStr := FQuery.ParamValueAsString(i);
  Result := (lBoolStr = 'T') or
    (lBoolStr = 'TRUE') or
    (lBoolStr = 'Y') or
    (lBoolStr = 'YES') or
    (lBoolStr = '1');
end;

function TtiQueryFBL.GetParamAsFloat(const AName: string): extended;
var
  i: integer;
begin
  i := FQuery.ParamNameToIndex(AName);
  if i >= 0 then
    result := StrToFloat(FQuery.ParamValueAsString(i))
  else
    Result := 0;
end;

function TtiQueryFBL.GetParamAsInteger(const AName: string): Int64;
var
  i: integer;
begin
  i := FQuery.ParamNameToIndex(AName);
  if i >= 0 then
    result := StrToInt(FQuery.ParamValueAsString(i))
  else
    Result := 0;
end;

function TtiQueryFBL.GetParamAsDateTime(const AName: string): TDateTime;
var
  i: integer;
begin
  i := FQuery.ParamNameToIndex(AName);
  if i >= 0 then
    result := tiIntlDateStorAsDateTime(FQuery.ParamValueAsString(i))
  else
    Result := 0;
end;

function TtiQueryFBL.GetParamAsTextBLOB(const AName: string): string;
var
  i: integer;
begin
  i := FQuery.ParamNameToIndex(AName);
  if i >= 0 then
    result := FQuery.ParamValueAsString(i)
  else
    result := '';
end;

function TtiQueryFBL.GetParamAsString(const AName: string): string;
var
  i: integer;
begin
  i := FQuery.ParamNameToIndex(AName);
  if i >= 0 then
    result := FQuery.ParamValueAsString(i)
  else
    result := '';
end;

function TtiQueryFBL.GetSQL: TStrings;
begin
  result := FQuery.SQL;
end;

procedure TtiQueryFBL.Next;
begin
  FQuery.Next;
end;

procedure TtiQueryFBL.Open;
begin
  Log(ClassName + ': ' + tiNormalizeStr(self.SQLText), lsSQL);
  LogParams;
  Active := true;
end;

function TtiQueryFBL.ParamCount: integer;
begin
  Result := FQuery.ParamCount;
end;

function TtiQueryFBL.ParamName(AIndex: integer): string;
begin
  Result := FQuery.ParamName(AIndex);
end;

function TtiQueryFBL.ParamsAsStringList: TStringList;
var
  i: integer;
  s: string;
begin
  result := TStringList.Create;
  try
    for i := 0 to ParamCount-1 do
    begin
      if ParamIsNull[ ParamName(i)] then      // Display the fact
        s := 'Null'
      else
        s := ParamAsString[ParamName(i)];
      result.Add(ParamName(i) + '=' + s);
    end;
  except
    on e: exception do
      LogError(e, true);
  end;
end;

procedure TtiQueryFBL.SetActive(const AValue: boolean);
begin
  Assert(Database.TestValid(TtiDatabase), CTIErrorInvalidObject);
  if AValue then
  begin
    FQuery.ExecSQL;
    FbActive := true;
  end else
  begin
    FQuery.Close;
    FbActive := false;
  end;
end;

procedure TtiQueryFBL.SetParamAsBoolean(const AName: string; const AValue: boolean);
begin
  Prepare;
{$IFDEF BOOLEAN_CHAR_1}
  if AValue then
    FQuery.ParamByNameAsString(AName, 'T')
  else
    FQuery.ParamByNameAsString(AName, 'F');
{$ELSE}
  {$IFDEF BOOLEAN_NUM_1}
    if AValue then
      FQuery.ParamByNameAsInt64(AName, 1)
    else
      FQuery.ParamByNameAsInt64(AName, 0);
  {$ELSE}
    if AValue then
      FQuery.ParamByNameAsString(AName, 'TRUE')
    else
      FQuery.ParamByNameAsString(AName, 'FALSE');
  {$ENDIF}
{$ENDIF BOOLEAN_CHAR_1}
end;

procedure TtiQueryFBL.SetParamAsFloat(const AName: string; const AValue: extended);
begin
  Prepare;
  FQuery.ParamByNameAsDouble(AName, AValue);
end;

procedure TtiQueryFBL.SetParamAsInteger(const AName: string; const AValue: Int64);
begin
  Prepare;
  FQuery.ParamByNameAsInt64(AName, AValue);
end;

procedure TtiQueryFBL.SetParamAsDateTime(const AName: string; const AValue: TDateTime);
begin
  Prepare;
  FQuery.ParamByNameAsDateTime(AName, AValue);
end;

procedure TtiQueryFBL.SetParamAsTextBLOB(const AName, AValue: string);
begin
  Prepare;
  FQuery.BlobParamByNameAsString(AName, AValue);
end;

procedure TtiQueryFBL.SetParamAsString(const AName, AValue: string);
begin
  Prepare;
  FQuery.ParamByNameAsString(AName, AValue);
end;

procedure TtiQueryFBL.SetSQL(const AValue: TStrings);
begin
  FQuery.SQL.Assign(AValue);
end;

procedure TtiQueryFBL.Prepare;
begin
  if FQuery.Prepared then
    Exit; //==>
  FQuery.Prepare;
end;

procedure TtiQueryFBL.LogParams;
const
  cLogLine = '%s: [Param %d] %s = %s';
var
  sl: TStringList;
  i: integer;
begin
  sl := ParamsAsStringList;
  try
    for i := 0 to sl.Count-1 do
      Log(Format(cLogLine, [ClassName, i+1, sl.Names[i], sl.ValueFromIndex[i]]), lsSQL);
  finally
    sl.Free;
  end;
end;

procedure TtiQueryFBL.AssignParamFromStream(const AName: string; const AStream: TStream);
begin
  Assert(AStream <> nil, 'Stream not assigned');
  AStream.Position := 0;
  Prepare;
  FQuery.BlobParamByNameLoadFromStream(UpperCase(AName), AStream);
end;

procedure TtiQueryFBL.AssignParamToStream(const AName: string; const AStream: TStream);
begin
  raise EtiOPFInternalException.Create('FBLib does not support AssignParamToStream yet.');
  Assert(AStream <> nil, 'Stream not assigned');
//  FQuery.Params.ByName(UpperCase(AName)).SaveToStream(AStream);
  AStream.Position := 0;
end;

procedure TtiQueryFBL.AssignFieldAsStream(const AName: string; const AStream: TStream);
begin
  Assert(AStream <> nil, 'Stream not assigned');
  AStream.Position := 0;
  FQuery.BlobFieldByNameSaveToStream(AName, AStream);
end;

procedure TtiQueryFBL.AssignFieldAsStreamByIndex(AIndex : integer; const AValue : TStream);
begin
  Assert(AValue <> nil, 'Stream not assigned');
  AValue.Position := 0;
  FQuery.BlobFieldSaveToStream(AIndex, AValue);
end;

// ToDo: Shouldn't this be in the abstract?
procedure TtiQueryFBL.AssignParams(const AParams: TtiQueryParams;
  const AWhere: TtiQueryParams);
begin
  if AParams = nil then
    Exit;
  Prepare;
  inherited;
end;

procedure TtiQueryFBL.AttachDatabase(ADatabase: TtiDatabase);
begin
  inherited AttachDatabase(ADatabase);
  FQuery.Transaction := TtiDatabaseFBL(ADatabase).FTrans;
end;

procedure TtiQueryFBL.DetachDatabase;
begin
  inherited DetachDatabase;
  FQuery.Transaction := nil;
end;

function TtiQueryFBL.FieldCount: integer;
begin
  if FQuery.EOF then
    result := 0
  else
    Result := FQuery.FieldCount;
end;

function TtiQueryFBL.FieldName(AIndex: integer): string;
begin
  Result := FQuery.FieldName(AIndex);
end;

procedure TtiQueryFBL.Reset;
begin
  Active := false;
  FQuery.SQL.Clear;
end;

function TtiQueryFBL.FieldIndex(const AName: string): integer;
var
  i: integer;
begin
  Result:= -1;
  for i := 0 to FQuery.FieldCount - 1 do
  begin
    if SameText(AName, FQuery.FieldName(i)) then
    begin
      Result := i;
      Exit;
    end;
  end;
end;


{ TtiDatabaseFBL }

constructor TtiDatabaseFBL.Create;
begin
  inherited Create;
  FDBase := TFBLDatabase.Create(nil);
  FTrans := TFBLTransaction.Create(nil);
  FDBase.SQLDialect  := 3;
  FDBase.Protocol    := ptTcpIp;
  FTrans.Database    := FDBase;
end;

destructor TtiDatabaseFBL.Destroy;
begin
  try
    FTrans.Free;
    FDBase.Free;
  except
    on e: exception do
      LogError(e.message);
  end;
  inherited;
end;

procedure TtiDatabaseFBL.Commit;
begin
  if not InTransaction then
    raise EtiOPFInternalException.Create('Attempt to commit but not in a transaction.');
  Log(ClassName + ': [Commit Trans]', lsSQL);
  FTrans.Commit;
end;

function TtiDatabaseFBL.InTransaction: boolean;
begin
  Result := FTrans.InTransaction;
end;

procedure TtiDatabaseFBL.RollBack;
begin
  Log(ClassName + ': [RollBack Trans]', lsSQL);
  FTrans.RollBack;
end;

procedure TtiDatabaseFBL.StartTransaction;
begin
  if InTransaction then
    raise EtiOPFInternalException.Create('Attempt to start a transaction but transaction already exists.');
  Log(ClassName + ': [Start Trans]', lsSQL);
  FTrans.StartTransaction;
end;

function TtiQueryFBL.FieldKind(AIndex: integer): TtiQueryFieldKind;
var
  lValue: string;
begin
  Result := IBFieldKindToTIFieldKind(FQuery.FieldAsXSQLVAR(AIndex));
  if (Result = qfkString) then
  begin
    lValue := FQuery.FieldAsString(AIndex);
    // ToDo: How to detect a logical field in a SQL database
    //       where logicals are represented as VarChar or Char?
    //       In the IBX layer we are currently looking for a value of
    //       'TRUE' or 'FALSE', but this is not reliable as it will not
    //       detect a null. Also, other ways of representing booleans
    //       might be used like 'T', 'F', '0', '1', etc...
    {$IFDEF BOOLEAN_CHAR_1}
      if SameText(lValue, 'T') or
         SameText(lValue, 'F') then
        Result := qfkLogical;
    {$ELSE}
      {$IFDEF BOOLEAN_NUM_1}
      if SameText(lValue, '1') or
         SameText(lValue, '0') then
        Result := qfkLogical;
      {$ELSE}
      if SameText(lValue, 'TRUE') or
         SameText(lValue, 'FALSE') then
        Result := qfkLogical;
      {$ENDIF}
   {$ENDIF}
 end;
end;

function TtiQueryFBL.IBFieldKindToTIFieldKind(AData: TXSQLVar): TtiQueryFieldKind;
begin
  case (AData.sqltype and (not 1)) of
    SQL_TEXT,
    SQL_VARYING:  result := qfkString;
    SQL_LONG,
    SQL_SHORT,
    SQL_INT64,
    SQL_QUAD:     if AData.SqlScale = 0 then
                    result := qfkInteger
                  else
                    result := qfkFloat;
    SQL_DOUBLE,
    SQL_FLOAT,
    SQL_D_FLOAT:  result := qfkFloat;
    SQL_BLOB:     begin
                    case AData.sqlsubtype of
                      isc_blob_untyped: result := qfkBinary;
                      isc_blob_text:    result := qfkLongString;
                    else
                      raise EtiOPFInternalException.Create('Invalid FireBird sqlsubtype');
                    end;
                  end;
    SQL_TIMESTAMP,
    SQL_TYPE_TIME,
    SQL_TYPE_DATE: result := qfkDateTime;
  else
    raise EtiOPFInternalException.Create('Invalid FireBird sqltype');
  end;
end;

function TtiQueryFBL.FieldSize(AIndex: integer): integer;
begin
  if FieldKind(AIndex) in [ qfkInteger, qfkFloat, qfkDateTime,
                            qfkLogical, qfkLongString ] then
    Result := 0
  else
    Result := FQuery.FieldAsXSQLVAR(AIndex).sqllen;
end;

function TtiQueryFBL.GetParamIsNull(const AName: string): Boolean;
begin
//  Assert(False, 'Not implemented');
  Result := False;
end;

procedure TtiQueryFBL.SetParamIsNull(const AName: string; const AValue: Boolean);
begin
  Prepare;
  FQuery.ParamByNameAsNull(AName);
end;

function TtiDatabaseFBL.GetConnected: boolean;
begin
  Result := FDBase.Connected;
end;

procedure TtiDatabaseFBL.SetConnected(AValue: boolean);
var
  lMessage : string;
begin
  try
    if (not AValue) then
    begin
      Log('Disconnecting from %s', [DatabaseName], lsConnectionPool);
      FDBase.Disconnect;
      Exit; //==>
    end;

    { DatabaseName = <host>:<database> }
    if tiNumToken(DataBaseName, ':') = 1 then
    begin
      Log('*** Local connection ***', lsConnectionPool);
      FDBase.Host    := tiToken(DatabaseName, ':', 1);
      FDBase.DBFile  := tiToken(DatabaseName, ':', 1);
      FDBase.Protocol := ptLocal;
    end
    else
    begin
      Log('*** remote connection ***', lsConnectionPool);
      FDBase.Host    := tiToken(DatabaseName, ':', 1);
      { we can't use tiToken(x,y,2) because Windows paths contain a : after the drive letter }
      FDBase.DBFile  := Copy(DatabaseName, Length(FDBase.Host)+2, Length(DatabaseName));
    end;

    FDBase.User      := UserName;
    FDBase.Password  := Password;

    { Assign some well known extra parameters if they exist. }
    if Params.Values['ROLE'] <> '' then
      FDBase.Role := Params.Values['ROLE'];
    if Params.Values['CHARSET'] <> '' then
      FDBase.CharacterSet := Params.Values['CHARSET'];

    FDBase.Connect;
  except
    on e: EFBLError do
    begin
      // Invalid username / password error
      if (EFBLError(E).ISC_ErrorCode = 335544472) then
        raise EtiOPFDBExceptionUserNamePassword.Create(cTIPersistFBL, DatabaseName, UserName, Password)
      else
      begin
        lMessage :=
          'Error attempting to connect to database.'
          + Cr + e.Message + Cr
          + 'Error code: ' + IntToStr(E.ISC_ErrorCode);
        raise EtiOPFDBExceptionUserNamePassword.Create(cTIPersistFBL, DatabaseName, UserName, Password, lMessage)
      end;
    end;
    on E: Exception do
    begin
      raise EtiOPFDBException.Create(cTIPersistFBL, DatabaseName, UserName, Password, E.Message);
    end;
  end;
end;

function TtiQueryFBL.GetFieldIsNull(const AName: string): Boolean;
begin
  Result := FQuery.FieldByNameIsNull(AName);
end;

// See borland communit article:
//   http://community.borland.com/article/0,1410,25259,00.html
// for more system table queries, or search google on 'interbase system tables'
procedure TtiDatabaseFBL.ReadMetaDataTables(AData: TtiDBMetaData);
var
  lQuery: TtiQuery;
  lTable: TtiDBMetaDataTable;
begin
  lQuery := GTIOPFManager.PersistenceLayers.CreateTIQuery(TtiDatabaseClass(ClassType));
  try
    StartTransaction;
    try
      lQuery.AttachDatabase(Self);
      { SQL Views are now also included }
      lQuery.SQLText :=
        'SELECT RDB$RELATION_NAME as Table_Name ' +
        '  FROM RDB$RELATIONS ' +
        'WHERE ((RDB$SYSTEM_FLAG = 0) OR (RDB$SYSTEM_FLAG IS NULL)) ' +
//        '  AND (RDB$VIEW_SOURCE IS NULL) ' +
        'ORDER BY RDB$RELATION_NAME ';
      lQuery.Open;
      while not lQuery.EOF do
      begin
        lTable := TtiDBMetaDataTable.Create;
        lTable.Name := Trim(lQuery.FieldAsString['table_name']);
        lTable.ObjectState := posPK;
        AData.Add(lTable);
        lQuery.Next;
      end;
      lQuery.DetachDatabase;
      AData.ObjectState := posClean;
    finally
      Commit;
    end;
  finally
    lQuery.Free;
  end;
end;

procedure TtiDatabaseFBL.ReadMetaDataFields(AData: TtiDBMetaDataTable);
var
  lTableName : string;
  lQuery: TtiQuery;
  lTable: TtiDBMetaDataTable;
  lField: TtiDBMetaDataField;
  lFieldType : integer;
  lFieldLength : integer;
const
// Interbase field types
//   select * from rdb$types
//   where rdb$field_NAME = 'RDB$FIELD_TYPE'
//   ORDER BY RDB$TYPE

  cIBField_LONG       = 8;
  cIBField_DOUBLE     = 27;
  cIBField_TIMESTAMP  = 35;
  cIBField_DATE       = 12;
  cIBField_TIME       = 13;
  cIBField_VARYING    = 37;
  cIBField_BLOB       = 261;

  cIBField_SHORT      = 7;
  cIBField_QUAD       = 9;
  cIBField_FLOAT      = 10;
  cIBField_TEXT       = 14;
  cIBField_CSTRING    = 40;
  cIBField_BLOB_ID    = 45;
begin
  lTable := (AData as TtiDBMetaDataTable);
  lTableName := UpperCase(lTable.Name);
  lQuery := GTIOPFManager.PersistenceLayers.CreateTIQuery(TtiDatabaseClass(ClassType));
  try
    StartTransaction;
    try
      lQuery.AttachDatabase(Self);
      lQuery.SQLText :=
        '  select ' +
        '    r.rdb$field_name     as field_name ' +
        '    ,rdb$field_type      as field_type ' +
        '    ,rdb$field_sub_type  as field_sub_type ' +
        '    ,rdb$field_length    as field_length ' +
        '  from ' +
        '    rdb$relation_fields r ' +
        '    ,rdb$fields f ' +
        '  where ' +
        '      r.rdb$relation_name = ''' + lTableName + '''' +
        '  and f.rdb$field_name = r.rdb$field_source ';

      lQuery.Open;
      while not lQuery.EOF do
      begin
        lField := TtiDBMetaDataField.Create;
        lField.Name := Trim(lQuery.FieldAsString['field_name']);
        lFieldType := lQuery.FieldAsInteger['field_type'];
        lFieldLength := lQuery.FieldAsInteger['field_length'];

        lField.Width := 0;

        case lFieldType of
          cIBField_SHORT,
          cIBField_LONG      : lField.Kind := qfkInteger;
          cIBField_DOUBLE    : lField.Kind := qfkFloat;
          cIBField_TIMESTAMP,
          cIBField_DATE,
          cIBField_TIME      : lField.Kind := qfkDateTime;
          cIBField_VARYING,
          cIBField_TEXT      : begin
                                  lField.Kind := qfkString;
                                  lField.Width := lFieldLength;
                                end;
          cIBField_BLOB      : begin
                                  Assert(not lQuery.FieldIsNull['field_sub_type'], 'field_sub_type is null');
                                  if lQuery.FieldAsInteger['field_sub_type'] = 1 then
                                    lField.Kind := qfkLongString
                                  else
                                    raise EtiOPFInternalException.Create('Invalid field_sub_type <' + IntToStr(lQuery.FieldAsInteger['field_sub_type']) + '>');
                                end;
        else
          raise EtiOPFInternalException.Create('Invalid Interbase FieldType <' + IntToStr(lFieldType) + '>');
        end;
        lField.ObjectState := posClean;
        lTable.Add(lField);
        lQuery.Next;
      end;
    finally
      Commit;
    end;
    lQuery.DetachDatabase;
    lTable.ObjectState := posClean;
  finally
    lQuery.Free;
  end;
end;

function TtiDatabaseFBL.FieldMetaDataToSQLCreate(const AFieldMetaData: TtiDBMetaDataField): string;
var
  lFieldName : string;
begin
  lFieldName := AFieldMetaData.Name;
  case AFieldMetaData.Kind of
    qfkString:  Result := 'VarChar(' + IntToStr(AFieldMetaData.Width) + ')';
    qfkInteger: Result := 'Integer';
    qfkFloat:   Result := 'DOUBLE PRECISION';  // or Decimal(10,5)
    qfkDateTime:
        // Take into account dialect
        if IBDatabase.SQLDialect <> 1 then
          Result := 'TIMESTAMP'
        else
          Result := 'Date';
    {$IFDEF BOOLEAN_CHAR_1}
    qfkLogical: Result    := 'Char(1) default ''F'' check(' +
        lFieldName + ' in (''T'', ''F''))';
    {$ELSE}
      {$IFDEF BOOLEAN_NUM_1}
    qfkLogical: Result    := 'SmallInt default 0 check(' +
        lFieldName + ' in (1, 0)) ';
      {$ELSE}
    qfkLogical: Result    := 'VarChar(5) default ''FALSE'' check(' +
        lFieldName + ' in (''TRUE'', ''FALSE'')) ';
      {$ENDIF}
    {$ENDIF}
    qfkBinary:     Result := 'Blob sub_type 0';
    qfkLongString: Result := 'Blob sub_type 1';
    else
      raise EtiOPFInternalException.Create('Invalid FieldKind');
  end;
end;

class procedure TtiDatabaseFBL.CreateDatabase(const ADatabaseName, AUserName, APassword: string; const AParams: string);
var
  lDatabase: TtiDatabaseFBL;
begin
  lDatabase := TtiDatabaseFBL.Create;
  try
    lDatabase.FDBase.DBFile      := ADatabaseName;
    lDatabase.FDBase.User        := AUserName;
    lDatabase.FDBase.Password    := APassword;
    lDatabase.FDBase.CreateDatabase(ADatabaseName, AUserName, APassword);
  finally
    lDatabase.Free;
  end;
end;

class procedure TtiDatabaseFBL.DropDatabase(const ADatabaseName, AUserName,
  APassword: string; const AParams: string);
begin
  Assert(False, 'DropDatabase not implemented in ' + ClassName);
end;

// Test if an Interbase server is available. Will not test for the existance of a GDB
// file, just if the server is up. Will also return the server version.
// Problem is, that this routine takes an IP address and an interbase connection
// string comprises an IPAddress:PathName. So this will have to be parsed into
// its two parts. Some valid IB connection strings that would have to be paresd are:

//  C:\Data\MyData.gdb
//  \Data\MyData.gdb
//  MyData.gdb
//  ..\Data\MyData.gdb
//  Server:C:\Data\MyData.gdb
//  123.456.789:C:\Data\MyData.gdb
//  LocalHost:C:\Data\MyData.gdb
//  Rules: If there is only one ':', then assume it's a file name only.
//  If there are two ':', then assume a machine name.
{
function TtiDatabaseFBL.TestServer(const pServerIPAddress : string; var pServerVersion : string): boolean;
var
  lIBSP: TIBServerProperties;
begin
  lIBSP:= TIBServerProperties.Create(nil);
  try
    lIBSP.LoginPrompt := false;
    lIBSP.Params.Clear;
    lIBSP.Params.Append('user_name=' + uUser);
    lIBSP.Params.Append('password=' + uPwd);
    lIBSP.ServerName  := pServerIPAddress;
    if SameText(lIBSP.ServerName, 'LocalHost') then
      lIBSP.Protocol := Local
    else
      lIBSP.Protocol := TCP;
    lIBSP.Options := [Version];
    try
      try
        lIBSP.Active := True;
        lIBSP.FetchVersionInfo;
        pServerVersion := lIBSP.VersionInfo.ServerVersion;
        result := true;
        lIBSP.Active := False;
      except
        on e: Exception do
          result := false;
        end;
    finally
      lIBSP.Active := False;
    end;
  finally
    lIBSP.Free;
  end;
end;
}

class function TtiDatabaseFBL.DatabaseExists(const ADatabaseName, AUserName, APassword: string; const AParams: string): boolean;
var
  lDatabase: TtiDatabaseFBL;
begin
  lDatabase := TtiDatabaseFBL.Create;
  try
    try
      lDatabase.Connect(ADatabaseName, AUserName, APassword, '');
      Result := True;
    except
      on E: Exception do
        Result := False;
    end;
    lDatabase.Connected := False;
  finally
    lDatabase.Free;
  end;
end;

function TtiQueryFBL.HasNativeLogicalType: boolean;
begin
  Result := False;
end;

function TtiDatabaseFBL.Test: boolean;
begin
  Result := False;
  Assert(False, 'Under construction');
end;


function TtiDatabaseFBL.TIQueryClass: TtiQueryClass;
begin
  result:= TtiQueryFBL;
end;

{ TtiPersistenceLayerFBL }

procedure TtiPersistenceLayerFBL.AssignPersistenceLayerDefaults(
  const APersistenceLayerDefaults: TtiPersistenceLayerDefaults);
begin
  Assert(APersistenceLayerDefaults.TestValid, CTIErrorInvalidObject);
  APersistenceLayerDefaults.PersistenceLayerName:= CTIPersistFBL ;
  APersistenceLayerDefaults.DatabaseName:= CDefaultDatabaseDirectory + CDefaultDatabaseName + '.fdb';
  APersistenceLayerDefaults.IsDatabaseNameFilePath:= True;
  APersistenceLayerDefaults.Username:= 'SYSDBA';
  APersistenceLayerDefaults.Password:= 'masterkey';
  APersistenceLayerDefaults.CanDropDatabase:= False;
  APersistenceLayerDefaults.CanCreateDatabase:= False;
  APersistenceLayerDefaults.CanSupportMultiUser:= False;
  APersistenceLayerDefaults.CanSupportSQL:= True;
end;

function TtiPersistenceLayerFBL.GetDatabaseClass: TtiDatabaseClass;
begin
  result:= TtiDatabaseFBL;
end;

function TtiPersistenceLayerFBL.GetPersistenceLayerName: string;
begin
  result:= cTIPersistFBL;
end;

function TtiPersistenceLayerFBL.GetQueryClass: TtiQueryClass;
begin
  result:= TtiQueryFBL;
end;

initialization
  GTIOPFManager.PersistenceLayers.__RegisterPersistenceLayer(
    TtiPersistenceLayerFBL);

finalization
  if not tiOPFManager.ShuttingDown then
    GTIOPFManager.PersistenceLayers.__UnRegisterPersistenceLayer(cTIPersistFBL);

end.
