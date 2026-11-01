defint a-z
REM $option !g[&
REM $option k100,y
rem $include toolbox.bas
rem $include window.bas
rem $include filesel.bas
rem $include textwind.bas

SUB ProcessKeys(BYVAL ascii$,BYVAL scan_code,BYVAL kstate)
SHARED finished_flag,TextWindows,wolines(1)
STATIC temp,finame$,texth,i
SELECT CASE ascii$
CASE chr$(15): 'ctrl-o
	finame$=FileSelect$
	IF finame$<>"" THEN
' treat as text
		LoadTextFile finame$,TextWindows,wolines(TextWindows)
		texth=OpenTextWindow(finame$,win_all-win_info)
	END IF
CASE chr$(17),"E": 'ctrl-q
	finished_flag=-1
END SELECT
END SUB

StartProgram "",0,0
InitTextWindows 3,2000
keys_enabled=-1
expandtabsflag=-1
HGTloop
StopProgram
