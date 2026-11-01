defint a-z
rem $include menutest.bh
rem $include toolbox.bas
rem $include menu.bas

SUB ProcessUserMenus(BYVAL cur_front,BYVAL item,BYVAL title)
SELECT CASE item
CASE PlayTune:
		SOUND 1,15,10,3,20
		sound 1,15,12,3,20
		sound 1,15,8,3,20
		sound 1,15,8,3,24
		sound 1,15,3,3,40
		Sound 1,0
END SELECT
END SUB

StartProgram "MENUTEST.RSC",MENU1,QUIT
HGTloop
StopProgram