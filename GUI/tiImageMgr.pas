(*

  === Delphi ===

  Add the resources to a .rc file like this:
    MyJPEG           JPEG    "..\MyJPEG.jpg"
    MyBMP            BITMAP  "..\ByBitMap.bmp"

  Then compile the .rc into a .res file like this:
    brcc32 MyRes.rc

  This will create a res file named MyRes.res

  Then add this res to your application, or a DLL like this
    {$R MyRes.res}

  If the resouces are in a DLL, you must load the DLL like this:
    gTIImageListMgr.LoadResourceDLL('MyResDLL.DLL');

  If the resources are in the main exe, then just use
    gTIImateListMgr


  === Lazarus ===

  Add the resources to a .rc file (as shown above)

  Then include the the resource file in your project
    {$R MyRes.rc}

  Compile your project. FPC will automatically compile the
  .rc file and include the .res version. You can also pre-compile
  the .rc file and include the .res file (as shown in the Delphi
  instructions).

  If the resources are in the main exe, then just use
    gTIImateListMgr


*)

unit tiImageMgr;

{$I tiDefines.inc}

interface
uses
  Controls
  ,Classes
{$IFDEF FPC}
  ,LCLIntf
{$ELSE}
  ,Windows
{$ENDIF}
  ,Graphics
  ,tiSpeedButton
 ;

const
  cErrorFailedLoadingResourceDLL = 'Failed loading resource DLL <%s>. Called in %s';
  cErrorInvalidImageState        = 'Invalid TtiImageState. Called in %s';
  cErrorInvalidImageSize         = 'Invalid TtiImageSize. Called in %s';

type

  TtiImageSize   = (tiIS16, tiIS24);
  TtiImageSizes  = set of TtiImageSize;
  TtiImageState  = (tiISNormal, tiISHot, tiISDisabled);
  TtiImageStates = set of TtiImageState;
const
  ctiImageSizes : array[TtiImageSize] of string =
                 ('16', '24');
  ctiImageStates : array[TtiImageState] of string =
                 ('N', 'H', 'D');
type

  TtiImageListMgr = class(TObject)
  private
    FILNormal16      : TImageList;
    FILHot16         : TImageList;
    FILDisabled16    : TImageList;
    FILNormal24      : TImageList;
    FILHot24         : TImageList;
    FILDisabled24    : TImageList;
    FImageNames16    : TStringList;
    FImageNames24    : TStringList;
    FResFileInstance : THandle;
    FResFileName     : String;
    FOwnsImageLists: boolean;
    FtiOPFImagesLoaded : Boolean;
    procedure  LoadStateImagesFromResource(const pResName, pRefName: string; pSize: TtiImageSize; pState: TtiImageState);
    function   GetILDisabled16 : TImageList;
    function   GetILHot16     : TImageList;
    function   GetILNormal16  : TImageList;
    function   GetILDisabled24: TImageList;
    function   GetILHot24: TImageList;
    function   GetILNormal24: TImageList;
    procedure  FreeImageLists;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   LoadTIOPFImages;

    procedure   LoadResourceDLL(const pDLLName : string);

    property    OwnsImageLists : boolean read FOwnsImageLists  write FOwnsImageLists;
    property    ILNormal16  : TImageList read GetILNormal16   write FILNormal16;
    property    ILHot16     : TImageList read GetILHot16      write FILHot16;
    property    ILDisabled16 : TImageList read GetILDisabled16 write FILDisabled16;

    property    ILNormal24  : TImageList read GetILNormal24   write FILNormal24;
    property    ILHot24     : TImageList read GetILHot24      write FILHot24;
    property    ILDisabled24 : TImageList read GetILDisabled24 write FILDisabled24;

    procedure   LoadImagesFromResource(const pResName, pRefName: string; pSizes: TtiImageSizes); overload;
    procedure   LoadImagesFromResource(const pResName : string; pSizes: TtiImageSizes); overload;
    function    ImageIndex(const pImageList : TImageList; const pImageName : string): integer;
    function    ImageIndex16(const pImageName : string): integer;
    function    ImageIndex24(const pImageName : string): integer;
    procedure   LoadBMPFromRes(const pResName: string; const pBMP    : TBitMap);
    {$IFNDEF FPC}
    procedure   LoadJPGFromRes(const pResName: string; const pPicture : TPicture);
    {$ENDIF}
    procedure   LoadBMPFromImageList16(const pResName: string; const pBMP    : TBitMap);
    procedure   LoadIconFromRes(const pResName : string);
    procedure   LoadBMPToTISPeedButton16(const pResName: string; const pButton : TtiSpeedButton);
    procedure   LoadBMPToTISPeedButton24(const pResName: string; const pButton : TtiSpeedButton);
  end;

function gTIImageListMgr : TtiImageListMgr;

implementation
uses
  SysUtils
  {$IFNDEF FPC}
  ,JPeg
  {$ENDIF}
  ,tiResources
  ,Forms
 ;

var
  uTIImageListMgr : TtiImageListMgr;

function gTIImageListMgr : TtiImageListMgr;
begin
  if uTIImageListMgr = nil then
    uTIImageListMgr := TtiImageListMgr.Create;
  result := uTIImageListMgr;
end;

constructor TtiImageListMgr.Create;
begin
  inherited;
  FImageNames16   := TStringList.Create;
  FImageNames24   := TStringList.Create;
  FResFileName    := ExtractFileName(ParamStr(0));
  FResFileInstance := HInstance;
  FOwnsImageLists := true;
  FtiOPFImagesLoaded := False;
  // ToDo: Come up with some way of loading the images for design time -
  //       while still allowing the image lists to be changed, and custom
  //       images to be added.
  //LoadTIOPFImages;
end;

procedure TtiImageListMgr.FreeImageLists;
begin
  if FOwnsImageLists then
  begin
    FreeAndNil(FILNormal16);
    FreeAndNil(FILHot16);
    FreeAndNil(FILDisabled16);
    FreeAndNil(FILNormal24);
    FreeAndNil(FILHot24);
    FreeAndNil(FILDisabled24);
  end;
end;

destructor TtiImageListMgr.Destroy;
begin
  FImageNames16.Free;
  FImageNames24.Free;
  FreeImageLists;
  {$IFNDEF FPC}
  if FResFileInstance <> HInstance then
    FreeLibrary(FResFileInstance);
  {$ENDIF}
  inherited;
end;

function TtiImageListMgr.ImageIndex(
  const pImageList: TImageList;
  const pImageName: string): integer;
begin

  Assert(pImageList <> nil, 'pImageList not assigned');
  Assert((pImageList = ILNormal16) or
          (pImageList = ILNormal24), 'pImageList not one fo internal image lists');
  result := -1;
  Assert(pImageName <> '', 'pImageName not assigned');
  if not FTIOPFImagesLoaded then
    LoadTIOPFImages;
  if pImageList = ILNormal16 then
    result := FImageNames16.IndexOf(UpperCase(pImageName))
  else if pImageList = ILNormal24 then
    result := FImageNames24.IndexOf(UpperCase(pImageName))

end;

procedure TtiImageListMgr.LoadImagesFromResource(const pResName, pRefName : string;
                                                 pSizes : TtiImageSizes {; pStates : TtiImageStates});
var
  lSize : TtiImageSize;
  lState : TtiImageState;
  pStates : TtiImageStates;
begin
  pStates := [tiISNormal, tiISHot, tiISDisabled];
  for lSize := Low(TtiImageSize) to High(TtiImageSize) do
    if lSize in pSizes then
      for lState := Low(TtiImageState) to High(TtiImageState) do
        if lState in pStates then
          LoadStateImagesFromResource(pResName, pRefName, lSize, lState);
end;

procedure TtiImageListMgr.LoadResourceDLL(const pDLLName: string);
begin
{$IFNDEF FPC}
  FResFileInstance := LoadLibrary(PChar(pDLLName));
  if FResFileInstance = 0 then
    raise exception.CreateFmt(cErrorFailedLoadingResourceDLL,
                               [pDLLName, ClassName + '.LoadResourceDLL']);
  FResFileName := pDLLName;
{$ENDIF}
end;

procedure TtiImageListMgr.LoadBMPFromRes(const pResName : string; const pBMP : TBitMap);
const
  RT_BITMAP = MAKEINTRESOURCE(2);
begin
 if FindResource(FResFileInstance, PChar(pResName), RT_BITMAP) <> 0 then
    pBMP.LoadFromResourceName(FResFileInstance, pResName)
  else
    pBMP.LoadFromResourceName(HInstance, pResName);
end;

procedure TtiImageListMgr.LoadStateImagesFromResource(const pResName, pRefName : string; pSize : TtiImageSize; pState : TtiImageState);
var
  lBMP : TBitMap;
  lResName : string;
begin
  Assert(ILNormal16   <> nil, 'FILNormal16   not assigned');
  Assert(ILHot16      <> nil, 'FILHot16      not assigned');
  Assert(ILDisabled16 <> nil, 'FILDisabled16 not assigned');
  Assert(ILNormal24   <> nil, 'FILNormal24   not assigned');
  Assert(ILHot24      <> nil, 'FILHot24      not assigned');
  Assert(ILDisabled24 <> nil, 'FILDisabled24 not assigned');

  lBMP := TBitMap.Create;
  try
    lResName := pResName + '_' +
                ctiImageSizes[pSize] +
                ctiImageStates[pState];
    LoadBMPFromRes(lResName, lBMP);
    if (pSize = tiIS16) then
    begin
      if (pState = tiISNormal) then
      begin
        FImageNames16.Add(UpperCase(pRefName));
        ILNormal16.AddMasked(lBMP, clDefault);
      end
      else if (pState = tiISHot) then
        ILHot16.AddMasked(lBMP, clDefault)
      else if (pState = tiISDisabled) then
        ILDisabled16.AddMasked(lBMP, clDefault)
      else
        raise Exception.CreateFmt(cErrorInvalidImageState, [ClassName + '.LoadSingleImage']);
    end
    else if (pSize = tiIS24) then
    begin
      if (pState = tiISNormal) then
      begin
        FImageNames24.Add(UpperCase(pRefName));
        ILNormal24.AddMasked(lBMP, clDefault);
      end
      else if (pState = tiISHot) then
        ILHot24.AddMasked(lBMP, clDefault)
      else if (pState = tiISDisabled) then
        ILDisabled24.AddMasked(lBMP, clDefault)
      else
        raise Exception.CreateFmt(cErrorInvalidImageState, [ClassName + '.LoadSingleImage']);
    end
    else
        raise Exception.CreateFmt(cErrorInvalidImageSize, [ClassName + '.LoadSingleImage']);

  finally
    lBMP.Free;
  end;
end;

{$IFNDEF FPC}
procedure TtiImageListMgr.LoadJPGFromRes(const pResName : string;
                                          const pPicture : TPicture);
var
  lResHandle : THandle;
  lMemHandle : THandle;
  lMemStream : TMemoryStream;
  lResPtr   : PByte;
  lResSize  : Longint;
  lJPEGImage : TJPEGImage;
begin
  lResHandle := FindResource(FResFileInstance, PChar(pResName), 'JPEG');
  Assert(lResHandle<>0, 'Unable to find resource <' + pResName + '> in <' +
         FResFileName + '>');
  lMemHandle := LoadResource(FResFileInstance, lResHandle);
  lResPtr   := LockResource(lMemHandle);
  lMemStream := TMemoryStream.Create;
  try
    lJPEGImage := TJPEGImage.Create;
    try
      lResSize := SizeOfResource(FResFileInstance, lResHandle);
      lMemStream.SetSize(lResSize);
      lMemStream.Write(lResPtr^, lResSize);
      FreeResource(lMemHandle);
      lMemStream.Seek(0, 0);
      lJPEGImage.LoadFromStream(lMemStream);
      pPicture.Assign(lJPEGImage);
    finally
      lJPEGImage.Free;
    end;
  finally
    lMemStream.Free;
  end;
end;
{$ENDIF}

procedure TtiImageListMgr.LoadImagesFromResource(const pResName: string;
  pSizes: TtiImageSizes);
begin
  LoadImagesFromResource(pResName, pResName, pSizes);
end;

function TtiImageListMgr.ImageIndex16(const pImageName: string): integer;
begin
  if not FTIOPFImagesLoaded then
    LoadTIOPFImages;
  result := FImageNames16.IndexOf(UpperCase(pImageName))
end;

function TtiImageListMgr.ImageIndex24(const pImageName: string): integer;
begin
  if not FTIOPFImagesLoaded then
    LoadTIOPFImages;
  result := FImageNames24.IndexOf(UpperCase(pImageName))
end;

procedure TtiImageListMgr.LoadBMPFromImageList16(const pResName: string; const pBMP: TBitMap);
var
  i : integer;
begin
  i := ImageIndex16(pResName);
  if i <> -1 then
    ILNormal16.GetBitmap(i, pBMP);
end;

function TtiImageListMgr.GetILDisabled16: TImageList;
begin
  if FOwnsImageLists and (FILDisabled16 = nil) then
  begin
    FILDisabled16 := TImageList.Create(nil);
    FILDisabled16.Height := 16;
    FILDisabled16.Width := 16;
  end;
  result := FILDisabled16;
end;

function TtiImageListMgr.GetILHot16:TImageList;
begin
  if FOwnsImageLists and (FILHot16 = nil) then
  begin
    FILHot16 := TImageList.Create(nil);
    FILHot16.Height := 16;
    FILHot16.Width := 16;
  end;
  result := FILHot16;
end;

function TtiImageListMgr.GetILNormal16:TImageList;
begin
  if FOwnsImageLists and (FILNormal16 = nil) then
  begin
    FILNormal16 := TImageList.Create(nil);
    FILNormal16.Height := 16;
    FILNormal16.Width := 16;
  end;
  result := FILNormal16;
end;

function TtiImageListMgr.GetILDisabled24: TImageList;
begin
  if FOwnsImageLists and (FILDisabled24 = nil) then
  begin
    FILDisabled24 := TImageList.Create(nil);
    FILDisabled24.Height := 24;
    FILDisabled24.Width := 24;
  end;
  result := FILDisabled24;
end;

function TtiImageListMgr.GetILHot24: TImageList;
begin
  if FOwnsImageLists and (FILHot24 = nil) then
  begin
    FILHot24 := TImageList.Create(nil);
    FILHot24.Height := 24;
    FILHot24.Width := 24;
  end;
  result := FILHot24;
end;

function TtiImageListMgr.GetILNormal24: TImageList;
begin
  if FOwnsImageLists and (FILNormal24 = nil) then
  begin
    FILNormal24 := TImageList.Create(nil);
    FILNormal24.Height := 24;
    FILNormal24.Width := 24;
  end;
  result := FILNormal24;
end;

procedure TtiImageListMgr.LoadTIOPFImages;
var
  lResFileInstance : THandle;
begin
  if FtiOPFImagesLoaded then
    Exit; //==>

  lResFileInstance := FResFileInstance;
  FResFileInstance := HInstance;
  try
    // ToDo: Replace these calls with references to the ordinal values, not the constant name.

    LoadImagesFromResource(cResTI_Exit,                        [tiIS16,tiIS24]{, [tiISNormal,tiISHot,tiISDisabled]});
    LoadImagesFromResource(cResTI_CloseWindow,                 [tiIS16,tiIS24]{, [tiISNormal,tiISHot,tiISDisabled]});
    LoadImagesFromResource(cResTI_ArrowRight,                  [tiIS16,tiIS24]{, [tiISNormal,tiISHot,tiISDisabled]});
    LoadImagesFromResource(cResTI_ArrowLeft,                   [tiIS16,tiIS24]{, [tiISNormal,tiISHot,tiISDisabled]});
    LoadImagesFromResource(cResTI_Help,                        [tiIS16,tiIS24]{, [tiISNormal,tiISHot,tiISDisabled]});
    LoadImagesFromResource(cResTI_HelpAbout,                   [tiIS16,tiIS24]{, [tiISNormal,tiISHot,tiISDisabled]});
    LoadImagesFromResource(cResTI_HelpWhatsThis,              [tiIS16,tiIS24]{, [tiISNormal,tiISHot,tiISDisabled]});
    LoadImagesFromResource(cResTI_WorkList,                    [tiIS16,tiIS24]{, [tiISNormal,tiISHot,tiISDisabled]});
    LoadImagesFromResource(cResTI_GoTo,                        [tiIS16]{,        [tiISNormal,tiISHot,tiISDisabled]});

    //LoadImagesFromResource(cResTI_Tick, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_Cross, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    //LoadImagesFromResource(cResTI_Browse, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    //LoadImagesFromResource(cResTI_CancelSave, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    //LoadImagesFromResource(cResTI_Delete, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    //LoadImagesFromResource(cResTI_Edit, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    //LoadImagesFromResource(cResTI_Execute, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_FileOpen, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_Find, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    //LoadImagesFromResource(cResTI_FullScreen, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    //LoadImagesFromResource(cResTI_GraphBar, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_GraphLine, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    //LoadImagesFromResource(cResTI_Insert, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_Query, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    //LoadImagesFromResource(cResTI_ReDo, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    //LoadImagesFromResource(cResTI_Refresh, [tiIS16]);
    //LoadImagesFromResource(cResTI_SaveAll, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_Save, [tiIS16]);
    LoadImagesFromResource(cResTI_Redo, [tiIS16]);
    LoadImagesFromResource(cResTI_Undo, [tiIS16]);
    LoadImagesFromResource(cResTI_Sort, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_SelectCols, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_Export, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_CutToClipboard, [tiIS16]);
    LoadImagesFromResource(cResTI_CopyToClipboard, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_PasteFromClipboard, [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_ExportToCSV,     [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_ExportToHTML,    [tiIS16]{, [tiISNormal, tiISHot, tiISDisabled]});
    LoadImagesFromResource(cResTI_ZoomIn,          [tiIS16]);
    LoadImagesFromResource(cResTI_ZoomOut,         [tiIS16]);
    LoadImagesFromResource(cResTI_Maximize,        [tiIS16]);
    LoadImagesFromResource(cResTI_Copy1Left,       [tiIS16]);
    LoadImagesFromResource(cResTI_CopyAllLeft,     [tiIS16]);
    LoadImagesFromResource(cResTI_Copy1Right,      [tiIS16]);
    LoadImagesFromResource(cResTI_CopyAllRight,    [tiIS16]);

    LoadImagesFromResource(cResTI_View,            [tiIS16]);
    LoadImagesFromResource(cResTI_Insert,          [tiIS16]);
    LoadImagesFromResource(cResTI_Edit,            [tiIS16]);
    LoadImagesFromResource(cResTI_Delete,          [tiIS16]);
    LoadImagesFromResource(cResTI_Deletex,         [tiIS16, tiIS24]);

    LoadImagesFromResource(cResTI_OpenImage,       [tiIS16]);
    LoadImagesFromResource(cResTI_Print,           [tiIS16]);
    LoadImagesFromResource(cResTI_PrintSetup,      [tiIS16]);

    LoadImagesFromResource(cResTI_CheckBoxChecked,   [tiIS16]);
    LoadImagesFromResource(cResTI_CheckBoxUnChecked, [tiIS16]);

  finally
    FResFileInstance := lResFileInstance;
  end;
  FtiOPFImagesLoaded := True;
end;

procedure TtiImageListMgr.LoadIconFromRes(const pResName: string);
begin
  Application.Icon.Handle := LoadIcon(FResFileInstance, PChar(pResName));
end;

procedure TtiImageListMgr.LoadBMPToTISPeedButton16(const pResName: string; const pButton: TtiSpeedButton);
begin
  Assert(pResName <> '', 'pResName not assigned');
  Assert(pButton <> nil, 'pButton not assigned');
  pButton.ClearGlyphs;
  LoadBMPFromRes(pResName + cResTI_16N, pButton.Glyph);
  LoadBMPFromRes(pResName + cResTI_16H, pButton.GlyphHot);
  LoadBMPFromRes(pResName + cResTI_16D, pButton.GlyphDisabled);
end;

procedure TtiImageListMgr.LoadBMPToTISPeedButton24(const pResName: string;const pButton: TtiSpeedButton);
begin
  Assert(pResName <> '', 'pResName not assigned');
  Assert(pButton <> nil, 'pButton not assigned');
  pButton.ClearGlyphs;
  LoadBMPFromRes(pResName + cResTI_24N, pButton.Glyph);
  LoadBMPFromRes(pResName + cResTI_24H, pButton.GlyphHot);
  LoadBMPFromRes(pResName + cResTI_24D, pButton.GlyphDisabled);
end;

initialization

finalization
  if Assigned(uTIImageListMgr) then
    uTIImageListMgr.Free;

end.
