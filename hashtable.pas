unit hashtable;

{$mode delphi}

interface

uses
  Classes, SysUtils, contnrs;

const
  DEFAULT_HASHTABLE_SIZE = 1024;

type
  Softlock = Cardinal;

  THashtableElement = class
    Key: AnsiString;
    Value: AnsiString;
    Next: THashtableElement;

    constructor Create(Key, Value: AnsiString);
    destructor Destroy();
  end;

  THashtableDescriptor = object
    X: Softlock;
    FElem: THashtableElement;

    procedure Lock();
    procedure Unlock();

    // following update procedures expect the lock to be acquired
    procedure Assign(Key, Value: AnsiString);
    function Read(const Key: AnsiString): AnsiString;
    procedure Delete(const Key: AnsiString);

    procedure Initialize();
    procedure Finalize();
  end;

  THashtable = class
  public
    DescriptorsCount: Cardinal;
    Hashtable: array of THashtableDescriptor;

    function Hash(const X: AnsiString): Cardinal;

    procedure Assign(Key, Value: AnsiString);
    function Read(Key: AnsiString): AnsiString;
    procedure Delete(const Key: AnsiString);

    constructor Create(); overload;
    constructor Create(Descriptors: Cardinal); overload;
    destructor Destroy();
  end;

procedure EnsureTablespaceExists(i: Integer);
function DoesTablespaceExist(i: Integer): Boolean;

procedure Initialize;

implementation
uses
  CommonData;

procedure Initialize;
var
  i: Cardinal;
begin
  // they are created on demand but they need to be set to null, so that functions
  // recognize when should they be created
  for i := 0 to 255 do
      tablespace[i] := nil;
end;
// ----------------------------------------------------------- hashing function
function THashtable.Hash(const X: AnsiString): Cardinal;     // FNV hash
var
  i: Integer;
begin
  result := 2166136261;
  for i := 1 to Length(X) do result := (result * 16777619) xor ord(X[i]);
  result := result mod self.DescriptorsCount;
end;

// ----------------------------------------------------------- THashtableElement
destructor THashtableElement.Destroy;
begin
  self.Key := '';
  self.Value := '';
end;
constructor THashtableElement.Create(Key, Value: AnsiString);
begin
     self.Key := Key;
     self.Value := Value;
     self.Next := nil;
end;
// ----------------------------------------------------------- THashtable
procedure THashtable.Assign(Key, Value: AnsiString);
begin
  with self.Hashtable[self.Hash(Key)] do
  begin
     Lock();
     Assign(Key, Value);
     Unlock();
  end;
end;
function THashtable.Read(Key: AnsiString): AnsiString;
begin
  with self.Hashtable[self.Hash(Key)] do
  begin
     Lock();
     result := Read(Key);
     Unlock();
  end;
end;
procedure THashtable.Delete(const Key: AnsiString);
begin
  with self.Hashtable[self.Hash(Key)] do
  begin
     Lock();
     Delete(Key);
     Unlock();
  end;
end;
constructor THashtable.Create(); overload;
var
  i: Cardinal;
begin
  self.DescriptorsCount := DEFAULT_HASHTABLE_SIZE;
  self.Hashtable := nil;
  SetLength(self.Hashtable, self.DescriptorsCount);
  for i := 0 to self.DescriptorsCount-1 do self.Hashtable[i].Initialize();
end;
constructor THashtable.Create(Descriptors: Cardinal); overload;
var
  i: Cardinal;
begin
  self.DescriptorsCount := Descriptors;
  self.Hashtable := nil;
  SetLength(self.Hashtable, self.DescriptorsCount);
  for i := 0 to self.DescriptorsCount-1 do self.Hashtable[i].Initialize();
end;
destructor THashtable.Destroy();
var
  i: Cardinal;
begin
  for i := 0 to self.DescriptorsCount-1 do self.Hashtable[i].Finalize();
  SetLength(self.Hashtable, 0);
end;
// ----------------------------------------------------------- helper functions
function DoesTablespaceExist(i: Integer): Boolean;
begin
  result := tablespace[i] <> nil;
end;
procedure EnsureTablespaceExists(i: Integer);
begin
  if tablespace[i] = nil then
     tablespace[i] := THashtable.Create();
end;
procedure Wait(var s: Softlock);      // wait()
var
  a: Softlock;
begin
  a := System.InterLockedExchange(s, 1);
  while a = 1 do
  begin
   ThreadSwitch();
   a := System.InterLockedExchange(s, 1);
  end;
end;

procedure Signal(var s: Softlock);      // signal()
begin
   System.InterLockedDecrement(s);
end;

// -------------------------------------------------------- THashtableDescriptor
procedure THashtableDescriptor.Lock();
begin
     Wait(self.X);
end;
procedure THashtableDescriptor.Unlock();
begin
     Signal(self.X);
end;
procedure THashtableDescriptor.Finalize();
var
  CurrentElement, ProcessedElement: THashtableElement;
begin
  CurrentElement := self.FElem;
  while CurrentElement <> nil do
  begin
    ProcessedElement := CurrentElement;
    CurrentElement := CurrentElement.Next;
    ProcessedElement.Destroy();
  end;
end;

procedure THashtableDescriptor.Initialize();
begin
  self.X := 0;
  self.FElem := nil;
end;

procedure THashtableDescriptor.Delete(const Key: AnsiString);
var
  PrevElement: THashtableElement = nil;
  CurrentElement: THashtableElement;
begin
  CurrentElement := self.FElem;

  while CurrentElement <> nil do
  begin
       if CurrentElement.Key = Key then break;
       PrevElement := CurrentElement;
       CurrentElement := CurrentElement.Next;
  end;

  // if CE=nil then item not found or list is empty (PE=nil also happens then)
  if CurrentElement = nil then Exit;

  // if PE=nil then item that we delete is the first one
  if PrevElement = nil then
  begin
     // and CE is the item that we want to delete
     self.FElem := CurrentElement.Next;
     CurrentElement.Destroy;
     Exit;
  end;

  // if CE.Next=nil then item that we want to delete is the last one
  // AND the list has at least 2 elements (see previous condition)
  if CurrentElement.Next=nil then
  begin
     // and PE is the item before it
     PrevElement.Next := nil;
     CurrentElement.Destroy;
     Exit;
  end;

  // in this case, deleted item is in the middle of the list;
  PrevElement.Next := CurrentElement.Next;
  CurrentElement.Destroy;
end;

function THashtableDescriptor.Read(const Key: AnsiString): AnsiString;
var
  CurrentElement: THashtableElement;
begin
  CurrentElement := self.FElem;

  // iterate over each element
  while CurrentElement <> nil do
  begin
       // if we have a match, send it over
       if CurrentElement.Key = Key then Exit(CurrentElement.Value);
       CurrentElement := CurrentElement.Next;
  end;

  // if we are here, then value was not found. Return a null
  Exit('');
end;

procedure THashtableDescriptor.Assign(Key, Value: AnsiString);
var
  CurrentElement: THashtableElement;
begin
  if self.FElem = nil then         // adding first element ever
  begin
    self.FElem := THashtableElement.Create(Key, Value);
    Exit;
  end;

  // grab the current first element
  CurrentElement := self.FElem;

  // now we have to iterate over each element
  while True do
  begin
     // is this element is the one we are looking for, update this and return
     if CurrentElement.Key = Key then
     begin
        CurrentElement.Value := Value;
        Exit;
     end;

     // in that case, is this the last element of the chain? Break if that's it
     if CurrentElement.Next = nil then break;

     // iterate to next one
     CurrentElement := CurrentElement.Next;
  end;

  // if we are here, that means that CurrentElement iterated up to nil. We
  // will be inserting a new one after CurrentElement - the last element in list
  CurrentElement.Next := THashtableElement.Create(Key, Value);
end;

end.

