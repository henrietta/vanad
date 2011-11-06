program vanad;
{
        Basic idea:
                   - SELECTs are to be fast
                   - UPDATEs are to be fast
                   - INSERTs don't have to be fast
                   - DELETEs are done once in a year
}

uses
  Classes, AVLTree, exavltree, SysUtils;

{$R *.res}

var
  Tree: TExAVLTree;
  n: TAVLNode;

type
    XThread = class(TThread)
      procedure Execute; override;
      constructor Create();
    end;

constructor XThread.Create();
begin
     FreeOnTerminate := True;
     inherited Create(false);
end;

function rs: ansistring;
var
  i: integer;
begin
     result := '';
     for i := 1 to 1 do
       result := result + chr(random(89)+33);
end;

procedure XThread.Execute;
var
   i: integer;
begin
     for i := 0 to 100000000 do Tree.Assign(rs(), '1');
end;


var
  i: Integer;
  r: ansistring;
begin
     Tree := TExAVLTree.Create();

     for i := 0 to 3 do
     begin
          XThread.Create();
     end;

     readln;


     Tree.Destroy;
end.

