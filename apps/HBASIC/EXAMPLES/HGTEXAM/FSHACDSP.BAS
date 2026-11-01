REM $option j140,y+,v+,u+,#,[,]
REM $include acctbox.bas
rem $include window.bas
rem $include textwind.bas
rem $include image.bas
rem $include imagwind.bas
REM $include filesel.bas

SUB AccOpened
SHARED finame$,ext$,imageWindows,textWindows,wolines(1),AlreadyOpen
STATIC x,texth,temp,i
		IF AlreadyOpen THEN
			CloseAWindow Texth
		ELSE
			InitTextWindows 1,2000
		END IF
		finame$=FileSelect$
		IF finame$<>"" THEN
			ext$=UCASE$(MID$(finame$,LEN(finame$)-3,3))
			SELECT CASE ext$
			CASE ".PI",".PC",".IM",".NE":
				LoadPicture finame$,imagewindows
				texth=OpenImageWindow(finame$,win_all-win_info)
			CASE ELSE
' treat as text
				LoadTextFile finame$,TextWindows,wolines(TextWindows)
				texth=OpenTextWindow(finame$,win_all-win_info)
			END SELECT
			FullReDraw texth
		END IF

END SUB

DIM images(2,fd_size)
ExpandTabsFlag=-1
StartAccessory "  HGT Display  "
