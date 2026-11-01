REM $option !g[&
REM $option k100,y
REM $include wrsc.bh
rem $include toolbox.bas
rem $include newdesk.bas

SUB ProcessKeys(BYVAL ascii$,BYVAL scan_code,BYVAL kstate)
SHARED finished_flag,TextWindows,wolines(1),desk_flag
STATIC handle2
SELECT CASE ascii$
CASE chr$(15): 'ctrl-o
		IF desk_flag THEN
			desk_flag=0
			SetDesk -1			'reset it
		ELSE
			desk_flag=-1
			SetDesk NewDeskTop
		END IF
	
CASE chr$(17),"E": 'ctrl-q
	finished_flag=-1
END SELECT
END SUB

desk_flag=0
StartProgram "WRSC.RSC",0,0
keys_enabled=-1
HGTloop
StopProgram
