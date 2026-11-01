' Note that to use this program wyou will need to supply
' your own .IMG file
REM $option !g
REM $option k100,y
REM $include gold.bh
REM $include toolbox.bas
REM $include image.bas
REM $include menu.bas
REM $include window.bas
REM $include imagwind.bas
REM $include dialog.bas
REM $include filesel.bas

SUB ProcessUserMenus(VAL cur_front,VAL item,VAL title)
SHARED texth,ImageWindows
STATIC i,finame$,temp,id,ext$
SELECT CASE item
CASE MeAboutGold: junk=NewForm_Alert(ABOUTALERT,1)
CASE MeLoad:	
		finame$=FileSelect$
		IF finame$<>"" THEN
				IF imagewindows THEN
					CloseImage imagewindows
					DECR imagewindows
					CloseAWindow texth
				END IF
				LoadPicture finame$,imagewindows
				texth=OpenImageWindow(finame$,win_all-win_info)
		END IF
	END SELECT
END SUB


StartProgram "GOLD.RSC",MENU1,MEQUIT
InitFileSelector
fspath$=LEFT$(fspath$,LEN(fspath$)-1)+"IMG"
DIM images(2,fd_size)
HGTloop
StopProgram