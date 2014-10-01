unit tiConstants;

{$I tiDefines.inc}

interface

const
  // XML version number
  cTIOPFVersion          = '2.000';

  // There are quite a few of these now, so keep them sorted in alapha order
  cTIPersistADOAccess     = 'ADOAccess';
  cTIPersistADOSQLServer  = 'ADOSQLServer';
  cTIPersistBDEParadox    = 'BDEParadox';
  cTIPersistCrSdac        = 'CrSdac';
  cTIPersistCSV           = 'CSV';
  cTIPersistDOA           = 'DOA';
  cTIPersistFBL           = 'FBL';          // Free Pascal only
  cTIPersistFIBP          = 'FIBP';         // FIBPlus
  cTIPersistIBO           = 'IBO';
  cTIPersistIBX           = 'IBX';
  cTIPersistRemote        = 'Remote';
  cTIPersistSqldbIB       = 'Sqldb_IB';     // Free Pascal equivalent to Delphi dbExpress
  cTIPersistSqldbPQ       = 'Sqldb_PQ';
  cTIPersistSqldbOracle   = 'Sqldb_Oracle';
  cTIPersistSqldbSQLite3  = 'Sqldb_SQLite3';
  cTIPersistSqldbODBC     = 'Sqldb_ODBC';
  cTIPersistSqldbMySQL40  = 'Sqldb_MySQL40';
  cTIPersistSqldbMySQL41  = 'Sqldb_MySQL41';
  cTIPersistSqldbMySQL50  = 'Sqldb_MySQL50';
//  cTIPersistSqldbMySQL51  = 'Sqldb_MySQL51';
  cTIPersistSqldbMySQL55  = 'Sqldb_MySQL55';
  cTIPersistTAB           = 'TAB';
  cTIPersistXML           = 'XML';          // ToDo: Rename this MSXML
  cTIPersistXMLLight      = 'XMLLight';
  cTIPersistZeosFB        = 'Zeos_FB';
  cTIPersistZeosMySQL41   = 'Zeos_MySQL41';
  cTIPersistZeosMySQL50   = 'Zeos_MySQL50';
  cTIPersistDBISAM4       = 'DBISAM4';
  cTIPersistAsqlite3      = 'Asqlite3';
  cTIPersistUIB_EB        = 'UIB_EB';  // Embedded server
  cTIPersistUIB_FB        = 'UIB_FB';  // Firebird server
  cTIPersistUIB_IB        = 'UIB_IB';  // Interbase server
  cTIPersistNexusDB       = 'NexusDB';

  cDBProxyServerTimeOut   = 1; // Minute

  cTIPersistPackageRootName = 'tiPersist';
  // When multiple database names are provided to GTIOPFManager.DetectAndConnect()
  // they will be separated by this character.
  cDatabaseNameDelim        = ';';
  CPasswordMasked = 'Password masked from view';

  CTIErrorInternal = 'tiOPF Internal Error: ';
  CTIErrorInvalidObject = CTIErrorInternal + ' TtiBaseObject.TestValid failed';
  // Don't use these ones, they are to allow old code to compile
  //CTIErrorInvalidObject = CTIErrorInvalidObject;
  //CTIErrorInvalidObject = CTIErrorInvalidObject;

  // Constants for the remote persistence layer
  cLocalHost = 'http://localhost:80';
  cRemoteServerMainFormCaption = 'TechInsite DB Proxy Server';
  cTIDBProxyServiceName = 'tiDBProxyServer';
  cSecToTimeOutLocked = 999999;

  CTIProtocolFile = 'file';
  CTIProtocolSelf = 'self';

{$IFDEF DELPHI5}
  cPackageSuffix = '';
  cCompilerName = 'Delphi 5';
{$ENDIF}

{$IFDEF DELPHI6}
  cPackageSuffix = '60';
  cCompilerName = 'Delphi 6';
{$ENDIF}

{$IFDEF DELPHI7}
  cPackageSuffix = '70';
  cCompilerName = 'Delphi 7';
{$ENDIF}

{$IFDEF DELPHI9}
  cPackageSuffix = '90';
  cCompilerName = 'Delphi 2005';
{$ENDIF}

{$IFDEF DELPHI10}
  cPackageSuffix = '100';
  cCompilerName = 'Delphi 2006';
{$ENDIF}

{$IFDEF DELPHI11}
  cPackageSuffix = '110';
  cCompilerName = 'Delphi 2007';
{$ENDIF}

{$IFDEF DELPHI12}
  cPackageSuffix = '120';
  cCompilerName = 'Delphi 2009';
{$ENDIF}

{$IFDEF DELPHI14}
  cPackageSuffix = '140';
  cCompilerName = 'Delphi 2010';
{$ENDIF}

{$IFDEF FPC}
  cPackageSuffix = {$I %fpcversion%};
  cCompilerName = 'Free Pascal';
{$ENDIF}

  // Compression constants
  cgsCompressNone = 'No compression';
  cgsCompressZLib = 'ZLib compression';

{$IFDEF MSWINDOWS}
  { example filename:  tiPersistCore60.bpl }
  cPackagePrefix       = '';
  cPackageExtension    = '.bpl';
{$ENDIF MSWINDOWS}

{$IFDEF UNIX}
  { example filename:  bpltiPersistCore.so }
  cPackagePrefix       = 'bpl';
  cPackageExtension    = '.so';
{$ENDIF}

  // Some parameter keys and values that may be used by TtiQueryRemote
  cINISystem              = 'System';
  cINIAppServer           = 'System'; // This can't be changed without changing the application launcher too
  cHTTPIndy               = 'HTTPIndy';
  cHTTPMSXML              = 'HTTPMSXML';
  cHTTPURL                = 'url';
  cHTTPConnectWith        = 'connectwith';
  cHTTPProxyServer        = 'proxyserver';
  cHTTPProxyServeractive  = 'proxyserveractive';
  cHTTPProxyServerName    = 'proxyservername';
  cHTTPProxyPort          = 'proxyport';
  CHTTPBlockSize          = 'blocksize';
  CHTTPRetryLimit         = 'retrylimit';

  CPathToCachedDataRoot       = 'CachedData';

  cTIOPFExcMsgConnectionConfirmationFormatWrong = 'Server did not return correctly formatted connection confirmation Expected <%s> Found <%s>';
  cTIOPFExcMsgWrongServerVersion = 'The client and server are incompatable versions.'#13#13 +
                                   'Please upgrade your software by following the'#13 +
                                   'instructions at %s'#13#13+
                                   '(When you click <OK>, your web browser will be launched pointing to the application''s web site.)';
  cTIOPFExcMsgErrorOnServer = 'There was an unknown error on the application server. Please try again later.';
  cNullOIDInteger = 0;

  cNextOIDReadHigh = 'NextOIDReadHigh'; // Visitor constant

  {$IFDEF BOOLEAN_CHAR_1}
  cTrueDB  = 'T';
  cFalseDB = 'F';
  {$ELSE}
  cTrueDB  = 'TRUE';
  cFalseDB = 'FALSE';
  {$ENDIF}

  cTrueGUI = 'True';
  cFalseGUI = 'False';

  ciOK                = 0;
  ciRetry             = 1;
  ciAbort             = 2;

  cdtOneDay        = 1;
  cdtOneHour       = 1/24;
  cdtOneMinute     = 1/24/60;
  cdtOneSecond     = 1/24/60/60;
  cdtOneMiliSecond = 1/24/60/60/1000;

  cComma          = ',';
  cBackSpace      = #8;

  crMaxReal       = 9999999999;

  CNullDate       = 0.0;
  CNullDateTime   = 0.0;
  CMaxDateTime    = 2958465.99998843;  // 31/12/9999 23:59:59
  CMaxDate        = 2958465;
  CNullSQLDate    = 0;                 // 12/30/1899

  cgNullDate      = CNullDateTime;
  cgNullDateTime  = CNullDateTime;
  cgMinDateTime   = CNullDateTime;
  cgdtMaxDateTime = CMaxDateTime;  // 31/12/9999 23:59:59
  cgMaxDateTime   = cgdtMaxDateTime;
  cgdtMaxDate     = CMaxDate;
  crMaxDate       = CMaxDate;
  cgMinDate       = 0.0;
  cgMaxDate       = CMaxDate;

  { Summary of ISO 8601  http://www.cl.cam.ac.uk/~mgk25/iso-time.html }
  cIntlDateTimeStor = 'yyyymmdd"T"hhnnss';    // for storage
  cIntlDateTimeDisp = 'yyyy-mm-dd hh:nn:ss';  // for display
  CIntlDateDisp     = 'yyyy-mm-dd';  // for display

  cgsComma        = ',';
  {$IFDEF DELPHI5} // These are defined from Delphi 5
  MinDateTime: TDateTime = -657434.0;      { 01/01/0100 12:00:00.000 AM }
  MaxDateTime: TDateTime =  2958465.99999; { 12/31/9999 11:59:59.999 PM }
  {$ENDIF}
  crZeroLimit      = 0.005;
  cCurrencyFormat0 = '$ #,##0';
  cCurrencyFormat2 = '$ #,##0.00';
  cgsNA            = 'N/A';

  cPI              = 3.14159265358979;
  cGoldenRatio     = 1618; // Forms should be sized in the ratio 1618 x 1000
  cCommandLineParamPause = 'pause'; // Handy in Console apps

  // Some INI file constants
  cINISectionSystem     = 'System';
  cINIIdentDatabaseName = 'DatabaseName';
  cINIIdentUserName     = 'UserName';
  cINIIdentPassword     = 'Password';
  cINIIdentPort         = 'Port';

  { Moved from tiUtils }
  csWinDateFormat     = 'dd/MM/yyyy';
  csWinTimeFormat     = 'hh:mm:ss';
  csWinDateTimeFormat = 'dd/MM/YYYY hh:mm:ss';
  {$IFDEF UNIX}
  AllFilesWildCard    = '*';
  {$ELSE}
  AllFilesWildCard    = '*.*';
  {$ENDIF}
  {$IFDEF UNIX}{$IFNDEF DARWIN}
  cLineEnding         = #10;    // Unix type OSes (Linux, *BSD, ...)
  CMinFileDate        = 29221; {$MESSAGE 'ToDo: Supply correct value for min file date on Unix'}
  {$ENDIF}{$ENDIF}
  {$IFDEF DARWIN}
  cLineEnding         = #13;    // Mac OS
  CMinFileDate        = 29221;  {$MESSAGE 'ToDo: Supply correct value for min file date on Mac OS'}
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  cLineEnding         = #13#10; // Windows
  CMinFileDate        = 29221;
  {$ENDIF}


  // Error messages
  CErrorDecodeNumError          = 'tiDecodeNum: <%s> does not represent a number in base %d.';
  CErrorUnableToCreateDirectory = 'Unable to create directory <%s>';
  CErrorRemoveDirectory         = 'Error removing <%s> from <%s>';
  CErrorInvalidVariantType      = 'Invalid variant type';
  CErrorXMLStringToDate         = 'Error converting string to date. String <%s> Error: %s';
  CErrorCanNotDeleteFile        = 'Can not delete file <%s>. It may be locked by another application.';
  CErrorCanNotCopyFile          = 'Unable to copy "%s" to "%s". System error code: "%d". System error message: "%s"';
  CErrorSettingFileDate         = 'Unable to set file date on: "%s" to "%s" System error code: "%d". System error message: "%s"';

  CUnknownGUI = 'Unknown' ;
  CUnknownDB = 'UNKNOWN';

  cBase           = 26;
  cZeroChar       = 'A';

  cuiBorder       = 16;
  cuiBtnBorder    =  8;
  cuiBtnHeight    = 25;
  cuiBtnWidth     = 75;
  cuiImageWidth   = 32;

{$ifndef Delphi6OrAbove}
const
  {$ifdef MSWINDOWS}PathDelim = '\';{$endif}
  {$ifdef UNIX}PathDelim = '/';{$endif}
{$endif}

  {: The maximum length a command passed to an console EXE can be. This length
     includes the exe path & name, and any parameters.}
  CMaximumCommandLineLength = 32768 - 5;
  {The 5 is a magic value to allow for pace between exe name and params,
   a null terminator and something else I don't quite understand.}
  {: When the command line parameter to be passed to a CGI extension excedes
     CMaximumCommandLineLength, then it's passed via a file. This flag is
     used to indicate a file name has been passed.}
  CCGIExtensionLargeParamFlag = 'CGIExtParamViaFile';

  // Structured CSV line prefixes
  CStructCSVPrefixI = 'I';
  CStructCSVPrefixD = 'D';

  CNoPathEntered = 'Please enter a path to save to.';
  CDirsEndingInSpace = 'Folder names cannot end in a space';
  CInvalidDrive = '%s is not a valid drive.';
  CInvalidDirName = '%s is not a valid directory name or you do not have write permission.';
  CInvalidFileName = '%s is not a valid file name.';
  CFileAccessDenied = '%s is locked by another application or you do not have permission to create it.';

implementation

end.
