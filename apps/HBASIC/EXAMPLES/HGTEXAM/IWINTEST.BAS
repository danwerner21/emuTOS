defint a-z
REM $option !g[&
REM $option k100,y
rem $include toolbox.bas
rem $include image.bas
rem $include window.bas
rem $include imagwind.bas

SUB ProcessKeys(BYVAL ascii$,BYVAL scan_code,BYVAL kstate)
SHARED finished_flag,ImageWindows,wolines(1)
STATIC handle2,finame$
SELECT CASE ascii$
CASE chr$(15): 'ctrl-o
	finame$="BLOCK.NEO"
	LoadPicture finame$,imagewindows
	handle2=OpenImageWindow(finame$,win_all-win_info)
	
CASE chr$(17),"E": 'ctrl-q
	finished_flag=-1
END SELECT
END SUB


StartProgram "",0,0
keys_enabled=-1
InitWindowSystem
DIM images(2,fd_size)
HGTloop
StopProgram
