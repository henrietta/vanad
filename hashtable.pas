unit hashtable;

{$mode delphi}

interface

uses
  Classes, SysUtils, contnrs;

const
  HASHLEN = 16;
  HASHTABSIZE = 2 shl HASHLEN;

type
  Softlock = Cardinal;

  THashtableElement = record
    Key: String;
    Value: String;
    Next: PHashtableElement;
  end;
  PHashtableElement = ^THashtableElement;

  THashtableDescriptor = object
    M1, M2, M3, W, R: Softlock;
    ReadCount, WriteCount: Cardinal;    // counts of R/W
    PFElem: PHashtableElement;

    procedure LockForWrite();
    procedure UnlockForWrite();
    procedure LockForRead();
    procedure UnlockForRead();

    procedure Initialize;
  end;

  THashtable = class
  private
    Hashtable: array[0..HASHTABSIZE-1] of THashtableDescriptor;
  public
    procedure Assign(Key, Value: AnsiString);
    function Read(Key: AnsiString): AnsiString;

    constructor Create();
    destructor Destroy();
  end;

implementation
// ----------------------------------------------------------- THashtable
constructor THashtable.Create();
var
  i: Cardinal;
begin
  for i := 0 to HASHTABSIZE-1 do self.Hashtable[i].Initialize();
end;

// ----------------------------------------------------------- helper functions
procedure P(var s: Softlock);      // wait()
var
  a: Semaphore;
begin
  a := System.InterLockedExchange(s, 1);
  while a = 1 do
  begin
   ThreadSwitch();
   a := System.InterLockedExchange(s, 1);
  end;
end;

procedure V(var s: Softlock);      // signal()
begin
     s := 0;
end;

// -------------------------------------------------------- THashtableDescriptor
procedure THashtableDescriptor.LockForWrite();
begin
     P(self.M2);
     Inc(self.WriteCount);
     if self.WriteCount = 1 then P(self.R);
     V(self.M2);

     P(self.W);
end;
procedure THashtableDescriptor.UnlockForWrite();
begin
     V(self.W);

     P(self.M2);
     Dec(self.WriteCount);
     if self.WriteCount = 0 then V(self.R);
     V(self.M2);
end;

procedure THashtableDescriptor.LockForRead();
begin
     P(self.M3);
     P(self.R);
     P(self.M1);
     Inc(self.ReadCount);
     if self.ReadCount = 1 then P(self.W);
     V(self.M1);
     V(self.R);
     V(self.M3);
end;

procedure THashtableDescriptor.UnlockForRead();
begin
  P(self.M1);
  Dec(self.ReadCount);
  if self.ReadCount = 0 then V(self.W);
  V(self.M1);
end;

procedure THashtableDescriptor.Initialize();
begin
  self.M1 := 0;
  self.M2 := 0;
  self.M3 := 0;
  self.W := 0;
  self.R := 0;
  self.ReadCount := 0;
  self.WriteCount := 0;
  self.PFElem := nil;
end;

end.

