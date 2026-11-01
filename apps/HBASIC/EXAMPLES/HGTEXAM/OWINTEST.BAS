defint a-z
REM $option !g[&
REM $option k100,y
REM $include gold.bh
rem $include toolbox.bas
rem $include window.bas
rem $include objwind.bas

SUB ProcessKeys(BYVAL ascii$,BYVAL scan_code,BYVAL kstate)
SHARED finished_flag
STATIC handle1
SELECT CASE ascii$
CASE chr$(15): 'ctrl-o
handle1=OpenObjectWindow("Toolbox Object",win_all-win_info,form2)
	
CASE chr$(17),"E": 'ctrl-q
	finished_flag=-1
END SELECT
END SUB


StartProgram "GOLD.RSC",0,0
keys_enabled=-1
HGTloop
StopProgram
