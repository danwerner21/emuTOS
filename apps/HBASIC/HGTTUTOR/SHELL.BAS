REM The Shell program referred to in the
REM HiSoft BASIC 2 tutorial.
REM Needs the HGT.T pre-tokenised file (from the HGT folder)
REM and its own .BH and .RSC files.

REM $option k150,y
REM $include shell.bh

SUB ProcessUserMenus(VAL cur_front,VAL item,VAL title)
SHARED texth,wolines(1),lines$(2),TextWindows,ImageWindows
STATIC i,fi$,temp,id,curline$,Comm

SELECT CASE item
CASE MeAboutShell: junk=NewForm_Alert(AboutAlert,1)
CASE MeShowTextFi:	
		fi$=FileSelect$
		IF fi$<>"" THEN
			LoadTextFile fi$,TextWindows,wolines(TextWindows)
			texth=OpenTextWindow(fi$,win_all-win_info)
		END IF

CASE	MeShowImageF:
		fi$=FileSelect$
		IF fi$<>"" THEN
			LoadPicture fi$,imagewindows
			texth=OpenImageWindow(fi$,win_all-win_info)
		END IF
		
CASE MeRunProgram:
		fi$=FileSelect$
		IF fi$<>"" THEN Execute fi$,curline$
		
CASE MeSetCommandL:
		SelectTree CLine
		Sette_ptext Clcommandline,curline$
		Comm=HandleDialog(CLcommandline)
		SELECT CASE Comm 
		CASE ClOK:
			curline$=Gette_ptext$(CLcommandline)
		END SELECT
END SELECT

END SUB

StartProgram "SHELL.RSC",MENU1,MEQUIT
InitTextWindows 2,1500
DIM images(2,fd_size)
expandtabsflag=-1
HGTloop
StopProgram