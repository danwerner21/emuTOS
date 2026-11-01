' Gold Fish example showing dragging icons
REM $option uvgy,l10,#
REM $include toolbox.bas
REM $include newdesk.bas
REM $include dialog.bas
REM $include menu.bas

'Our actual program
' get the header file created with WERCS
REM $INCLUDE WRSC.BH

' global variables
DIM SHARED junk,deskflag,checked
DIM SHARED edit$,radio

clicks_enabled=1
SUB ProcessClicks(byval clicks,byval kstate,byval x,byval y)
SHARED windx,windy,windw,windh
SHARED desktree&
STATIC found,newx,newy
'	Debug "Clicks="+STR$(Clicks)+"kstate="+STR$(kstate)+"x="+STR$(x)+"y="+STR$(y)
	found=objc_find(desktree&,0,7,x,y)
	IF found>0 THEN
		graf_mouse 4,0
		SelectTreeAddr desktree&
		graf_dragbox Getob_width(found),Getob_height(found),Getob_x(found),Getob_y(found), _
				Getob_x(0),Getob_y(0),Getob_width(0),Getob_height(0),newx,newy
		Setob_x found,newx
		Setob_y found,newy
		graf_mouse 0,0
		form_dial FMD_FINISH,0,0,0,0,Windx,Windy,Windw,Windh
	END IF	
	Debug "found "+STR$(found)
END SUB

' a routine to handle our particular dialog box
SUB test_dialog
STATIC dlog&,result
SelectTree TestDialog
Sette_ptext DEditable,edit$
SetButton DParent,radio
result=HandleDialog(DEditable)
IF result=DOK THEN
	edit$=Gette_ptext$(DEditable)
	radio=GetButton(DParent)
END IF
END SUB

' handle a given menu click
SUB ProcessUserMenus(VAL cur_front,VAL item,VAL title)
SHARED windx,windy,windw,windh
SHARED menutree&
STATIC temp&
SELECT CASE item
	=MAbout
		junk=newform_alert(AAlert,1)
 	=MCheckme
		checked=checked XOR 1
		menu_icheck menutree&,MCheckme,checked
	=MDialog
		test_dialog
	=MInstall
		IF deskflag THEN
			deskflag=0
			SetDesk -1			'reset it
		ELSE
			deskflag=-1
			SetDesk NewDeskTop
		END IF
END SELECT
END SUB

' the main program starts here
StartProgram "Wrsc.RSC",MENU1,MQUIT
deskflag=0

' get the screen size
' set default values for dialog box
edit$=""
radio=DRadio1

HGTloop
StopProgram

' that's all folks
