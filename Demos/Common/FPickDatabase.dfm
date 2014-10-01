object FormPickDatabase: TFormPickDatabase
  Left = 371
  Top = 234
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = ' Enter database connection details'
  ClientHeight = 196
  ClientWidth = 728
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 4
    Top = 8
    Width = 716
    Height = 137
    Anchors = [akLeft, akTop, akRight]
    Caption = ' Database connection details '
    TabOrder = 0
    object sbDefaultToPresetValues: TtiSpeedButton
      Left = 555
      Top = 20
      Width = 146
      Height = 22
      Cursor = crHandPoint
      Anchors = [akTop, akRight]
      Caption = 'Default to preset values'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsUnderline]
      ParentFont = False
      OnClick = sbDefaultToPresetValuesClick
      ImageRes = tiRINone
    end
    object paePersistenceLayer: TtiPerAwareEdit
      Left = 8
      Top = 20
      Width = 540
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      Constraints.MinHeight = 23
      TabOrder = 0
      LabelLayout = tlTop
      Caption = 'P&ersistence layer name'
      LabelWidth = 120
      LabelFont.Charset = DEFAULT_CHARSET
      LabelFont.Color = clBlack
      LabelFont.Height = -11
      LabelFont.Name = 'MS Sans Serif'
      LabelFont.Style = []
      LabelParentFont = False
      ReadOnly = False
      MaxLength = 0
      CharCase = ecNormal
      PasswordChar = #0
    end
    object paeDatabaseName: TtiPerAwareEdit
      Left = 8
      Top = 48
      Width = 540
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      Constraints.MinHeight = 23
      TabOrder = 1
      LabelLayout = tlTop
      Caption = '&Database name'
      LabelWidth = 120
      LabelFont.Charset = DEFAULT_CHARSET
      LabelFont.Color = clBlack
      LabelFont.Height = -11
      LabelFont.Name = 'MS Sans Serif'
      LabelFont.Style = []
      LabelParentFont = False
      ReadOnly = False
      MaxLength = 0
      CharCase = ecNormal
      PasswordChar = #0
    end
    object paeUserName: TtiPerAwareEdit
      Left = 8
      Top = 76
      Width = 540
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      Constraints.MinHeight = 23
      TabOrder = 2
      LabelLayout = tlTop
      Caption = '&User name'
      LabelWidth = 120
      LabelFont.Charset = DEFAULT_CHARSET
      LabelFont.Color = clBlack
      LabelFont.Height = -11
      LabelFont.Name = 'MS Sans Serif'
      LabelFont.Style = []
      LabelParentFont = False
      ReadOnly = False
      MaxLength = 0
      CharCase = ecNormal
      PasswordChar = #0
    end
    object paePassword: TtiPerAwareEdit
      Left = 8
      Top = 104
      Width = 540
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      Constraints.MinHeight = 23
      TabOrder = 3
      LabelLayout = tlTop
      Caption = '&Password'
      LabelWidth = 120
      LabelFont.Charset = DEFAULT_CHARSET
      LabelFont.Color = clBlack
      LabelFont.Height = -11
      LabelFont.Name = 'MS Sans Serif'
      LabelFont.Style = []
      LabelParentFont = False
      ReadOnly = False
      MaxLength = 0
      CharCase = ecNormal
      PasswordChar = #0
    end
  end
  object PM: TPopupMenu
  end
  object AL: TActionList
    Left = 28
    object Action1: TAction
      Caption = 'Action1'
    end
  end
end
