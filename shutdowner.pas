unit shutdowner;
{ module works either under Windows or Linux and is passed control on running.
  it has to return control when shutdown was requested. it will have a thread
  for it's duties, but the thread may not heavily tax the CPU }
interface

uses
  Classes, SysUtils{$IFDEF Windows}, Windows{$ENDIF};

procedure control;

implementation
var
  do_Terminate: Boolean;

function exit_handler(_para: DWORD): WINBOOL; stdcall;
begin
     do_Terminate := True;
     result := True;
end;

procedure control;
{$IFDEF Windows}
begin
     do_Terminate := False;
     Windows.SetConsoleCtrlHandler(exit_handler, True);
     while not do_Terminate do Windows.Sleep(5000);
end;
{$ENDIF}

end.

