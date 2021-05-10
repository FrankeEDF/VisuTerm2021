object DebugWindowDlg: TDebugWindowDlg
  Left = 273
  Top = 132
  Width = 696
  Height = 480
  Caption = 'DebugWindowDlg'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 137
    Width = 688
    Height = 309
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Fixedsys'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 688
    Height = 137
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object cbActive: TCheckBox
      Left = 24
      Top = 16
      Width = 97
      Height = 17
      Caption = 'Active'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
    object ListBox1: TListBox
      Left = 184
      Top = 8
      Width = 497
      Height = 113
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Fixedsys'
      Font.Style = []
      ItemHeight = 15
      ParentFont = False
      TabOrder = 1
    end
  end
end
