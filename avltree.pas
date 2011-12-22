unit AVLTree;
{
     Vanad-specific AVL tree implementation.

     Posesses basic routines to build on.
}
{$mode delphi}
interface

uses
  Classes, SysUtils;

type
    TAVLNode = class
        private
            Parent: TAVLNode;
            Left, Right: TAVLNode;
            Balance: ShortInt;
        public
            Key, Value: AnsiString;

            function InsertLeft(n: TAVLNode): TAVLNode;
            function InsertRight(n: TAVLNode): TAVLNode;
            // inserts n as new subnode, returning previous one

            { TAVLNode can handle rotations which will not result in
             reparenting self }
            procedure RotateLR();
 {  We don't care about nodes illustrated with numbers - they can be even nil
                      self                       self
                     /    \                      /  \
                    A      4                    B    4
                   / \               =>        / \
                  1   B                       A   3
                     / \                     / \
                    2   3                   1   2           }
            procedure RotateRL();
               {      self                       self
                     /    \                      /  \
                    1      A                    1    B
                          / \        =>             / \
                         B   4                     2   A
                        / \                           / \
                       2   3                         3   4  }

            constructor Create(Key, Value: AnsiString); overload;
            destructor Destroy();
        end;

    TAVLTree = class
        public
            Root: TAVLNode;
            constructor Create();
            destructor Destroy();

            procedure Insert(Key, Value: AnsiString; closestNode: TAVLNode);
            { this isn't called Insert for nothing. Will raise Exception if
              closestNode.Key = Key }
            function FindClosest(Key: AnsiString): TAVLNode;
            { returns nil if tree has no root
              if there is not node with matching Key, it will return node that
              would be it's parent if Insert was to happen }

            function RotateLL(node: TAVLNode): TAVLNode;
{          parent                 parent
             |                      |
            node                    B
            /  \                   / \          returns B
           B    4                 A  node
          / \            =>      / \   / \
         A   3                  1  2  3   4
        / \
       1   2                              }
           function RotateRR(node: TAVLNode): TAVLNode;
{          parent                 parent
             |                      |
            node                    B
           /   \                   / \
           1    B         =>    node  A        returns B
               / \             / \   / \
              2   A           1   2  3  4
                 / \
                3   4                                   }
    end;

    TAVLTreeIterator = class
    public
            Tree: TAVLTree;
            Node: TAVLNode;
            Done: Boolean;
            constructor Create(tree: TAVLTree);
            procedure Next();
    end;


implementation
function ReparentIA(n, parent: TAVLNode): TAVLNode;
{   if n is not nil, sets n.Parent = parent.       Returns n }
begin
    result := n;
    if result <> nil then result.Parent := parent;
end;
function Reparent(n, parent: TAVLNode): TAVLNode;
{   sets n.Parent = parent.       Returns n }
begin
    result := n;
    result.Parent := parent;
end;
// =========================================================    TAVLTreeIterator
constructor TAVLTreeIterator.Create(tree: TAVLTree);
begin
     self.Tree := tree;
     self.Node := self.Tree.Root;
     self.Done := (self.Node = nil);
end;

procedure TAVLTreeIterator.Next();
{
 Algorithm sets self.Node as next node on which an op should be performed. It should be
 executed until NIL returns

 Input: Current node [N]
 Output: Next node or NIL

 Precondition: First node is the root

 1. If N has no kids, jump to 3
 2. If N has left-side child, return left-side child, else return right-side kid.
 3. If N is the root, return NIL
 4. If N isn't a left-side kid of it's parent, jump to 6
 5. If parent of N has right-side kid, return it
 6. N := parent of N
 7. Jump to 3
}
begin
     // Points 1-2
     if (self.Node.Left <> nil) and (self.Node.Right <> nil) then
     begin
          if self.Node.Left <> nil then
             self.Node := self.Node.Left
          else
              self.Node := self.Node.Right;

          Exit;
     end;

     while True do
     begin
         if self.Node = self.Tree.Root then             // point 3
         begin
              self.Done := True;
              self.Node := nil;
              Exit;
         end;

         if self.Node = self.Node.Parent.Left then      // point 4
             if self.Node.Parent.Right <> nil then      // point 5
             begin
                self.Node := self.Node.Parent.Right;
                Exit;
             end;

         self.Node := self.Node.Parent;     // point 6

         // And point 7 :)
     end;

end;

// =================================================================    TAVLTree
procedure TAVLTree.Insert(Key, Value: AnsiString; closestNode: TAVLNode);
var
  node: TAVLNode;
  child: TAVLNode;  // this is child of 'node' that had a new child
  new_node: TAVLNode;
begin
    new_node := TAVLNode.Create(Key, Value);

    node := closestNode;    { find node that would be the parent }
    if node = nil then          { we are rootless }
    begin
       self.Root := new_node;
       Exit;
    end;
    if node.Key = Key then
       raise Exception.Create('Hey, how come we are here?');

    if Key < node.Key then     // left-insert
    begin
       node.InsertLeft(new_node);
       node.Balance -= 1;
    end else                   // right-insert
    begin
       node.InsertRight(new_node);
       node.Balance += 1;
    end;

    if node.Balance = 0 then Exit; // tree height did not change, as we
                                   // have just balanced the node. Exit.

    while node.Parent <> nil do // we cannot have a situation where we try to
    begin                       // obtain parent of root
       child := node;
       node := node.Parent;

       if node.Left = child then  // if we are here then our subtree has grown
          node.Balance -= 1 // determine which one
       else
          node.Balance += 1;

       if node.Balance = 0 then Exit; // tree height did not change
                                      // we can finish

       if node.Balance in [-1, 1] then continue;
          // tree has grown in one of sides. We need to inform our parent
          // about that

       if node.Balance = -2 then          // imbalanced left
       begin
          if node.Left.Balance = 1 then   // imbalanced left - skewed right
          begin
             node.RotateLR();
             node.Left.Balance := -1;
          end;
          if node.Left.Balance = -1 then
          begin                        // imbalanced left - skewed left
             node := self.RotateLL(node);
             node.Balance := 0;
             node.Right.Balance := 0;
          end;

          Exit;
       end else
       if node.Balance = 2 then           // imbalanced right
       begin
          if node.Right.Balance = -1 then    // imbalanced right - skewed left
          begin
             node.RotateRL();
             node.Right.Balance := 1;
          end;
          if node.Right.Balance = 1 then     // imbalanced right - skewed right
          begin
             node := self.RotateRR(node);
             node.Balance := 0;
             node.Left.Balance := 0;
          end;

          Exit;
       end;
    end;
end;
function TAVLTree.FindClosest(Key: AnsiString): TAVLNode;
begin
    result := self.Root;
    if result = nil then Exit;   { no root found }

    while true do
    begin
      if Key = result.Key then Exit;  { exact node found }
      if Key < result.Key then
         if result.Left = nil then Exit { should branch left, but can't }
         else result := result.Left
      else
         if result.Right = nil then Exit { should branch right, but can't }
         else result := result.Right;
    end;
end;

// ----------------------------------------------------- rotation routines
function TAVLTree.RotateRR(node: TAVLNode): TAVLNode;
{          parent                 parent
             |                      |
            node                    B
           /   \                   / \
           1    B         =>    node  A        returns B
               / \             / \   / \
              2   A           1   2  3  4
                 / \
                3   4                                   }
var
  parent: TAVLNode;
  A, B, _1, _2: TAVLNode;
begin
   parent := node.Parent;      // we will reparent stuff later, because
                               // B may end up a new tree root

   _1 := node.Left;          B := node.Right;
//                          ///            \\\
                         _2 := B.Left;       A := B.Right;

                 { we're leaving 3 and 4 alone, as they will not change parent }

   B.Left := Reparent(node, B);           B.Right := Reparent(A, B);
   node.Left := ReparentIA(_1, node);     node.Right := ReparentIA(_2, node);

    if parent = nil then        // node was previously root
    begin
       self.Root := B;
       self.Root.Parent := nil;
    end
    else
    begin
        Reparent(B, parent);
        // parent needs to be posted that a child has changed
        if parent.Left = node then
           parent.Left := B
        else
           parent.Right := B;
    end;

    result := B;
end;

function TAVLTree.RotateLL(node: TAVLNode): TAVLNode;
{          parent                 parent
              |                      |
             node                    B
             /  \                   / \          returns B
             B    4                 A  node
            / \            =>      / \   / \
           A   3                  1  2  3   4
          / \
         1   2                              }
var
  parent: TAVLNode;
  A, B, _3, _4: TAVLNode;
begin
   parent := node.Parent;      // we will reparent stuff later, because
                               // B may end up a new tree root

           B := node.Left;                _4 := node.Right;
//         ///           \\
         A := B.Left;      _3 := B.Right;

   { we're leaving 1 and 2 alone, as they will not change parent }

    B.Left := Reparent(A, B);            B.Right := Reparent(node, B);
    node.Left := ReparentIA(_3, node);   node.Right := ReparentIA(_4, node);

    if parent = nil then        // node was previously root
    begin
       self.Root := B;
       self.Root.parent := nil;
    end
    else
    begin
        Reparent(B, parent);
        // parent needs to be posted that a child has changed
        if parent.Left = node then
           parent.Left := B
        else
           parent.Right := B;
    end;

    result := B;
end;

// ----------------------------------------------------- bookkeeping
constructor TAVLTree.Create();
begin
     self.Root := nil;
end;
destructor TAVLTree.Destroy();
begin
     if self.Root <> nil then self.Root.Destroy();
end;
// =================================================================    TAVLNode
function TAVLNode.InsertLeft(n: TAVLNode): TAVLNode;
begin
    result := self.Left;
    self.Left := n;
    n.Parent := self;
end;
function TAVLNode.InsertRight(n: TAVLNode): TAVLNode;
begin
    result := self.Right;
    self.Right := n;
    n.Parent := self;
end;
// ----------------------------------------------------- bookkeeping
procedure TAVLNode.RotateLR();
{      self                       self
      /    \                      /  \
     A      4                    B    4
    / \               =>        / \
   1   B                       A   3
      / \                     / \
     2   3                   1   2           }
var
  A, B, _1, _2, _3: TAVLNode;
  // we're leaving 4 alone, it will not change places
begin
                   A := self.Left;
//              ///            \\\
        _1 := A.Left;            B := A.Right;
//                              ////       \\\
                          _2 := B.Left;    _3 := B.Right;

    self.Left := Reparent(B, self);

    B.Left := Reparent(A, B);                 B.Right := ReparentIA(_3, B);
    A.Left := ReparentIA(_1, A);              A.Right := ReparentIA(_2, A);
end;
procedure TAVLNode.RotateRL();
{      self                       self
      /    \                      /  \
     1      A                    1    B
           / \        =>             / \
          B   4                     2   A
         / \                           / \
        2   3                         3   4  }
var
  A, B, _2, _3, _4: TAVLNode;
  // we're leaving 1 alone, it will not change places
begin
                      A := self.Right;
   //              ///            \\\
             B := A.Left;      _4 := A.Right;
   //       ///      \\\
   _2 := B.Left;    _3 := B.Right;


   self.Right := Reparent(B, self);
   B.Left := ReparentIA(_2, B);         B.Right := Reparent(A, B);
   A.Left := ReparentIA(_3, A);         A.Right := ReparentIA(_4, A);
end;
constructor TAVLNode.Create(Key, Value: AnsiString);
begin
     self.Key := Key;
     self.Value := Value;
     self.Balance := 0;
     self.Left := nil; self.Right := nil;
     self.Parent := nil;
end;
destructor TAVLNode.Destroy();
begin
    // TODO: Shouldn't be recursive
    if self.Left <> nil then self.Left.Destroy();
    if self.Right <> nil then self.Right.Destroy();

    inherited Destroy();
end;
end.

