'Execute routines for the Toolbox

FUNCTION GetWholeEnvironment$
STATIC i,res$,a$
res$=""
i=1
DO
	a$=ENVIRON$(i)
	IF a$="" THEN EXIT LOOP
	res$=res$+a$+CHR$(0)
	INCR i
LOOP
GetWholeEnvironment$=res$
END FUNCTION

SUB Execute(nname$,commline$)
SHARED menutree&,Windx,Windy,Windw,Windh,HowManyWindows,woHandle(1)
SHARED desktree&
STATIC junk&,junk,wind_temp(2),curhandle,i,curtop

	junk=wind_get(0,WF_TOP,curtop,0,0,0)
	DIM windtemp(HowmanyWindows,4)
	FOR i=1 TO HowManyWindows
		curhandle=woHandle(i)
		junk=wind_get(curhandle,WF_CURRXYWH,windtemp(i,1),windtemp(i,2),windtemp(i,3),windtemp(i,4)) ' current size
		junk=wind_close(woHandle(i))
	NEXT i


IF menutree& THEN menu_bar menutree&,0

junk=wind_update(END_UPDATE)

junk&=pexec&(0,nname$,commline$,GetWholeEnvironment$)
junk=wind_set(0,WF_NEWDESK,PEEKW(VARPTR(desktree&)),PEEKW(VARPTR(desktree&)+2),0,0)


IF menutree& THEN menu_bar menutree&,1
FOR i=1 TO HowManyWindows
	junk=wind_open(woHandle(i),windtemp(i,1),windtemp(i,2),windtemp(i,3),windtemp(i,4)) ' current size
NEXT i
ERASE windtemp
junk=wind_set(0,WF_TOP,curtop,0,0,0)
form_dial FMD_FINISH,0,0,0,0,Windx,Windy,Windw,Windh

junk=wind_update(BEG_UPDATE)

END SUB
