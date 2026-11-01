' 31.3.92	djn maximums taken to include possible part characters at end of window

FUNCTION MyInterSection( BYVAL x1,BYVAL y1,BYVAL w1,BYVAL h1,_ ' First Source AES Rect
			BYVAL x2,BYVAL y2,BYVAL w2,BYVAL h2,_ ' Second Source AES Rect
			outx,outy,outw,outh)	' Intersection Rect
intersection x1,y1,w1,h1,x2,y2,w2,h2,outx,outy,outw,outh
IF outh>0 AND outw>0 THEN myintersection=-1 ELSE myintersection=0
END FUNCTION 

' The windows section of the Toolbox
'These are the arrays
'where the mapping between the window handles and ReDrawProcs are stored
'There are HowManyWindows valid entries in this table and there may
'	NOT be any 'holes' in the structure


CONST woTsimple=0, woTobject=1,woTtext=2,woTimage=3,woTform=4


' Open a window and clear it to white with the given name and
'   re-draw sub-program and returns the corresponding WindowHandle
'   - if there was an error the GEM return value is given
'   The name must be null-terminated and the Redraw sub-program has the
'   following parameters:
'	WindowHandle,x,y,w,h (all CARDINAL) of the window to draw
'	This should re-draw that part of that window. There is no need
'	to clear it to white first

FUNCTION OpenAWindow(WindowName$,BYVAL WindComp,BYVAL procaddr&,BYVAL slidermaxaddr&,BYVAL closeproc&)
STATIC WindowHandle
STATIC x1,y1,x2,y2,id
SHARED WindX,WindY,WindW,WindH,HowManyWindows,WindowsInitialised,max_windows
SHARED woHandle(1),woRedraw&(1),woSliderMax&(1),woClose&(1)
SHARED woType(1),woOffx(1),woOffy(1)
	IF	WindowsInitialised=0 THEN CALL InitWindowSystem
	IF HowManyWindows=max_windows THEN 
		CALL NoMoreWindows
		EXIT SUB
	END IF
'Find an unused BASIC window id
	id=0
	DO WHILE VARPTR(#257+id)
		INCR id
	LOOP
' OK we can use BASIC window id - we will get a runtime error if
' this doesn't work.
	graf_mouse 256,0
	WINDOW OPEN id,WindowName$,WindX,WindY,WindW,WindH,WindComp
	
	INCR HowManyWindows
	
	WINDOW READ id,5,WindowHandle	'read the AES handle
	woHandle(HowManyWindows)=WindowHandle
	woRedraw&(HowManywindows)=procaddr&
	woSliderMax&(HowManyWindows)=slidermaxaddr&
	woClose&(HowManyWindows)=closeproc&
	woType(HowManyWindows)=woTsimple
	woOffX(HowManyWindows)=0
	woOffy(HowManyWindows)=0
	vsf_color 0			'  fill with white
'  set the clipping rectangle and clear it
	junk=wind_get(WindowHandle,WF_WORKXYWH,x1,y1,x2,y2)
	x2=x1+x2-1
	y2=y1+y2-1
	vs_clip 1,x1,y1,x2,y2
	vr_recfl x1,y1,x2,y2
	graf_mouse 257,0
	OpenAWindow=WindowHandle
END FUNCTION

DECLARE FUNCTION UserClose(BYVAL WindowHandle)
DECLARE FUNCTION FormClose

' Close a window of the given handle
' Note a variable parameter - will be set to 0 on exit
SUB CloseAWindow(WindowHandle)
STATIC j,k,id
SHARED HowManyWindows
SHARED userclose_enabled,formWindowsInitialised
SHARED woHandle(1),woRedraw&(1),woSliderMax&(1),woClose&(1)
SHARED woType(1),woOffx(1),woOffy(1),commoni
	commoni=WhichWindow(WindowHandle)
'	Debug "Closing window"+STR$(WindowHandle)+"Number"+STR$(i)
	IF commoni>0 THEN
		IF FormWindowsInitialised THEN
			IF FormClose=0 THEN EXIT SUB
		END IF
		IF userclose_enabled THEN
			IF UserClose(WindowHandle)=0 THEN EXIT SUB
		END IF
		DECR HowManyWindows
		CALLS woClose&(commoni)
		FOR j=commoni TO HowManyWindows
			woHandle(j)=woHandle(j+1)
			woRedraw&(j)=woRedraw&(j+1)
			woSliderMax&(j)=woSlidermax&(j+1)
			woClose&(j)=woClose&(j+1)
			woType(j)=woType(j+1)
			woOffx(j)=woOffx(j+1)
			woOffy(j)=woOffy(j+1)
		NEXT j
		WINDOW READ windowhandle,6,id
		IF id>=0 THEN
			WINDOW CLOSE id
		END IF
	END IF
	WindowHandle=0
END SUB

' Redraw a slider 1 for Horizontal, 0 for Vertical
SUB OneSlider(BYVAL Horizontal, BYVAL TotalSize,BYVAL curpos,BYVAL Size)
STATIC	i,j,k,temp&
SHARED commonHandle
IF TotalSize>0 THEN
'debug "slider"+STR$(Totalsize)+STR$(curpos)+STR$(size)
	IF TotalSize<Size THEN
	' Its all at the top	
		curpos=1
		Size=1000
	ELSE
		temp&=1000*CLNG(curpos)
		curpos=temp&\(CLNG(TotalSize)-Size)+1
		IF curpos>1000 THEN curpos=1000
		temp&=1000*CLNG(Size)
		Size=temp& \CLNG(TotalSize)+1
		IF Size>1000 THEN Size=1000
	END IF
	i=WF_VSLSIZE-Horizontal
	k=0
	j=wind_set(CommonHandle,i,Size,k,k,k)
	i=i-7
	j=wind_set(CommonHandle,i,CurPos,k,k,k)
END IF
END SUB

FUNCTION GetOffset(BYVAL TotalHeight,BYVAL Value)
IF TotalHeight<0 THEN
	GetOffset=0
ELSE
	GetOffset=(CLNG(Value)*CLNG(TotalHeight)\1000)
END IF
END FUNCTION


SUB WindowSlid(BYVAL Horizontal,BYVAL WindowHandle,BYVAL Value)
SHARED commoni,commonmaxx,commonmaxy,commonhandle
SHARED cellx,celly
SHARED woSliderMax&(1),woOffX(1),woOffY(1)
STATIC x,y,w,h
	commoni=WhichWindow(WindowHandle)
	IF commoni>0 THEN
		commonhandle=WindowHandle
		CALLS woSliderMax&(commoni)
		junk=wind_get(CommonHandle,WF_WORKXYWH,x,y,w,h)
		h=(h\celly)*celly	'usable characters
		w=(w\cellx)*cellx

		IF Horizontal THEN
			woOffX(commoni)=GetOffset(commonmaxx-w,Value)
		ELSE
			woOffY(commoni)=GetOffset(commonmaxy-h,Value)
		END IF
		FullRedraw WindowHandle
	END IF
END SUB



SUB WindowArrowed(BYVAL WindowHandle, BYVAL which)
SHARED woOffX(1),woOffY(1),cellx,celly,woSliderMax&(1)
SHARED commonhandle,commoni,commonmaxx,Commonmaxy
STATIC x,y,w,h,NewX,NewY
	commoni=WhichWindow(WindowHandle)
	IF commoni>0 THEN
		junk=wind_get(WindowHandle,WF_WORKXYWH,x,y,w,h)
		h=(h\celly)*celly	'usable characters
		w=(w\cellx)*cellx
		NewX=woOffX(commoni): NewY=woOffY(commoni)
		SELECT CASE which
		CASE	0: NewY=NewY-h
		CASE 	1: NewY=NewY+h
		CASE	2: NewY=NewY-celly
		CASE	3: NewY=NewY+celly
		CASE	4: NewX=NewX-w
		CASE	5: NewX=NewX+w
		CASE	6: NewX=NewX-cellx
		CASE	7: NewX=NewX+cellx
		END SELECT
' Now check not too big or too small
		commonhandle=WindowHandle
		CALLS woSliderMax&(commoni)
		woOffX(commoni)=MAX(MIN(NewX,((commonmaxx-w-1)\cellx+1)*cellx),0)
		woOffY(commoni)=MAX(MIN(NewY,((commonmaxy-h-1)\celly+1)*celly),0)
						
		FullReDraw WindowHandle
	END IF 
END SUB


' changes the window whose AES handle is WindowHandle to WindowName$
SUB RenameWindow(WindowHandle,WindowName$)
STATIC BasicHandle
	WINDOW READ WindowHandle,6,BasicHandle	'convert from AES handle
	WINDOW NAME BasicHandle,WindowName$
END SUB

	
' redraw a given window taking note of the GEM re-draw list
SUB ReDraw(WindowHandle,BYVAL x,BYVAL y,BYVAL w,BYVAL h)
STATIC x1,y1,w1,h1,xvdi,yvdi,i
SHARED commonx,commony,commonw,commonh,commonhandle
SHARED woReDraw&(1)
	graf_mouse 256,0
	junk=wind_get(WindowHandle,WF_FIRSTXYWH,x1,y1,w1,h1)
	WHILE (w1<>0) AND (h1<>0)
		IF MyInterSection(x,y,w,h,x1,y1,w1,h1,commonx,commony,commonw,commonh) THEN
			vsf_color 0			' white
' set the rectangle AND clear it
			xvdi=commonx+commonw-1:yvdi=commony+commonh-1
			vs_clip 1,commonx,commony,xvdi,yvdi
			vr_recfl commonx,commony,xvdi,yvdi

' Now CALL the window specific routine
			i=WhichWindow(WindowHandle)
			IF i>0 THEN
				commonhandle=windowhandle 
				CALLS woReDraw&(i)
				UpdateSliders
			END IF
		END IF
		junk=wind_get(WindowHandle,WF_NEXTXYWH,x1,y1,w1,h1)
	WEND
	graf_mouse 257,0
END SUB


' redraws the entire window if exposed
SUB FullReDraw(BYVAL WindowHandle)
STATIC x,y,w,h
		junk=wind_get(WindowHandle,WF_WORKXYWH,x,y,w,h)
		Redraw WindowHandle,x,y,w,h
END SUB

' called when the window is moved OR changes size
SUB ChangeWindow(BYVAL WindowHandle,BYVAL x,BYVAL y,BYVAL w,BYVAL h)
SHARED woType(1),woObjectTree&(1),woBaseX(1),woBaseY(1),woOffX(1),woOffy(1)
STATIC i
	junk=wind_set(WindowHandle,WF_CURRXYWH,x,y,w,h)
	i=WhichWindow(WindowHandle)
	IF i=0 THEN EXIT SUB
	IF woType(i)<>woTform THEN EXIT SUB
	SelectTreeAddr woObjectTree&(i)
	Setob_x 0,woBaseX(i)-woOffX(i)+x
	Setob_y 0,woBasey(i)-woOffY(i)+y

END SUB

SUB UpdateSliders
SHARED CommonHandle,Commoni,commonmaxx,commonmaxy
SHARED woSliderMax&(1),woOffX(1),woOffY(1),woType(1)
STATIC x,y,w,h
SHARED Mess(1)
	CommonHandle=Mess(3)
	commoni=WhichWindow(CommonHandle)
	IF commoni=0 THEN EXIT SUB
	junk=wind_get(CommonHandle,WF_WORKXYWH,x,y,w,h)
	CALLS woSliderMax&(commoni)
	IF woType(commoni)=woTform THEN EXIT SUB			'without this the program crashes on old TOS
	OneSlider 1,commonmaxx,woOffX(commoni),w
	OneSlider 0,commonmaxy,woOffY(commoni),h
END SUB

DECLARE SUB do_cursor(BYVAL win_handle,BYVAL mode)

SUB TopAWindow(VAL WindowHandle)
SHARED woType(1)
STATIC i
i=WhichWindow(WindowHandle)
junk=wind_set(windowhandle,WF_TOP,0,0,0,0)
IF woType(i)=woTform THEN do_cursor windowhandle,1
END SUB

SUB UnTopAWindow(BYVAL WindowHandle)
SHARED woType(1)
STATIC i
i=WhichWindow(WindowHandle)
IF woType(i)=woTform THEN do_cursor WindowHandle,0
END SUB

'Deals with the common window update requirements:
'   Note that only includes redraw, topped,sized, moved, fulled etc
' Is passed a meesage a la evnt_mesag/evnt_multi

SUB WindowMessage
SHARED windx,windy,windh,windw,mess(1),myap_id
STATIC x,y,w,h,mes_type,tmp,align
	mes_type=mess(0)
	SELECT CASE mes_type
		CASE WM_REDRAW:
			ReDraw Mess(3),Mess(4),Mess(5),Mess(6),Mess(7)
		CASE WM_TOPPED:
			topawindow mess(3)
		CASE WM_UNTOPPED:
			UntopAWindow mess(3)
		CASE WM_SIZED:
			Changewindow Mess(3),Mess(4),Mess(5),Mess(6),Mess(7) ' current size
			UpdateSliders
		CASE WM_MOVED:		
			mess(4)=byte_align(mess(4))-1
			ChangeWindow Mess(3),Mess(4),Mess(5),Mess(6),Mess(7) ' current size
 		CASE WM_FULLED:
			junk=wind_get(Mess(3),WF_CURRXYWH,x,y,w,h) ' current size

			IF (windw<>w) OR (windh<>h) OR (windx<>x) OR (windy<>y) THEN
				'  make as large as possible
				ChangeWindow  Mess(3),windx,windy,windw,windh
			ELSE
				'  return to  the old size
				junk=wind_get(Mess(3),WF_PREVXYWH,x,y,w,h)
				ChangeWindow Mess(3),x,y,w,h
			END IF
			UpdateSliders
		CASE WM_VSLID:
			WindowSlid 0,Mess(3),Mess(4)
		CASE WM_HSLID:
			WindowSlid 1,Mess(3),Mess(4)
		CASE WM_ARROWED:
			WindowArrowed Mess(3),Mess(4)
	END SELECT
END SUB

'Initialise the window system
SUB	InitWindowSystem
SHARED cellx,celly,HowManyWindows,myap_id
SHARED woHandle(1),woRedraw&(1),woOffx(1),woOffy(1),woClose&(1)
SHARED woType(1),woTindex(1),woSliderMax&(1)
SHARED WindowsInitialised,max_windows
IF aes_version>=&h330 THEN max_windows=19 ELSE max_windows=7
REDIM woHandle(max_windows)	' the handle of this window
REDIM	woRedraw&(max_windows)	' the address of the re-draw proc
REDIM woSliderMax&(max_windows) ' slider handling routines
REDIM woClose&(max_windows)	' window closed handler
REDIM woType(max_windows)

REDIM	woOffx(max_windows),woOffy(max_windows) 'offset of top left 0,0 unless we have scrolled

REDIM woTindex(max_windows)	'maps window numbers to indices in the lines$() array
' Utility functions for the windows section
' Returns the index in the wo... tables of Windowhandle



	HowManyWindows=0
	junk=graf_handle(cellx,celly,junk,junk)
	myap_id=PEEKW(PEEKL(GB+4)+ap_id)
	WindowsInitialised=-1
END SUB

SUB NoMoreWindows
STATIC a$
a$="[3][There are no more|windows available.| |Please close a window.][ OK ]"
junk=form_alert(1,a$)
END SUB