unit tiThread;

{$I tiDefines.inc}

interface
uses
  Classes
  ,tiBaseObject
  ,Contnrs
  {$IFDEF MSWINDOWS}
  ,Windows
  {$ENDIF}
  ,SyncObjs   // This unit must always appear after the Windows unit!
 ;

const
  cDefaultSleepResponse = 100; // Will check Terminated while sleeping every 100ms

type

  TtiThread = class;

  // ToDo: TtiThread should be renamed to TtiRegisteredThread and descend
  //       from TtiSleepThread
  TtiSleepThread = class(TThread)
  private
    FSleepResponse: Cardinal;
    FName: string;
    FUpdateEvent: TEvent;
    FThreadInstanceID: Integer;
  protected
    FFinished: boolean;
    procedure WakeUpAndTerminate;
    function SleepAndCheckTerminated(ASleepFor: Cardinal): boolean;
    property UpdateEvent: TEvent read FUpdateEvent;
  public
    constructor Create(ASuspended: boolean); virtual;
    destructor  Destroy; override;
    procedure   SetThreadName(const AName: string);
    procedure   WakeUp;
    procedure   Execute; override;
    {$IFDEF FPC}
    procedure   WaitFor; reintroduce;
    {$ENDIF}
    property    ThreadInstanceID: Integer read FThreadInstanceID;
    property    SleepResponse: Cardinal read FSleepResponse write FSleepResponse;
  end;

  TtiThread = class(TtiSleepThread)
  private
    FText: string;
    FDescription: string;
    FInActiveThreadList: boolean;
    FOnTerminate: TNotifyEvent;
  protected
    procedure   DoOnTerminate(Sender: TObject); virtual;
    procedure   SetText(const AValue: string); virtual;
  public
    constructor Create(ACreateSuspended: Boolean); overload; override;
    constructor Create(const ACreateSuspended: boolean; const AAddToActiveThreadList: boolean); reintroduce; overload;
    constructor CreateAndResume; virtual; // See note in body of method
    destructor  Destroy; override;
    property    Text: string read FText write SetText;
    property    Description: string read FDescription write FDescription;
    property    OnTerminate: TNotifyEvent read FOnTerminate write FOnTerminate;
  end;

  TtiThreadEvent = procedure(const AThread: TtiThread) of object;
  TtiThreadEventRegular = procedure(const AThread: TtiThread);

  TtiThreadList = class(TObjectList)
  private
    FCritSect : TCriticalSection;
  protected
    function    GetItem(Index: integer): TtiThread; reintroduce;
    procedure   SetItem(Index: integer; const Value: TtiThread); reintroduce;
  public
    constructor Create;
    destructor  Destroy; override;
    {: Performs the class method AMethod on every thread in the list.}
    procedure   ForEach(AMethod: TtiThreadEvent); overload;
    {: Performs the method AMethod on every thread in the list.}
    procedure   ForEach(AMethod: TtiThreadEventRegular); overload;
    procedure   Lock;
    procedure   Unlock;
    procedure   Terminate;
    property    Items[Index:integer]: TtiThread read GetItem write SetItem;
    // ToDo: Should override Add() and check that the thread's FreeOnTerminate
    //       = False (WaitForAll will fail if FreeOnTerminate = True)
    procedure   WaitForAll;
    procedure   ResumeAll;
  end;

  TtiThreadClass = class of TtiThread;

  TtiThreadCountChangeEvent = procedure(const AThreadCount: integer) of object;

  TtiActiveThreadList = class(TtiBaseObject)
  private
    FList: TtiThreadList;
    FCritSect : TCriticalSection;
    FOnThreadCountChange: TtiThreadCountChangeEvent;
    FThreadCount: integer;

    FNewThreadInstanceID: Integer;

    procedure DoThreadCountChange(AThreadCount: Integer; const AThread: TThread);
    procedure DoThreadCountChangeSynchronized;
    procedure SetOnThreadCountChange(const AValue: TtiThreadCountChangeEvent);
    function GetThreadCount: integer;
    function GetActiveThreadNames: string;
    function GetActiveThreadTextDescriptions: string;
    function FindThreadByInstanceID(const AThreadInstanceID: Integer): TtiThread;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   Add(const AThread : TtiThread);
    procedure   Remove(const AThread : TtiThread);
    procedure   Terminate;

    function  GetNewThreadInstanceID: Integer;
    procedure TerminateThreadByInstanceID(const AThreadInstanceID: Integer);
    {: Performs the class method AMethod on every thread in the list.}
    procedure   ForEach(AMethod: TtiThreadEvent); overload;
    {: Performs the method AMethod on every thread in the list.}
    procedure   ForEach(AMethod: TtiThreadEventRegular); overload;
    property    OnThreadCountChange: TtiThreadCountChangeEvent read FOnThreadCountChange write SetOnThreadCountChange;
    property    Count: integer read GetThreadCount;
    property    ActiveThreadNames: string read GetActiveThreadNames;
    // ToDo: WaitForAll is buggy. It depends on TtiThread's Destroy method
    //       executing when the thread terminates (Destroy is where each
    //       thread removes it self from the list.) Destroy will only be called
    //       after Application.ProcessMessages when there is a GUI, and never
    //       for console apps. This needs investigation. So, for the meantime,
    //       don't use WaitForAll.
    procedure   WaitForAll;
    property    ActiveThreadTextDescriptions: string read GetActiveThreadTextDescriptions;
    function    InstanceOfThreadClassIsActive(const AThreadClass: TtiThreadClass): boolean;
  end;


{$IFDEF MSWINDOWS}
procedure SetIdeDebuggerThreadName(AThreadID: DWORD; AThreadName: PChar);
{$ELSE}
procedure SetIdeDebuggerThreadName(AThreadID: TThreadID; AThreadName: PChar);
{$ENDIF}



implementation
uses
  tiOPFManager
  {$IFDEF MSWINDOWS}
  ,tiWin32
  {$IFNDEF FPC}
  ,Forms // Hack to work around problem in TtiActiveThreadList.WaitForAll
  {$ENDIF}
  {$ENDIF MSWINDOWS}
  ,tiUtils
  ,SysUtils    // Used by FPC for the Sleep method.
 ;


{ This could be used for Delphi too, but it's not really needed (while Delphi
  only supports Windows) }
type
  TAutoFinishedState = class(TInterfacedObject)
  private
    FFinished: Boolean;
  public
    constructor Create(var Finished: Boolean);
    destructor Destroy; override;
  end;

{ TAutoFinishedState }

constructor TAutoFinishedState.Create(var Finished: Boolean);
begin
  FFinished := Finished;
  FFinished := False;
end;

destructor TAutoFinishedState.Destroy;
begin
  FFinished := True;
  inherited Destroy;
end;



{$IFDEF MSWINDOWS}
procedure SetIdeDebuggerThreadName(AThreadID: DWORD; AThreadName: PChar);
type
  TThreadNameInfo = record
    FType: LongWord;     // must be 0x1000
    FName: PChar;        // pointer to name (in user address space)
    FThreadID: LongWord; // thread ID (-1 indicates caller thread)
    FFlags: LongWord;    // reserved for future use, must be zero
  end;
var
  ThreadNameInfo: TThreadNameInfo;
begin
  ThreadNameInfo.FType := $1000;
  ThreadNameInfo.FName := AThreadName;
  ThreadNameInfo.FThreadID := $FFFFFFFF; //ThreadID;
  ThreadNameInfo.FFlags := 0;
  try
    RaiseException($406D1388, 0, SizeOf(ThreadNameInfo) div SizeOf(LongWord), @ThreadNameInfo);
  except
  end;
end;
{$ELSE}
procedure SetIdeDebuggerThreadName(AThreadID: TThreadID; AThreadName: PChar);
begin
  // In .NET there is a method... thread.setname or something
  // In Linux - who knows
end;
{$ENDIF}


{ TtiThread }

constructor TtiThread.CreateAndResume;
begin
  Create(false);
end;


constructor TtiThread.Create(ACreateSuspended: Boolean);
begin
  Create(ACreateSuspended, true {AAddToActiveThreadList});
end;


constructor TtiThread.Create(const ACreateSuspended: boolean; const AAddToActiveThreadList: boolean);
begin
  inherited Create(ACreateSuspended);
  FreeOnTerminate := true;
  inherited OnTerminate := DoOnTerminate;
  if AAddToActiveThreadList then
  begin
    FThreadInstanceID := gTIOPFManager.ActiveThreadList.GetNewThreadInstanceID;
    gTIOPFManager.ActiveThreadList.Add(Self);
  end;

  FInActiveThreadList := AAddToActiveThreadList;
end;


destructor TtiThread.Destroy;
begin
  {$IFDEF MSWINDOWS}
  tiWin32CoUnInitialize; // You never know, perhpas COM was used in this thread.
  {$ENDIF}
  if FInActiveThreadList then
    gTIOPFManager.ActiveThreadList.Remove(Self);
  inherited Destroy;
end;


procedure TtiThread.DoOnTerminate(Sender: TObject);
begin
  if Assigned(FOnTerminate) then
    FOnTerminate(Sender);
end;

procedure TtiThread.SetText(const AValue: string);
begin
  FText := AValue;
end;

procedure TtiSleepThread.SetThreadName(const AName: string);
begin
  FName := AName; // Need to store the name in the heap
  SetIdeDebuggerThreadName(Self.ThreadID, PChar(FName));
end;

{ TtiThreadList }

constructor TtiThreadList.Create;
begin
  inherited;
  FCritSect := TCriticalSection.Create;
end;

destructor TtiThreadList.Destroy;
begin
  FCritSect.Free;
  inherited;
end;

procedure TtiThreadList.ForEach(AMethod: TtiThreadEvent);
var
  i: integer;
begin
  Lock;
  try
    for i := 0 to Count - 1 do
      AMethod(Items[i]);
  finally
    Unlock;
  end;
end;

procedure TtiThreadList.ForEach(AMethod: TtiThreadEventRegular);
var
  i: integer;
begin
  Lock;
  try
    for i := 0 to Count - 1 do
      AMethod(Items[i]);
  finally
    Unlock;
  end;
end;

function TtiThreadList.GetItem(Index: integer): TtiThread;
begin
  result := TtiThread(inherited GetItem(Index));
end;

procedure TtiThreadList.SetItem(Index: integer; const Value: TtiThread);
begin
  inherited SetItem(Index, Value);
end;

procedure TtiThreadList.Lock;
begin
  FCritSect.Enter;
end;

procedure TtiThreadList.ResumeAll;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Resume;
end;

procedure TtiThreadList.Unlock;
begin
  FCritSect.Leave;
end;

procedure TtiThreadList.Terminate;
var
  i: integer;
begin
  Lock;
  try
    for i := 0 to Count - 1 do
      Items[i].Terminate;
  finally
    Unlock;
  end;
end;

procedure TtiThreadList.WaitForAll;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    TtiThread(Items[i]).WaitFor;
end;

{ TtiActiveThreadList }

procedure TtiActiveThreadList.Add(const AThread: TtiThread);
begin
  FCritSect.Enter;
  try
    FList.Add(AThread);
    FList.Capacity:= FList.Count; // To suppress a memory leak being reported by DUnit2
    DoThreadCountChange(FList.Count, AThread);
  finally
    FCritSect.Leave;
  end;
end;


constructor TtiActiveThreadList.Create;
begin
  inherited;
  FList := TtiThreadList.Create;
  FList.OwnsObjects := False;
  FCritSect := TCriticalSection.Create;
  FThreadCount:= 0;
  FNewThreadInstanceID := 0;
end;

destructor TtiActiveThreadList.Destroy;
begin
  // ToDo: Should call WaitForAll, but that has problems...
  FList.Free;
  FCritSect.Free;
  inherited;
end;

procedure TtiActiveThreadList.DoThreadCountChange(AThreadCount: integer; const AThread: TThread);
begin
  // We should be called whilst the critical section lock is acquired so
  // this is just protection in case we forget!
  FCritSect.Enter;
  try
    if FThreadCount <> AThreadCount then
    begin
      FThreadCount:= AThreadCount;
      if Assigned(FOnThreadCountChange) then
        TThread.Synchronize(AThread, DoThreadCountChangeSynchronized);
    end;
  finally
    FCritSect.Leave;
  end;
end;

procedure TtiActiveThreadList.DoThreadCountChangeSynchronized;
begin
  Assert(GetCurrentThreadID = MainThreadID, 'Current thread not main thread');

  // Call the thread count change event handler passing the thread count.
  // We pass the thread count so that the main thread does not need to
  // retrieve it as this would require a lock on the critical section which
  // would cause a deadlock as the thread that was added/removed in the list
  // that caused the thread count change already has the lock.
  if Assigned(FOnThreadCountChange) then
    FOnThreadCountChange(FThreadCount);
end;

procedure TtiActiveThreadList.ForEach(AMethod: TtiThreadEvent);
begin
  FCritSect.Enter;
  try
    FList.ForEach(AMethod);
  finally
    FCritSect.Leave;
  end;
end;

function TtiActiveThreadList.FindThreadByInstanceID(
  const AThreadInstanceID: Integer): TtiThread;
var
  i: Integer;
begin
  result := nil;
  for i := 0 to FList.Count - 1 do
    if FList.Items[i].ThreadInstanceID = AThreadInstanceID then
    begin
      result := FList.Items[i];
      exit; //-->
    end; 
end;

procedure TtiActiveThreadList.ForEach(AMethod: TtiThreadEventRegular);
begin
  FCritSect.Enter;
  try
    FList.ForEach(AMethod);
  finally
    FCritSect.Leave;
  end;
end;

function TtiActiveThreadList.GetActiveThreadNames: string;
var
  i: Integer;
begin
  FCritSect.Enter;
  try
    result:= '';
    for i := 0 to FList.Count-1 do
    begin
      if result <> '' then
        result:= result + tiLineEnd;
      result:= result + FList.Items[i].ClassName;
    end;
  finally
    FCritSect.Leave;
  end;
end;

function TtiActiveThreadList.GetActiveThreadTextDescriptions: string;
var
  i: Integer;
  LUnknownThreadCount: Integer;
  LDescription: string;
begin
  FCritSect.Enter;
  try
    result:= '';
    LUnknownThreadCount := 0;
    for i := 0 to FList.Count-1 do
    begin
      LDescription := FList.Items[i].Description;
      if LDescription = '' then
        LDescription := FList.Items[i].Text;
      if LDescription <> '' then
      begin
        if result <> '' then
          result:= result + tiLineEnd;
        result:= result + LDescription;
      end else
        Inc(LUnknownThreadCount);
    end;
    if LUnknownThreadCount > 0 then
    begin
      if result <> '' then
        result:= result + tiLineEnd + 'and ';
      result:= result + Format('%d system background tasks', [LUnknownThreadCount]);
    end;
  finally
    FCritSect.Leave;
  end;
end;

function TtiActiveThreadList.GetNewThreadInstanceID: Integer;
begin
  Inc(FNewThreadInstanceID);
  result := FNewThreadInstanceID;
end;

function TtiActiveThreadList.GetThreadCount: integer;
begin
  FCritSect.Enter;
  try
    result:= FThreadCount;
  finally
    FCritSect.Leave;
  end;
end;

function TtiActiveThreadList.InstanceOfThreadClassIsActive(
  const AThreadClass: TtiThreadClass): boolean;
var
  i: integer;
begin
  result := false;
  FCritSect.Enter;
  try
    for i := 0 to FList.Count - 1 do
      if FList.Items[i] is AThreadClass then
      begin
        result := true;
        exit;
      end;
  finally
    FCritSect.Leave;
  end;  
end;

procedure TtiActiveThreadList.Remove(const AThread: TtiThread);
var
  LIndex: integer;
begin
  FCritSect.Enter;
  try
    LIndex:= FList.IndexOf(AThread);
    if LIndex <> -1 then
    begin
      FList.Delete(LIndex);
      FList.Capacity:= FList.Count; // To suppress a memory leak being reported by DUnit2
      DoThreadCountChange(FList.Count, AThread);
    end;
  finally
    FCritSect.Leave;
  end;
end;

procedure TtiActiveThreadList.SetOnThreadCountChange(
  const AValue: TtiThreadCountChangeEvent);
begin
  FCritSect.Enter;
  try
    FOnThreadCountChange := AValue;
  finally
    FCritSect.Leave;
  end;
end;

procedure TtiActiveThreadList.Terminate;
var
  i : integer;
begin
  FCritSect.Enter;
  try
    for i := FList.Count - 1 downto 0 do
      FList.Items[i].Terminate;
  finally
    FCritSect.Leave;
  end;
end;


procedure TtiActiveThreadList.TerminateThreadByInstanceID(const AThreadInstanceID: Integer);
var
  LThread: TtiThread;
begin
  LThread := FindThreadByInstanceID(AThreadInstanceID);
  //TODO: How should we handle FindThreadByThreadID = nil? Throw exception or just check assigned?
  LThread.WakeUpAndTerminate;
end;

procedure TtiActiveThreadList.WaitForAll;
begin
  while Count > 0 do
  begin
    Sleep(100);
    {$IFDEF MSWINDOWS}
      {$IFNDEF FPC}
      Application.ProcessMessages;
      {$ENDIF}
    {$ENDIF MSWINDOWS}
  end;
end;

{ TtiSleepThread }

constructor TtiSleepThread.Create(ASuspended: boolean);
begin
  inherited Create(ASuspended);
  FSleepResponse:= cDefaultSleepResponse;
  FUpdateEvent := TEvent.Create(nil, True, False, '');
  FFinished := True;
end;


function TtiSleepThread.SleepAndCheckTerminated(ASleepFor: Cardinal): boolean;
var
  LStart: DWord;
begin
  LStart := tiGetTickCount;
  while ((tiGetTickCount - LStart) <= ASleepFor) and (not Terminated) do
    Sleep(FSleepResponse);
  //Call wakeup if terminated
  Result := not Terminated;
end;


procedure TtiSleepThread.WakeUp;
begin
  FUpdateEvent.SetEvent;
end;

procedure TtiSleepThread.Execute;
var
  intf: IInterface;
begin
  intf := TAutoFinishedState.Create(FFinished);
  { FFinished will automatically be set to True once it goes out of scope }
end;

{$IFDEF FPC}
procedure TtiSleepThread.WaitFor;
begin
  { graemeg: 2009-05-04
    FPC handles WaitFor slightly different under Unix environments, so I rather
    do the following which seems safer. Delphi could probably also use this
    method (and will probably be needed when it gets cross-platfrom support).
    When the Execute() method is done, it will set Finished to True,
    which we can then detect to know that the thread is done.
    The default TThread.WaitFor is a blocking method under Unix, suspending the
    main thread. If the thread calls synchronise, it waits for the main thread which
    is suspended, thus we sit with a deadlock! This issue is only under Unix.
    Under Windows (applies to FPC and Delphi) we use a specific Windows API to make
    TThread.WaitFor non-blocking.

    See the following URL for a more detailed explanation:
      http://free-pascal-general.1045716.n5.nabble.com/TThread-WaitFor-not-returning-td2820297.html
    }
  while not FFinished do CheckSynchronize(100);
end;
{$ENDIF}

procedure TtiSleepThread.WakeUpAndTerminate;
begin
  WakeUp;
  Terminate;
end;

destructor TtiSleepThread.Destroy;
begin
  // If it's a low priority thread, it may never finish running so it can
  // be destroyed. (Destroy calls WaitFor)
  // This became an issue with Delphi 6 apps hanging on shutdown.
  if Priority < tpNormal then
    Priority := tpNormal;
  FUpdateEvent.Free;
  inherited Destroy;
end;

end.
