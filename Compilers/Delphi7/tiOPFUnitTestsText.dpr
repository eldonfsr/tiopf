program tiOPFUnitTestsText;
{$APPTYPE CONSOLE}
uses
  FastMM4,
  SysUtils,
  TestFrameWork,
  TextTestRunner,
  tiOPFTestManager,
  tiTextTestRunner in '..\..\UnitTests\Common\tiTextTestRunner.pas',
  tiTestDependencies in '..\..\UnitTests\Common\tiTestDependencies.pas';

var
  LExitBehavior : TRunnerExitBehavior;

begin

  // To run with rxbPause, use -p switch
  // To run with rxbHaltOnFailures, use -h switch
  // No switch runs as rxbContinue
  if FindCmdLineSwitch('p', ['-', '/'], true) then
    LExitBehavior := rxbPause
  else if FindCmdLineSwitch('h', ['-', '/'], true) then
    LExitBehavior := rxbHaltOnFailures
  else
    LExitBehavior := rxbContinue;

  if not FindCmdLineSwitch(cCommandLineParamsNoTests, ['-', '/'], true) then
  begin
    GTIOPFTestManager.Read;
    GTIOPFTestManager.DeleteDatabaseFiles;
    tiRemoveXMLLightIfNotRegistered;
    tiTestDependencies.tiRegisterTests;
    tiTextTestRunner.RunRegisteredTests(LExitBehavior);
  end else
    WriteEmptyLogs(LExitBehavior);

end.

