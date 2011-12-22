unit shutdowner;
{ module works either under Windows or Linux and is passed control on running.
  it has to return control when shutdown was requested. it will have a thread
  for it's duties, but the thread may not heavily tax the CPU }
{$mode delphi}
interface

uses
  Classes, SysUtils, syncobjs, {$IFDEF Windows}Windows{$ENDIF}{$IFDEF Unix}BaseUnix{$ENDIF};

procedure control;

implementation
var
  termLock: Boolean;

{$IFDEF Windows}
function exit_handler(_para: DWORD): WINBOOL; stdcall;
begin
     termLock := False;
     result := True;
end;

procedure control;
begin
     Windows.SetConsoleCtrlHandler(exit_handler, True);
     while termLock do Windows.Sleep(5000);
end;
{$ENDIF}


{$IFDEF Unix}
procedure exit_handler(sig: Longint); cdecl;
begin
     termLock := False;
end;

procedure control;
begin
     fpsignal(SIGTERM, signalhandler(@exit_handler));
     while termLock do fpSelect(0,nil,nil,nil,5000);
end;
{$ENDIF}

initialization
begin
     termLock := True;
end;

end.

