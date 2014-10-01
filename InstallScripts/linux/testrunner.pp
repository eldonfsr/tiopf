{
  My custom text test runner application. This one actually works even if I
  have the DB persistance layers enabled.

  Author: Graeme Geldenhuys (2007-06-20)
}
program testrunner;

{$mode objfpc}
{$h+}

uses
  cthreads,
  custapp, Classes, SysUtils, fpcunit, testutils, testregistry
  ,tiTestDependencies, xmlwrite, xmltestreport;


const
  ShortOpts = 'alhp';
  Longopts: Array[1..6] of String = (
    'all','list','format:','suite:','help', 'progress');
  Version = 'Version 0.3';


type
  TProgressWriter= class(TNoRefCountObject, ITestListener)
  private
    FSuccess: boolean;
  public
    destructor Destroy; override;
    { ITestListener interface requirements }
    procedure AddFailure(ATest: TTest; AFailure: TTestFailure);
    procedure AddError(ATest: TTest; AError: TTestFailure);
    procedure StartTest(ATest: TTest);
    procedure EndTest(ATest: TTest);
    procedure StartTestSuite(ATestSuite: TTestSuite);
    procedure EndTestSuite(ATestSuite: TTestSuite);
  end;



  TTestRunner = Class(TCustomApplication)
  private
    FXMLResultsWriter: TXMLResultsWriter;
    progressWriter: TProgressWriter;
    FShowProgress: Boolean;
  protected
    procedure   DoRun ; Override;
    procedure   doTestRun(aTest: TTest); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
  end;


destructor TProgressWriter.Destroy;
begin
  // on descruction, just write the missing line ending
  writeln;
  inherited Destroy;
end;

procedure TProgressWriter.AddFailure(ATest: TTest; AFailure: TTestFailure);
begin
  FSuccess := false;
  write('F');
end;

procedure TProgressWriter.AddError(ATest: TTest; AError: TTestFailure);
begin
  FSuccess := false;
  write('E');
end;

procedure TProgressWriter.StartTest(ATest: TTest);
begin
  FSuccess := true; // assume success, until proven otherwise
end;

procedure TProgressWriter.EndTest(ATest: TTest);
begin
  if FSuccess then
    write('.');
end;

procedure TProgressWriter.StartTestSuite(ATestSuite: TTestSuite);
begin
  writeln('');
  writeln(ATestSuite.TestName + ':');
  // do nothing
end;

procedure TProgressWriter.EndTestSuite(ATestSuite: TTestSuite);
begin
  // do nothing
end;


constructor TTestRunner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FXMLResultsWriter := TXMLResultsWriter.Create(nil);
  FShowProgress := False;
end;


destructor TTestRunner.Destroy;
begin
  FXMLResultsWriter.Free;
end;


procedure TTestRunner.doTestRun(aTest: TTest);
var
  testResult: TTestResult;
begin
  testResult := TTestResult.Create;
  try
    if FShowProgress then
    begin
      progressWriter := TProgressWriter.Create;
      testResult.AddListener(progressWriter);
    end;

    testResult.AddListener(FXMLResultsWriter);
    aTest.Run(testResult);
    FXMLResultsWriter.WriteResult(testResult);
    WriteXMLFile(FXMLResultsWriter.Document, 'results.xml');
  finally
    if FShowProgress then
      progressWriter.Free;
    testResult.Free;
  end;
end;


procedure TTestRunner.DoRun;
var
  I : Integer;
  S : String;
begin
  S:=CheckOptions(ShortOpts,LongOpts);
  If (S<>'') then
    Writeln(S);
  if HasOption('h', 'help') or (ParamCount = 0) then
  begin
    writeln(Title);
    writeln(Version);
    writeln('Usage: ');
    writeln('-l or --list to show a list of registered tests');
    writeln('default format is xml, add --format=latex to output the list as latex source');
    writeln('-a or --all to run all the tests and show the results in xml format');
    writeln('The results can be redirected to an xml file,');
    writeln('for example: ./testrunner --all > results.xml');
    writeln('use --suite=MyTestSuiteName to run only the tests in a single test suite class');
    writeln('-p or --progress   Shows progress as tests are run.');
  end
  else;
    if HasOption('l', 'list') then
    begin
(*      if HasOption('format') then
      begin
        if GetOptionValue('format') = 'latex' then
          writeln(GetSuiteAsLatex(GetTestRegistry))
        else
          writeln(GetSuiteAsXML(GetTestRegistry));
      end
      else
        writeln(GetSuiteAsXML(GetTestRegistry));
*)         	
    end;

  if HasOption('p', 'progress') then
  begin
    FShowProgress := True;
  end;

  if HasOption('a', 'all') then
  begin
    doTestRun(GetTestRegistry)
  end
  else
    if HasOption('suite') then
    begin
      S := '';
      S:=GetOptionValue('suite');
      if S = '' then
        for I := 0 to GetTestRegistry.Tests.count - 1 do
          writeln(GetTestRegistry[i].TestName)
      else
      for I := 0 to GetTestRegistry.Tests.count - 1 do
        if GetTestRegistry[i].TestName = S then
        begin
          doTestRun(GetTestRegistry[i]);
        end;
    end;
  Terminate;
end;


var
  App: TTestRunner;


begin
  App := TTestRunner.Create(nil);
  App.Initialize;
  App.Title := 'FPCUnit Console Test Case runner.';
  
  GTIOPFTestManager.Read;
  tiTestDependencies.RegisterTests;
//  tiTestDependencies.RemoveUnSelectedPersistenceLayerSetups;

  App.Run;
  App.Free;
end.

