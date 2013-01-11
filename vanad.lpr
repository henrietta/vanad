program vanad;

{$mode delphi}

uses
{$IFDEF Unix}
cthreads,
{$ENDIF}
Classes, hashtable, SysUtils, Configuration, Sockets, VSocket,
workerthread, CommonData, shutdowner;


procedure ReadTable(tabid: Integer);
var
  d: Longword;      // block-builders
  b: Byte;
  f: File;          // read file
  Temp: Integer;    // placeholder for temporary return codes
  k, v: ansiString; // key-value holders
begin
  EnsureTablespaceExists(tabid);
  AssignFile(f, Configuration.GetS('FS', 'TableHierarchy')+'/'+IntToStr(tabid));
  Reset(f, 1);
  while not Eof(f) do
  begin
      BlockRead(f, b, 1, Temp);                      d := b shr 24;
      BlockRead(f, b, 1, Temp);                      d := d + (b shr 16);
      BlockRead(f, b, 1, Temp);                      d := d + (b shr 8);
      BlockRead(f, b, 1, Temp);                      d := d + b;

      SetLength(k, d);
      BlockRead(f, k[1], d, Temp);

      BlockRead(f, b, 1, Temp);                      d := b shr 24;
      BlockRead(f, b, 1, Temp);                      d := d + (b shr 16);
      BlockRead(f, b, 1, Temp);                      d := d + (b shr 8);
      BlockRead(f, b, 1, Temp);                      d := d + b;

      SetLength(v, d);
      BlockRead(f, v[1], d, Temp);

      tablespace[tabid].Assign(k, v);
  end;
  Close(f);
end;

procedure WritebackTable(tabid: Integer);
var
  d: Longword;                  // block-builders
  b: Byte;
  f: File;                      // writeback file
  Temp: Integer;                // placeholder for return code
  elem: THashtableElement;      // currently parsed element
  i: Integer;                   // iterating over tablespaces
begin
  if not DoesTablespaceExist(tabid) then Exit;

  AssignFile(f, Configuration.GetS('FS', 'TableHierarchy')+'/'+IntToStr(tabid));
  Rewrite(f, 1);

  // iterate over each THashableDescriptor;
  for i := 0 to tablespace[tabid].DescriptorsCount-1 do
  begin
       // iterate over each THashtableElement
       elem := tablespace[tabid].Hashtable[i].FElem;
       while elem <> nil do
       begin
           // write to file
           d := Length(elem.Key);
           b := d shr 24;                   BlockWrite(f, b, 1, Temp);
           b := (d shr 16) and $FF;         BlockWrite(f, b, 1, Temp);
           b := (d shr 8) and $FF;          BlockWrite(f, b, 1, Temp);
           b := d and $FF;                  BlockWrite(f, b, 1, Temp);

           BlockWrite(f, elem.Key[1], d, Temp);      // Magic :)

           d := Length(elem.Value);
           b := d shr 24;                   BlockWrite(f, b, 1, Temp);
           b := (d shr 16) and $FF;         BlockWrite(f, b, 1, Temp);
           b := (d shr 8) and $FF;          BlockWrite(f, b, 1, Temp);
           b := d and $FF;                  BlockWrite(f, b, 1, Temp);

           BlockWrite(f, elem.Value[1], d, Temp);

           // next one please
           elem := elem.Next;
       end;
  end;

  Close(f);
end;

var
  i, j: Cardinal;
  WorkerThreads: array of TWorkerThread;
begin
     Configuration.Initialize;
     Hashtable.Initialize;

     SocketOpTimeout := Configuration.GetI('Operation', 'SocketOperationTimeout');
     for i := 0 to 255 do
         if FileExists(Configuration.GetS('FS', 'TableHierarchy')+'/'+IntToStr(i)) then
            ReadTable(i);

     VSocket.Initialize;

     j := Configuration.GetI('Operation', 'WorkerThreads');
     SetLength(WorkerThreads, j);
     for i := 0 to j-1 do
         WorkerThreads[i] := TWorkerThread.Create(i);

     for i := 0 to j-1 do WorkerThreads[i].Start();

     shutdowner.control;

     for i := 0 to j-1 do
         WorkerThreads[i].Terminate();

     for i := 0 to j-1 do
     begin
          WorkerThreads[i].WaitFor();
          WorkerThreads[i].Destroy();
     end;

     VSocket.Finalize;
     for i := 0 to 255 do WritebackTable(i);
     Configuration.Finalize();

     // for sake of memfreeing fashionistas
     for i := 0 to 255 do
         if DoesTablespaceExist(i) then
            tablespace[i].Destroy;

end.

