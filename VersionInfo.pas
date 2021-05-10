unit VersionInfo;

interface

uses Windows,SysUtils;

type  TVersionInfo = record
           CompanyName      : string;
           FileDescription  : string;
           FileVersion      : string;
           InternalName     : string;
           LegalCopyright   : string;
           LegalTradeMarks  : string;
           OriginalFilename : string;
           ProductName      : string;
           ProductVersion   : string;
           Comments         : string;
      end;

  function ReadVersionInfo(FileName:string):TVersionInfo;
  function ReadVersionInfoApp :TVersionInfo;
  function CompareVersionTo (ToVersion : string) : integer;
  function CompareVersions (Version1, Version2 : string) : integer;


implementation

uses Forms;

const
  VerQueryHeader           =  'StringFileInfo\040704E4\';    // german
  // VerQueryHeader           =  'StringFileInfo\040704E4\'; // english

  VerQueryCompanyName      =  'CompanyName';
  VerQueryFileDescription  =  'FileDescription';
  VerQueryFileVersion      =  'FileVersion';
  VerQueryInternalName     =  'InternalName';
  VerQueryLegalCopyright   =  'LegalCopyright';
  VerQueryLegalTradeMarks  =  'LegalTradeMarks';
  VerQueryOriginalFilename =  'OriginalFilename';
  VerQueryProductName      =  'ProductName';
  VerQueryProductVersion   =  'ProductVersion';
  VerQueryComments         =  'Comments';

function ReadVersionInfo(FileName : string) : TVersionInfo;
var
  InfoBufSize,VerBufSize : integer;
  InfoBuf,VerBuf         : PChar;

  function VerQuery(VerInfoValue:string):string;
  begin
     VerQueryValue(InfoBuf,
            PChar(VerQueryHeader + VerInfoValue),
            Pointer(VerBuf), DWORD(VerBufSize));
     if VerBufSize > 0 then Result := VerBuf
                       else Result := '';
  end;

begin
  fillchar (result, sizeof (result), 0);
  InfoBufSize := GetFileVersionInfoSize(PChar(FileName),DWORD(InfoBufSize));
  if InfoBufSize > 0 then
  begin
    InfoBuf := AllocMem(InfoBufSize);
    GetFileVersionInfo(PChar(FileName),0,InfoBufSize,InfoBuf);

    with Result do begin
       CompanyName       := VerQuery (VerQueryCompanyName);
       FileDescription   := VerQuery (VerQueryFileDescription);
       FileVersion       := VerQuery (VerQueryFileVersion);
       InternalName      := VerQuery (VerQueryInternalName);
       LegalCopyright    := VerQuery (VerQueryLegalCopyright);
       LegalTradeMarks   := VerQuery (VerQueryLegalTradeMarks);
       OriginalFilename  := VerQuery (VerQueryOriginalFilename);
       ProductName       := VerQuery (VerQueryProductName);
       ProductVersion    := VerQuery (VerQueryProductVersion);
       Comments          := VerQuery (VerQueryComments);
    end;

    FreeMem(InfoBuf, InfoBufSize);
  end;
end;

function ReadVersionInfoApp :TVersionInfo;
begin
  result := ReadVersionInfo (Application.ExeName);
end;

function CompareVersions (Version1, Version2 : string) : integer;
var
  Version1Number : integer;
  Version1Pos    : integer;
  Version2Number : integer;
  Version2Pos    : integer;
  code           : integer;
begin
  result := 0;
  Version1Pos := 0;
  Version2Pos := 0;
  Version1Number := 0;
  Version2Number := 0;

  while (Result = 0) do begin
    if length (Version1) = 0 then
    begin
      result := -1;
      break;
    end else begin
      val (Version1, Version1Number, code);
      Version1Pos    := Pos ('.', Version1);
    end;
    if length (Version2) = 0 then
    begin
      result := 1;
      break;
    end else begin
      val (Version2, Version2Number, code);
      Version2Pos    := Pos ('.', Version2);
    end;
    if (Version1Number > Version2Number) then result := 1;
    if (Version1Number < Version2Number) then result := -1;
    Version1 := copy (Version1, Version1Pos+1, length (Version1));
    Version2 := copy (Version2, Version2Pos+1, length (Version2));
    if (Version1Pos = 0) and (Version1Pos = 0) then
    begin
      break;
    end;
  end;
end;


function CompareVersionTo (ToVersion : string) : integer;
var
  ExeVersion : String;
begin
  ExeVersion := ReadVersionInfo (Application.ExeName).FileVersion;
  result     := CompareVersions (ExeVersion, ToVersion);
end;


end.
