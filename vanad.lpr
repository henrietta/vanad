program vanad;
{
        Basic idea:
                   - SELECTs are to be fast
                   - UPDATEs are to be fast
                   - INSERTs don't have to be fast
                   - DELETEs are done once in a year
}

uses
  Classes, AVLTree;

{$R *.res}

var
  Tree: TAVLTree;
  n: TAVLNode;
function rs: ansistring;
var
  i: integer;
begin
     result := '';
     for i := 1 to 10 do
       result := result + chr(random(89)+33);
end;

var
  i: Integer;
  r: ansistring;
begin
     Tree := TAVLTree.Create();

     while true do
     begin
       Readln(r);
       Tree.Insert(r, '1', Tree.FindClosest(r));
       Visualise(0, Tree.Root);
     end;

     Tree.Destroy;
end.

