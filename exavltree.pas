unit exavltree;

{$mode delphi}

interface

uses
  AVLTree, SysUtils;

type
  TExAVLTree = class(TAVLTree)
  private
    Lock: TMultiReadExclusiveWriteSynchronizer;
  public
    procedure Assign(Key, Value: ansistring);
    function Read(Key: ansistring): ansistring;

    constructor Create();
  end;

implementation

procedure TExAVLTree.Assign(Key, Value: ansistring);
label
  Inserting;
var
  node: TAVLNode;
begin
  self.Lock.BeginRead();
  node := self.FindClosest(Key);

  if node = nil then
    goto Inserting;

  if node.Key = Key then
  begin
    node.Value := Value;
    self.Lock.EndRead();
    Exit;
  end;

Inserting:
  self.Lock.EndRead();
  self.Lock.BeginWrite();


  node := self.FindClosest(Key); // we need to lookup it again - situation could have changed!
  if (node = nil) then
    self.Insert(Key, Value, node)
  else if node.Key = Key then
     node.Value := Value
  else
    self.Insert(Key, Value, node);

  self.Lock.EndWrite();
end;

function TExAVLTree.Read(Key: ansistring): ansistring;
var
  node: TAVLNode;
begin
  self.Lock.BeginRead();

  node := self.FindClosest(Key);

  Result := '';

  if node <> nil then
    if node.Key = Key then
      Result := node.Value;

  self.Lock.EndRead();
end;

constructor TExAVLTree.Create();
begin
  self.Lock := TMultiReadExclusiveWriteSynchronizer.Create();
  inherited Create();
end;

end.

