{
  This persistence layer uses standard Free Pascal SQLDB (SQLite3) components.

  The connection string format is the same as the standard SQLite3 persistence layers.

  eg:
    GTIOPFManager.ConnectDatabase('Test.db','','', '');

  Initial Author:  Michael Van Canneyt (michael@freepascal.org) - Aug 2008
}

unit tiQuerySqldbSQLite3;

{$I tiDefines.inc}

interface

uses
  tiQuery
  ,Classes
  ,db
  ,sqldb
  ,sqlite3conn
  ,tiPersistenceLayers
  ,tiQuerySqldb;

type

  { TtiPersistenceLayerSqldSQLite3 }

  TtiPersistenceLayerSqldSQLite3 = class(TtiPersistenceLayerSqldDB)
  protected
    function GetPersistenceLayerName: string; override;
    function GetDatabaseClass: TtiDatabaseClass; override;
  public
    procedure AssignPersistenceLayerDefaults(const APersistenceLayerDefaults: TtiPersistenceLayerDefaults); override;
  end;
  { TtiDatabaseSQLDBSQLite3 }

  TtiDatabaseSQLDBSQLite3 = Class(TtiDatabaseSQLDB)
  protected
    Class Function CreateSQLConnection : TSQLConnection; override;
    function    HasNativeLogicalType: boolean; override;
  end;



implementation

{ $define LOGSQLDB}
uses
{$ifdef LOGSQLDB}
  tiLog,
{$endif}
  tiOPFManager,
  tiConstants;


{ TtiPersistenceLayerSqldSQLite3 }

procedure TtiPersistenceLayerSqldSQLite3.AssignPersistenceLayerDefaults(
  const APersistenceLayerDefaults: TtiPersistenceLayerDefaults);
begin
  Assert(APersistenceLayerDefaults.TestValid, CTIErrorInvalidObject);
  APersistenceLayerDefaults.PersistenceLayerName:= cTIPersistSqldbSQLLite3;
  APersistenceLayerDefaults.DatabaseName:= CDefaultDatabaseName + '.db';
  APersistenceLayerDefaults.IsDatabaseNameFilePath:= True;
  APersistenceLayerDefaults.CanCreateDatabase:= True;
  APersistenceLayerDefaults.CanSupportMultiUser:= False;
  APersistenceLayerDefaults.CanSupportSQL:= True;
end;

function TtiPersistenceLayerSqldSQLite3.GetDatabaseClass: TtiDatabaseClass;
begin
  result:= TtiDatabaseSQLDBSQLite3;
end;

function TtiPersistenceLayerSqldSQLite3.GetPersistenceLayerName: string;
begin
  result:= cTIPersistSqldbSQLLite3;
end;


{ TtiDatabaseSQLDBSQLite3 }

Class function TtiDatabaseSQLDBSQLite3.CreateSQLConnection: TSQLConnection;
begin
  Result:=TSQLite3Connection.Create(Nil);
end;


function TtiDatabaseSQLDBSQLite3.HasNativeLogicalType: boolean;
begin
  Result:=True;
end;

initialization

  GTIOPFManager.PersistenceLayers.__RegisterPersistenceLayer(
    TtiPersistenceLayerSqldSQLite3);

finalization
  if not tiOPFManager.ShuttingDown then
    GTIOPFManager.PersistenceLayers.__UnRegisterPersistenceLayer(cTIPersistSqldbSQLLite3);

end.
