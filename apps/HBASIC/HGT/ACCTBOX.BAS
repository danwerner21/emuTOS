' HiSoft BASIC GEM Toolkit
' Desk accessory version
DEFINT a-z
	GOTO	skip
' 10k should be plenty to Leave, variable checks on, no window
REM $option y+,v+,u+,#,[,]
'  constant file for HiSoft BASIC
' use defint a-z and option u+
' end of GEMAES.BH
'  constant file for HiSoft BASIC
' use defint a-z and option u+
rem $include gemaes.bh

LIBRARY "gemaes","gemvdi","xbios","gemdos"

DIM SHARED junk

' This is the main toolkit itself
' (c) HiSoft 1991
' written by Dave Nutkins

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

'icnludes a given mask (e.g. mask_selectable,mask_exit) from the ob_flags
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

' If Busy is true (non-zero) then  makes the rodent busy
SUB BusyBee(BYVAL Busy)
 IF Busy THEN
	graf_mouse 2,0
 ELSE
	graf_mouse 0,0
 END IF
END SUB


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

DECLARE SUB AccOpened
' process message event
SUB do_message
STATIC cur_front,MessageType,title,item
SHARED exit_item,Finished_Flag,Mess(1),AlreadyOpen
	MessageType=Mess(0)
'	Debug STR$(Mess(0))+STR$(Mess(1))+STR$(Mess(2))+STR$(Mess(3))
	IF (MessageType>=WM_TOPPED) AND (MessageType<=WM_MOVED) THEN
		IF NOT IsMyWindow(Mess(3)) THEN EXIT SUB ' it's not our's
 	END IF
	junk=wind_get(Mess(3),WF_TOP,cur_front,junk,junk,junk)
 	SELECT CASE MessageType
	CASE AC_OPEN:
		WINDOW SYSTEM
 		AccOpened
 		AlreadyOpen=-1
 	CASE WM_CLOSED: 
 		CloseAWindow mess(3)
		AlreadyOpen=0
		WINDOW STOP
	CASE ELSE
		WindowMessage
		
	END SELECT
END SUB


SUB StartAccessory(daname$)
SHARED WindX,WindY,WindW,WindH
SHARED Mess(1)
STATIC id,mpos
DIM Mess(7)
id=PEEKW(PEEKL(GB+4)+4)
mpos=menu_register(id,daname$)
junk=wind_get(0,WF_WORKXYWH,WindX,WindY,WindW,WindH)

DO
	evnt_mesag VARPTR(mess(0))
	do_message
LOOP
END SUB



'Debug routines for the tookbox
' displays the given srting using the BIOS

SUB AbortProgram(a$)
	Debug a$
	STOP -1
END SUB

SUB Debug(BYVAL a$)
STATIC i
FOR i=1 TO LEN(a$)
OUT 2,ASC(MID$(a$,i,1))
NEXT i
junk=INP(2)
END SUB

FUNCTION aes_version
aes_version=PEEKW(PEEKL(GB+4))
END FUNCTION


skip:
' End of Goldfish
