
' The text window routines
SUB InitTextWindows(BYVAL MaxFiles,BYVAL MaxLines)
SHARED aligntext,tabsize,MaxTextWidth,wolines(1),lines$(2),TextWindowsInitialised
SHARED MaxTextWindows,TextWindows
MaxTextWindows=MaxFiles
REDIM wolines(MaxTextWindows-1),lines$(MaxtextWindows-1,maxLines)
	aligntext=-1 	' align to word boundaries for speed by default
	tabsize=8
	MaxTextWidth=300
	TextWindows=0
	TextWindowsInitialised=-1
END SUB

SUB TextSliderMax
SHARED wolines(1),MaxTextWidth,cellx,celly,woTindex(1)
SHARED commoni,commonmaxx,commonmaxy
		commonmaxx=MaxTextWidth*cellx
		commonmaxy=wolines(woTindex(commoni))*celly
END SUB

SUB TextReDraw
SHARED commonhandle,cellx,celly
SHARED wolines(1),lines$(2),woTindex(1)
SHARED aligntext,expandtabsflag,MaxTextwidth,woOffX(1),woOffY(1)
STATIC i,x,y,w,h,curline,newx,linebuf$,linestodo,j,file,margin
	i=WhichWindow(commonHandle)
	IF i=0 THEN EXIT SUB ' panic
	junk=wind_get(CommonHandle,WF_WORKXYWH,x,y,w,h)
	file=woTindex(i)
'debug str$(x)+str$(y)+str$(newx)
	IF aligntext THEN
		newx=((x+7)\8)*8
		w=w-newx+x
		x=newx
	END IF
	curline=woOffY(i)\celly
	linestodo=h\celly
	IF curline+linestodo>wolines(file) THEN linestodo=wolines(file)-curline
'	Debug "From"+STR$(curline)+"doing"+STR$(linestodo)
	margin=woOffX(i)\cellx
	FOR j=1 TO linestodo
		y=y+celly
		IF expandtabsflag OR margin<>0 THEN
			IF expandtabsflag THEN
				ExpandTabs lines$(file,curline),linebuf$
				IF woOffX(i)<>0 THEN
					linebuf$=MID$(linebuf$,margin+1)
				END IF
			ELSE
				linebuf$=MID$(lines$(file,curline),margin+1)
			END IF	
			v_gtext x,y,linebuf$
		ELSE
			v_gtext x,y,lines$(file,curline)
		END IF
		INCR curline
	NEXT j
END SUB

SUB TextClose
SHARED HowManyWindows,Commoni,woTindex(1),lines$(2),TextWindows,wolines(1)
STATIC j,k
	FOR j=1 TO HowManywindows+1
		IF woTindex(j)>woTindex(commoni) THEN  DECR woTindex(j)
	NEXT j
	
	DECR TextWindows
	FOR j=woTindex(commoni)+1 TO TextWindows
		woLines(j-1)=woLines(j)
		FOR k=0 TO UBOUND(lines$,2)
			lines$(j-1,k)=lines$(j,k)
		NEXT k
	NEXT j
	woTindex(commoni)=0
END SUB
'Opens a scrolling window that displays text - the
' text is stroed as lines in the lines$(i,n) array where i is
' text file number. The number of lines is stored in wolines()
FUNCTION OpenTextWindow(WindowName$,WindComp)
STATIC WindowHandle
SHARED woType(1),woTindex(1),TextWindows,MaxTextWindows,HowManyWindows
	WindowHandle=OpenAWindow(WindowName$,WindComp,VARPTRS(TextReDraw),VARPTRS(TextSliderMax),VARPTRS(TextClose))
	IF WindowHandle >= 0 THEN
			INCR TextWindows
			IF TextWindows>MaxTextWindows THEN
				DECR TextWindows
				WindowHandle=-1
			ELSE
				woType(HowManyWindows)=woTtext
				woTindex(HowManyWindows)=TextWindows-1
			END IF
	END IF
	OpenTextWindow=WindowHandle
'	DEbug "opened window"
END FUNCTION

SUB LoadTextFile(name$,BYVAL index,lines)
SHARED lines$(2)
STATIC i,tempch
BusyBee 1
tempch=FREEFILE
OPEN name$ FOR INPUT AS tempch
i=0
WHILE NOT EOF(tempch)
	LINE INPUT #tempch,lines$(index,i)
	INCR i
WEND
'debug  STR$(i)+ "lines"
lines=i
CLOSE tempch
BusyBee 0
END SUB

' expand any tabs in the string sce$ to dest$
SUB ExpandTabs(sce$,dest$)
SHARED tabsize
STATIC i,j,ch,newj
i=1:j=1:dest$=""
FOR i=1 TO LEN(sce$)
	ch=ASC(MID$(sce$,i,1))
	IF ch=9 THEN
		newj=((j-1)\tabsize+1)*tabsize+1
		dest$=dest$+SPACE$(newj-j)
		j=newj
	ELSE
		dest$=dest$+CHR$(ch)
		INCR j
	END IF
NEXT i
END SUB

