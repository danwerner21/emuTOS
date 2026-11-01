' Your first HGT program
' Displays a window with a text file and menu
' Needs the TWDM.T tokenised file and its own
' .BH and .RSC files.

REM $option y,l10

' Get the resource file header
REM $include HGT1.BH

CONST maxlines=200

' The heart of the program. Handles all menu
' interaction.

SUB ProcessUserMenus(VAL wind, VAL item, VAL title)
SHARED Finished_Flag,MyWindow,wolines(1),whandle
STATIC dum

  SELECT CASE item
    CASE menu_about 
      SelectTree about
      dum=HandleDialog(0)
    CASE menu_quit
      SelectTree quit
      dum=HandleDialog(0)
      IF dum=qu_ok THEN Finished_Flag=-1 ELSE Finished_Flag=0
    CASE menu_load
      SelectTree load
      dum=HandleDialog(0)
      IF dum=load_ok THEN
        LoadTextFile "HGT1.BAS",MyWindow,wolines(MyWindow)
        FullRedraw whandle
      END IF
        
  END SELECT  

END SUB

' Initialisation.

StartProgram "HGT1.RSC",menu1,-1

InitTextWindows 1,maxlines
MyWindow=TextWindows
whandle=OpenTextWindow("Your first GEM program",win_all-win_info)
  
' The main toolbox loop
HGTLoop

StopProgram
