' HiSoft BASIC GEM Toolkit

' Copyright HiSoft 1991-3
' You are welcome to use this code and modifications of it in
' your own programs, which you may distribute without royalties.
' However this source code and modifications to it may not
' be distributed without our express permission.

' written by Dave Nutkins and Ofir Gal
  DEFINT a-z
	GOTO	skip
' 10k should be plenty to Leave, variable checks on, no window
REM $option g,y+,v+,u+,#,[,]
'  constant file for HiSoft BASIC
' use defint a-z and option u+
' end of GEMAES.BH
'  constant file for HiSoft BASIC
' use defint a-z and option u+
rem $include gemaes.bh

LIBRARY "gemaes","gemvdi","gemdos","xbios"

DIM SHARED junk

'Object Tree routines

DIM SHARED tree&		' the current Toolbox tree
'Gives the address of the given object in the current tree
DEF ObjectAddr&(object)=tree&+object*ob_sizeof

'Selects a new tree given the address of the root
SUB SelectTreeAddr(BYVAL t&)
tree&=t&
END SUB

' Selects a given tree in the resource file
SUB SelectTree(BYVAL treeno)
STATIC formaddr&
	junk=rsrc_gaddr(type_tree,treeno,formaddr&)
	SelectTreeAddr formaddr&
END SUB


'Returns the value of the ob_head field in the given object of the current tree
FUNCTION Getob_head(BYVAL object)
Getob_head=PEEKW(ObjectAddr&(object)+ob_head)
END FUNCTION

'Returns the value of the ob_tail field in the given object of the current tree
FUNCTION Getob_tail(BYVAL object)
Getob_tail=PEEKW(ObjectAddr&(object)+ob_tail)
END FUNCTION

'Returns the value of the ob_spec field in the given object of the current tree
FUNCTION Getob_spec&(BYVAL object)
Getob_spec&=PEEKL(ObjectAddr&(object)+ob_spec)
END FUNCTION

'Returns the value of the ob_state field in the given object of the current tree
FUNCTION Getob_state(BYVAL object)
Getob_state=PEEKW(ObjectAddr&(object)+ob_state)
END FUNCTION

'Returns the value of the ob_flags field in the given object of the current tree
FUNCTION Getob_flags(BYVAL object)
Getob_flags=PEEKW(ObjectAddr&(object)+ob_flags)
END FUNCTION

'Returns the value of the ob_type field in the given object of the current tree
FUNCTION Getob_type(BYVAL object)
Getob_type=PEEKW(ObjectAddr&(object)+ob_type)
END FUNCTION

'Returns the value of the ob_next field in the given object of the current tree
FUNCTION Getob_next(BYVAL object)
Getob_next=PEEKW(ObjectAddr&(object)+ob_next)
END FUNCTION

'Returns the value of the ob_x field in the given object of the current tree
FUNCTION Getob_x(BYVAL object)
Getob_x=PEEKW(ObjectAddr&(object)+ob_x)
END FUNCTION

'Returns the value of the ob_y field in the given object of the current tree
FUNCTION Getob_y(BYVAL object)
Getob_y=PEEKW(ObjectAddr&(object)+ob_y)
END FUNCTION

'Returns the value of the ob_width field in the given object of the current tree
FUNCTION Getob_width(BYVAL object)
Getob_width=PEEKW(ObjectAddr&(object)+ob_width)
END FUNCTION

'Returns the value of the ob_height field in the given object of the current tree
FUNCTION Getob_height(BYVAL object)
Getob_height=PEEKW(ObjectAddr&(object)+ob_height)
END FUNCTION

'Sets the value of the ob_state field in the given object of the current tree
SUB Setob_state(BYVAL object,BYVAL value)
POKEW ObjectAddr&(object)+ob_state,value
END SUB

'Sets the value of the ob_flags field in the given object of the current tree
SUB Setob_flags(BYVAL object,BYVAL value)
POKEW ObjectAddr&(object)+ob_flags,value
END SUB

'Sets the value of the ob_x field in the given object of the current tree
SUB Setob_x(BYVAL object,BYVAL value)
POKEW ObjectAddr&(object)+ob_x,value
END SUB

'Sets the value of the ob_y field in the given object of the current tree
SUB Setob_y(BYVAL object,BYVAL value)
POKEW ObjectAddr&(object)+ob_y,value
END SUB

'Sets the value of the ob_width field in the given object of the current tree
SUB Setob_width(BYVAL object,BYVAL value)
POKEW ObjectAddr&(object)+ob_width,value
END SUB

'Sets the value of the ob_height field in the given object of the current tree
SUB Setob_height(BYVAL object,BYVAL value)
POKEW ObjectAddr&(object)+ob_height,value
END SUB

'Sets the value of the ob_spec field in the given object of the current tree
SUB Setob_spec(BYVAL object,BYVAL spec&)
POKEL ObjectAddr&(object)+ob_spec,spec&
END SUB

'Removes a given mask (e.g. mask_selected,mask_disable) from the ob_state
'field in the given object of the current tree
SUB Exclob_state(BYVAL object,BYVAL flag_mask)
STATIC t&
t&=ObjectAddr&(object)+ob_state
POKEW	t&,PEEKW(t&) AND (NOT flag_mask)
END SUB

'Includes a given mask (e.g. mask_selected,mask_disable) from the ob_state
'field in the given object of the current tree
SUB Inclob_state(BYVAL object,BYVAL flag_mask)
STATIC t&
t&=ObjectAddr&(object)+ob_state
POKEW t&,PEEKW(t&) OR flag_mask
END SUB

'Returns non-zero if a given mask(e.g. mask_selected,mask_disable) from the
'ob_state field is set
FUNCTION Curob_state(BYVAL object,BYVAL flag_mask)
Curob_state=(PEEKW(ObjectAddr&(object)+ob_state) AND flag_mask)<>0
END FUNCTION

'Removes a given mask (e.g. mask_selectable,mask_exit) from the ob_flags
'field in the given object of the current tree
SUB Exclob_flags(BYVAL object,BYVAL flag_mask)
STATIC t&
t&=ObjectAddr&(object)+ob_flags
POKEW	t&,PEEKW(t&) AND (NOT flag_mask)
END SUB

'Includes a given mask (e.g. mask_selectable,mask_exit) from the ob_flags
'field in the given object of the current tree
SUB Inclob_flags(BYVAL object,BYVAL flag_mask)
STATIC t&
t&=ObjectAddr&(object)+ob_flags
POKEW t&,PEEKW(t&) OR flag_mask
END SUB

'Returns non-zero if a given mask(e.g. mask_selected,mask_disable) from the
'ob_flags field is set
FUNCTION Curob_flags(BYVAL object,BYVAL flag_mask)
Curob_flags=(PEEKW(ObjectAddr&(object)+ob_flags) AND flag_mask)<>0
END FUNCTION

' set a tedinfo record
SUB Sette_ptext(BYVAL object,BYVAL newted$)
STATIC t&,chars,i
t&=Getob_spec&(object)
chars=MIN(PEEKW(t&+te_txtlen)-1,LEN(newted$))		'-1 for the null
t&=PEEKL(t&+te_ptext)
FOR i=1 TO chars
	POKEB t&,ASC(MID$(newted$,i,1))
	INCR t&
NEXT i
POKEB t&,0									'must end in null
END SUB

' extract a tedinfo record
FUNCTION Gette_ptext$(BYVAL object)
STATIC t&,a$
a$=""
t&=Getob_spec&(object)
t&=PEEKL(t&+te_ptext)
WHILE PEEKB(t&)
	a$=a$+CHR$(PEEKB(t&))
	INCR t&
WEND
Gette_ptext$=a$
END FUNCTION

' Extract ob_spec field as a BASIC string
FUNCTION Getob_spec$(BYVAL object)
STATIC t&,a$
a$=""
t&=Getob_spec&(object)
WHILE PEEKB(t&)
	a$=a$+CHR$(PEEKB(t&))
	INCR t&
WEND
Getob_spec$=a$
END FUNCTION

' Set ob_spec field as a BASIC string
SUB Setob_spec_str(BYVAL object,BYVAL spec$)
STATIC t&,i,chars
'chars=MIN(LEN(spec$),LEN(getob_spec$(object)))
chars=LEN(spec$)
t&=Getob_spec&(object)
FOR i=1 TO chars
	POKEB t&,ASC(MID$(spec$,i,1))
	INCR t&
NEXT i
POKEB t&,0									'must end in null
END SUB


FUNCTION ConvertAlt(ScanCode)
STATIC a&,res
	a&=keytbl&(-1,-1,-1)
	res=PEEKB(PEEKL(a&)+CLNG(ScanCode)\256)
	IF res>="a"% AND res<="z"% THEN res=res-"a"%+"A"%
	ConvertAlt=res
END FUNCTION

' If Busy is true (non-zero) then  makes the rodent busy
SUB BusyBee(BYVAL Busy)
 IF Busy THEN
	graf_mouse 2,0
 ELSE
	graf_mouse 0,0
 END IF
END SUB

DECLARE SUB InitMenuSystem(BYVAL treenumber,BYVAL exititem)
DECLARE SUB CloseAllImages


SUB InitResourceFile(name$)

' Load resouce file - giving alert if not found
' should use the PATH ?
SHARED resource_loaded
' load the resource file
IF rsrc_load(name$)=0 THEN
	' this alert can't be in the resource file of course..
	junk=form_alert(1,"[3][Resource file not found][ Quit ]")
	SYSTEM
END IF
resource_loaded=-1
END SUB

FUNCTION byte_align(BYVAL x)
SHARED supress_byte_align
IF supress_byte_align=0 THEN byte_align=(x+4) AND &hFFF8
END FUNCTION

FUNCTION WhichWindow(BYVAL AEShandle)
SHARED woHandle(1)
SHARED HowManyWindows
STATIC i
	i=0
	IF HowManyWindows>0 THEN
		DO
			INCR i
		LOOP WHILE (i <= HowManyWindows) AND (woHandle(i)<>AEShandle)
		IF woHandle(i)<>AEShandle THEN i=0
	END IF
	WhichWindow=i
END FUNCTION

' Returns TRUE IF WindowHandle was opened using OpenAWindow
FUNCTION IsMyWindow(BYVAL WindowHandle)
	IsMyWindow= WhichWindow(WindowHandle)>0
END FUNCTION

DECLARE SUB WindowMessage
DECLARE SUB CloseAWindow(WindowHandle)
DECLARE SUB ProcessUserMenus(BYVAL wind,BYVAL item,BYVAL title)

' process message event
SUB do_message
STATIC cur_front,MessageType,title,item
SHARED exit_item,Finished_Flag,menutree&,Mess(1)
	MessageType=Mess(0)
	IF (MessageType>=WM_REDRAW) AND (MessageType<=WM_MOVED) THEN
		IF NOT IsMyWindow(Mess(3)) THEN EXIT SUB ' it's not our's
 	END IF
	junk=wind_get(Mess(3),WF_TOP,cur_front,junk,junk,junk)
 	SELECT CASE MessageType
 	CASE MN_SELECTED:
		'  its a menu
		title=Mess(3)
		' un-highlight the menu item even if not at front
		'	- strictly this should be done later but this would
		'	need more code
		menu_tnormal menutree&,title,1
		item=Mess(4)
		IF item=exit_item THEN
			Finished_Flag=-1
		ELSE
			ProcessUserMenus cur_front,item,title
		END IF
 	CASE WM_CLOSED: 
 		CloseAWindow mess(3)
	CASE AP_TERM
		Finished_Flag=-1	
	CASE ELSE
		WindowMessage
	END SELECT
END SUB


DECLARE FUNCTION CreateShortCut(BYVAL Scancode)
DECLARE SUB ProcessClicks(BYVAL clicks,BYVAL kstate,BYVAL x,BYVAL y)
DECLARE SUB ProcessKeys(BYVAL ascii$,BYVAL scan_code,BYVAL kstate)

'The Toolbox's main loop
SUB HGTloop
STATIC ev,key_pressed,clicks,x,y,kstate
SHARED finished_flag,Mess(1),clicks_enabled,keys_enabled,menus_enabled
 REDIM mess(7)
 finished_flag=0
 DO
	junk=wind_update(END_UPDATE)
	ev=evnt_multi(MU_MESAG+MU_KEYBD+MU_BUTTON,2,1,1,_
			0,0,0,0,0,_
			0,0,0,0,0,_
			VARPTR(mess(0)),0,_
			x,y, _
			0,kstate, _
			key_pressed,clicks)
	junk=wind_update(BEG_UPDATE)
	IF ev AND MU_KEYBD THEN
		IF menus_enabled THEN
			IF CreateshortCut(key_pressed) THEN
				do_message
			ELSE
				IF keys_enabled THEN
' process keystrokes that aren't menu items
					ProcessKeys CHR$(key_pressed AND 255),key_pressed,kstate
				END IF
			END IF
		ELSEIF keys_enabled THEN
		' process keystrokes
			ProcessKeys CHR$(key_pressed AND 255),key_pressed,kstate
' otherwise ignore keys
		END IF
	END IF
	IF ev AND MU_MESAG THEN
		do_message
	END IF
	IF ev AND MU_BUTTON THEN
		IF clicks_enabled THEN 
			ProcessClicks clicks,kstate,x,y
		END IF
	END IF
	LOOP UNTIL finished_flag
END SUB

SUB StartProgram(resourcefile$,treenumber,exititem)
SHARED WindX,WindY,WindW,WindH
WINDOW ON
IF resourcefile$<>"" THEN
	InitResourceFile resourcefile$
	IF exititem THEN InitMenuSystem treenumber,exititem
END IF
	junk=wind_get(0,WF_WORKXYWH,WindX,WindY,WindW,WindH)
'InitFileSelector
junk=wind_update(BEG_UPDATE)
'InitWindowSystem
'InitTextWindows
'InitObjectWindows
'ON ERROR GOTO error_handler
END SUB
	
SUB StopProgram
SHARED menutree&,images_used
STATIC junk
IF	images_used THEN CALL CloseAllImages
 IF menutree& THEN menu_bar menutree&,0
junk=wind_set(0,WF_NEWDESK,0,0,0,0)
junk=wind_update(END_UPDATE)

STOP -1
END SUB



'Debug routines for the tookbox
' displays the given srting using the BIOS

SUB AbortProgram(a$)
	Debug a$
	StopProgram
END SUB

SUB Debug(BYVAL a$)
STATIC i,t!
cconws a$
't!=timer
'do loop until timer-t!>3
junk=INP(2)
END SUB

FUNCTION aes_version
aes_version=PEEKW(PEEKL(GB+4))
END FUNCTION

skip:
' End of Goldfish
