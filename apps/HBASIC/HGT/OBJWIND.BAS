' The Object window routines
' requires object.bas
SUB InitObjectWindows
SHARED woObjectTree&(1),woBaseX(1),woBaseY(1),ObjectWindowsInitialised,max_windows
' Object specific
REDIM	woObjectTree&(max_windows)	' pointer to object tree to be displayed
								' or 0 if 'normal'
REDIM woBaseX(max_windows),woBasey(max_windows)
ObjectWindowsInitialised=-1
END SUB

SUB ObjectReDraw
SHARED commonx,commony,commonw,commonh,commonhandle
STATIC i,x,y,w,h,ActualX,ActualY
SHARED woObjectTree&(1),woOffX(1),woOffY(1),woBaseX(1),woBaseY(1),tree&

STATIC	oldtree&
	oldtree&=tree&
	i=WhichWindow(commonHandle)
	IF i=0 THEN EXIT SUB ' panic
	SelectTreeAddr woObjectTree&(i)
	junk=wind_get(CommonHandle,WF_WORKXYWH,x,y,w,h)

	Setob_x 0,woBaseX(i)-woOffX(i)+x
	Setob_y 0,woBasey(i)-woOffY(i)+y
	junk=objc_draw(tree&,0,7,commonx,commony,commonw,commonh)
	SelectTreeAddr oldtree&
END SUB

SUB ObjectSliderMax
SHARED commoni,commonmaxx,commonmaxy
SHARED woObjectTree&(1),woBaseX(1),woBaseY(1)
STATIC x,y,oldtree&,new
IF woObjectTree&(commoni)<>0 THEN
	oldtree&=tree&
	SelectTreeAddr woObjectTree&(commoni)
	commonmaxx=woBaseX(commoni)+Getob_width(0)
	commonmaxy=woBaseY(commoni)+Getob_height(0)
	SelectTreeAddr oldtree&
END IF
END SUB

SUB ObjectClose
END SUB

' 	As OpenAWindow except the Object Tree whose Address is given by
'	p  is always - rather than a specific redraw routine. This will
'	handle scroll events
FUNCTION OpenObjectWindowAddr(WindowName$,WindComp,treeaddr&)
STATIC WindowHandle,oldtree&
SHARED woObjectTree&(1),woBaseX(1),woBaseY(1)
SHARED woType(1),HowManyWindows,ObjectWindowsInitialised
	WindowHandle=OpenAWindow(WindowName$,WindComp,VARPTRS(ObjectReDraw),VARPTRS(ObjectSliderMax),VARPTRS(ObjectClose))
	IF ObjectWindowsInitialised=0 THEN  CALL InitObjectWindows
	IF WindowHandle >= 0 THEN
			woObjectTree&(HowManyWindows)=treeaddr&
			oldtree&=tree&
			SelectTreeAddr treeaddr&
			woType(HowMAnyWindows)=woTobject
			woBaseX(HowManyWindows)=Getob_x(0)
			woBaseY(HowManyWindows)=Getob_y(0)
			SelectTreeAddr oldtree&
		END IF
	OpenObjectWindowAddr=WindowHandle
END FUNCTION

FUNCTION OpenObjectWindow(WindowName$,BYVAL WindComp,BYVAL treeno)
STATIC junk,formaddr&,temp
	junk=rsrc_gaddr(type_tree,treeno,formaddr&)
	temp=OpenObjectWindowAddr(windowName$,WindComp,formaddr&)
	OpenObjectWindow=temp
END FUNCTION
