unit shutdowner;
{ module works either under Windows or Linux and is passed control on running.
  it has to return control when shutdown was requested. it will have a thread
  for it's duties, but the thread may not heavily tax the CPU }
{$mode delphi}
interface

uses
  Classes, SysUtils, {$IFDEF Windows}Windows{$ENDIF}{$IFDEF Unix}BaseUnix, Crt{$ENDIF};

procedure control;

implementation
var
  do_Terminate: Boolean;

{$IFDEF Windows}
function exit_handler(_para: DWORD): WINBOOL; stdcall;
begin
     do_Terminate := True;
     result := True;
end;

procedure control;
begin
     do_Terminate := False;
     Windows.SetConsoleCtrlHandler(exit_handler, True);
     while not do_Terminate do Windows.Sleep(5000);
end;
{$ENDIF}


{$IFDEF Unix}
procedure exit_handler(sig: Longint); cdecl;
begin
     do_Terminate := True;
end;

procedure control;
begin
     do_Terminate := False;
     fpsignal(SIGINT, signalhandler(@exit_handler));
     fpsignal(SIGTERM, signalhandler(@exit_handler));
     while not do_Terminate do delay(5000);
end;
{$ENDIF}

end.

