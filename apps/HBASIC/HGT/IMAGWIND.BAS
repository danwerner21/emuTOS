' The Image window routines
SUB ImageReDraw
SHARED commonhandle
SHARED woTindex(1),woOffX(1),woOffY(1)
SHARED images(2),mscr(1)
STATIC i,x,y,w,h,index,remaining,local_mfdb(1),mscr(1),x(1),j,disp$
STATIC displayed_height,displayed_width
	i=WhichWindow(commonHandle)
	IF i=0 THEN EXIT SUB ' panic
	junk=wind_get(CommonHandle,WF_WORKXYWH,x,y,w,h)
	REDIM local_mfdb(fd_size),mscr(fd_size),x(8)
	index=woTindex(i)
	FOR j=0 TO fd_size: local_mfdb(j)=images(index,j): NEXT j
	x(0)=woOffX(i):x(1)=woOffY(i)
	displayed_width=MIN(local_mfdb(fd_w)-woOffX(i),w)
	displayed_height=MIN(local_mfdb(fd_h)-woOffY(i),h)
	x(2)=x(0)+displayed_width-1
	x(3)=x(1)+displayed_height-1
	x(4)=x: x(5)=y
	x(6)=x+displayed_width-1
	x(7)=y+displayed_height-1
'	disp$=""
	
'	FOR j=0 TO 7: disp$=disp$+STR$(x(j)): NEXT j
'	Debug disp$
	
	vro_cpyfm 3,x(),VARPTR(local_mfdb(0)),VARPTR(mscr(0))
END SUB


SUB ImageSliderMax
SHARED commonHandle,woTindex(1),images(2),commonmaxx,commonmaxy
STATIC index
	index=woTindex(commonHandle)
	commonmaxx=images(index,fd_w)
	commonmaxy=images(index,fd_h)
END SUB

SUB ImageClose
SHARED commoni,HowManyWindows
SHARED woObjectTree&(1),woBaseX(1),woBaseY(1)
STATIC j
	FOR j=commoni TO HowManyWindows
 		woObjectTree&(j)=woObjectTree&(j+1)
		woBaseX(j)=woBaseX(j+1)
		woBaseY(j)=woBaseY(j+1)
	NEXT j
END SUB

'Opens a scrolling window that displays an image - the
' image is stored in images() and must be loaded using
' LoadPicture <filename>,ImageWindows
FUNCTION OpenImageWindow(WindowName$,WindComp)
STATIC WindowHandle
SHARED HowManywindows
SHARED woType(1),woTindex(1),ImageWindows
	WindowHandle=OpenAWindow(WindowName$,WindComp,VARPTRS(ImageReDraw),VARPTRS(ImageSliderMax),VARPTRS(ImageClose))
	IF WindowHandle >= 0 THEN
			woType(HowManyWindows)=woTimage
			woTindex(HowManyWindows)=ImageWindows
			INCR ImageWindows
' Check here for too many image windows
	END IF
	OpenImageWindow=WindowHandle
'	DEbug "opened window"
END FUNCTION

