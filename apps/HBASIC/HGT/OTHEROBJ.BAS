' Additional object routines for the HiSoft GEM toolbox
' (C) Copyright HiSoft 1991

' Returns the object number of this object's parent or -1 if it is the root
FUNCTION GetParent(VAL index)
STATIC nextindex
	IF Index=0 THEN
		GetParent=-1
	ELSE
		DO
			nextindex=Getob_next(index)
			IF Getob_tail(nextindex)=index THEN EXIT LOOP
			index=nextindex
		LOOP
		GetParent=nextindex
	END IF
END FUNCTION
DIM SHARED current,ithchild,stop_now

'ForEachChild calls the given parameterless sub-program
'(use VARPTRS to find its address) for each child
' of object no parent. The sub-program can read the following
' globally shared variables:
' current - the object number of the current object
' ithchild - 0 for the first child, 1 for the second etc
' stop_now - setting this to a non-zero value will stop any
'          other children being considered
SUB ForEachChild(VAL parent,VAL procadr)
STATIC last
current=Getob_head(parent)
IF current=-1 THEN EXIT SUB ' no children at all
ithchild=0
stop_now=0
last=Getob_tail(parent)
DO
	CALLS procadr
	IF stop_now THEN EXIT LOOP
	INCR ithchild
	IF current=last THEN EXIT LOOP
	current=Getob_next(current)
LOOP	
END SUB

' Does nothing!
SUB HowManyProc
END SUB

' Returns the number of children that the given object has
FUNCTION HowManyChildren(VAL item)
	ForEachChild item,VARPTRS(HowManyProc)
	HowManyChildren=ithchild
END FUNCTION

SUB WhichChildProc
SHARED target
	IF current=target THEN stop_now=-1
END SUB

' Returns which child of its parent tree,item is or
'		0 if no parent
FUNCTION WhichChild(VAL item)
SHARED target
STATIC parent
	target=item
	parent=GetParent(item)
	IF parent=-1 THEN
		WhichChild=0
	ELSE
		ForEachChild parent,VARPTRS(WhichChildProc)
		WhichChild=ithchild
	END IF
END FUNCTION

' returns TRUE if PossChild is a child (or the same as) Parent
'	in tree ObjTree.
FUNCTION IsChild(VAL parent, VAL PossChild)
STATIC current
	current=PossChild
	DO
		IF current=parent THEN
			IsChild=-1
			EXIT LOOP
		END IF
		current=GetParent(current)
		IF current<0 THEN
			IsChild=0
			EXIT FUNCTION
		END IF
	LOOP
END FUNCTION
SUB ObjectNumberProc
SHARED target
	IF ithchild=target THEN stop_now=-1
END SUB
' returns the object number in the tree of the ith child
'	or tree,par
FUNCTION ObjectNumber(VAL par,i)
SHARED target
	target=i
	ForEachChild par,VARPTRS(ObjectNumberProc)
	ObjectNumber=current
END FUNCTION
