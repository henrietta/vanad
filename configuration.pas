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
     if System.argc = 1 then
     begin
          // no arguments passed - assume the defaults
          if not FileExists('config.ini') then Halt(1);   // no config.ini found!
          IniFile := TIniFile.Create('config.ini');
     end else
     begin
          // first parameter is the name of the config file
       if not FileExists(System.argv[1]) then Halt(1);   // no config.ini found!
       IniFile := TIniFile.Create(System.argv[1]);
     end;
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

