{$I tiDefines.inc}

unit tiOPFControlsReg;

interface
uses
  Classes
  ,ActnList
  {$IFNDEF FPC}
   {$IFNDEF VER130}
     ,DesignIntf
     ,DesignEditors
   {$ELSE}
     ,DsgnIntf
   {$ENDIF}
  {$ELSE}
  ,ComponentEditors
  ,PropEdits
  ,LazarusPackageIntf
  ,LResources
  {$ENDIF FPC}
  ,DtiDefaultActionValues
  ,tiPerAwareCtrls
  ,tiPerAwareFileCombos
  ,tiMemoReadOnly
  ,tiPerAwareMultiSelect
  ,tiReadOnly
  ,tiHyperlink
  ,tiSpeedButton
  ,tiButtons
  ,tiRoundedPanel
  ,tiPerAwareDateRange
  ,tiListView
  ,tiListViewCtrls
  ,tiListViewPlus
  ,tiListViewDif
  ,tiSplitter
  ,tiSplitterEditor
  ,tiTreeView
  ,tiTreeViewChildForm
  {$IFNDEF FPC}
  ,tiPerAwareDirectoryCombos
  {$IFNDEF DELPHI2009ORABOVE}
  ,tiVTListView
  ,tiVTTreeView
  {$ENDIF}
  {$ENDIF}
  ,tiTreeviewEditor
  ,tiHyperlinkWithImage
  ,tiModelMediator
 ;


procedure Register;

implementation

{$IFNDEF FPC}
  {$R tiOPFControls.dcr}
{$ENDIF}

procedure Register;
begin
  RegisterComponents('TechInsite Base',
                      [   TtiPerAwareEdit
                         ,TtiPerAwareMemo
                         ,TtiPerAwareComboBoxStatic
                         ,TtiPerAwareComboBoxDynamic
                         ,TtiPerAwareComboBoxHistory
                         ,TtiPerAwareDateTimePicker
                         ,TtiPerAwareCheckBox
                         ,TtiPerAwareFloatEdit
                         ,TtiPerAwareImageEdit
                         ,TtiDateRange
                         ,TtiPerAwareDateTimeEdit
                         ,TtiPerAwareTimeEdit
                         ,TtiPerAwareDateEdit
                      ]);




  RegisterComponents('TechInsite Extra',
                      [  TtiUserDefinedPicker
                         ,TtiPickFile
                         ,TtiPerAwarePickFile
                         {$IFNDEF FPC}
                         ,TtiPickDirectory
                         ,TtiPerAwarePickDirectory
                         {$ENDIF}
                         ,TtiMemoReadOnly
                         ,TtiPerAwareMultiSelect
                         ,TtiReadOnly
                         ,TtiHyperLink
                         ,TtiHyperlinkWithImage
                         ,TtiSpeedButton
                         ,TtiRoundedPanel
                         ,TtiSplitter
                         ,TtiSplitterPanel
                         ,TtiToolBar
                         ,TtiButtonPanel
                         ,TtiMicroButton
                         {$IFNDEF FPC}
                         {$IFNDEF DELPHI2009ORABOVE}
                         ,TtiVTListView
                         ,TtiVTTreeView
                         {$ENDIF}
                         {$ENDIF}
                         ,TtiModelMediator
                         ,TtiModelMediatorList
                      ]);


  RegisterComponents('TechInsite Old',
                      [
                         TtiListView      // Depreciated.  Use TtiVTListView in future
                         ,TtiListViewListBox
                         ,TtiListViewPlus
                         ,TtiListViewDif
                         ,TtiTreeView      // Depreciated.  Use TtiVTTreeView in future
                         ,TtiTreeViewChildForm
                      ]);



  RegisterActions('TechInsite Base',
                   [
                     TtiImageLoadAction
                    ,TtiImageSaveAction
                    ,TtiImagePasteFromClipboardAction
                    ,TtiImageCopyToClipboardAction
                    ,TtiImageEditAction
                    ,TtiImageClearAction
                    ,TtiImageStretchAction
                    ,TtiImageViewAction
                    ,TtiImageNewAction
                    ,TtiImageExportAction
                   ],
                   TtidmDefaultActionValues);

  RegisterComponentEditor(TtiSplitterPanel, TtiSplitterPanelEditor);

  RegisterPropertyEditor(TypeInfo(TtiTVNodeEvent),            // TypeInfo of property
                          TtiTVDataMapping,                   // ClassRef of component containing property
                          '',                                 // Name of property
                          TtiTVNodeEventPropertyEditor);      // ClassRef of property editor

  RegisterPropertyEditor(TypeInfo(TtiTVNodeConfirmEvent),     // TypeInfo of property
                          nil,                                // ClassRef of component containing property
                          '',                                 // Name of property
                          TtiTVNodeEventPropertyEditor);      // ClassRef of property editor


  RegisterPropertyEditor(TypeInfo(TtiTVDragDropEvent),        // TypeInfo of property
                          nil,                                // ClassRef of component containing property
                          '',                                 // Name of property
                          TtiTVNodeEventPropertyEditor);      // ClassRef of property editor

  RegisterPropertyEditor(TypeInfo(TtiTVDragDropConfirmEvent), // TypeInfo of property
                          nil,                                // ClassRef of component containing property
                          '',                                 // Name of property
                          TtiTVNodeEventPropertyEditor);      // ClassRef of property editor

end;

{$IFDEF FPC}
initialization
  {$i tiOPFControls.lrs}
{$ENDIF}

end.
