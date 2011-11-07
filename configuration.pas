unit Configuration;

{$mode delphi}

interface

uses
  IniFiles, SysUtils;

procedure Initialize;
procedure Finalize;
function GetS(Section, Key: AnsiString): AnsiString;
function GetI(Section, Key: AnsiString): Integer;

implementation
var
  IniFile: TIniFile;
procedure Initialize;
begin
     IniFile := TIniFile.Create('config.ini');
end;
procedure Finalize;
begin
     IniFile.Destroy();
end;
function GetS(Section, Key: AnsiString): AnsiString;
begin
     result := IniFile.ReadString(Section, Key,'');
end;
function GetI(Section, Key: AnsiString): Integer;
begin
     result := StrToInt(IniFile.ReadString(Section, Key,''));
end;

end.

