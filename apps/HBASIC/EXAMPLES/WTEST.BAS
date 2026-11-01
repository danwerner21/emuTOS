' WERCS example program for HiSoft BASIC 2
' this does not use the HiSoft GEM Toolkit
DEFINT a-z

' 10k should be plenty to Leave, variable checks on, no window
' No FNs in libraries
REM $option l10,v+,y+,u+,#+

LIBRARY "gemaes"

' the GEMAES.BH file must be accessable
REM $INCLUDE GEMAES.BH

' get the header file created with WERCS
REM $INCLUDE WRSC.BH

' global variables
DIM SHARED junk,deskflag,menu&,finished,checked
DIM SHARED screenx,screeny,screenw,screenh,edit$,radio

FUNCTION object&(BYVAL tree&,BYVAL object)
object&=tree&+object*ob_sizeof
END FUNCTION

' an additional GEM call is needed as the built-in form_alert expects a
' BASIC-style string, not a pointer to a C-type string
FUNCTION newform_alert(BYVAL button,BYVAL addr&)
	POKEW PEEKL(GB+8),button	'int_in
	POKEL PEEKL(GB+16),addr&	'addr_in
	GEMSYS(52)
	newform_alert=PEEKW(PEEKL(GB+20))
END FUNCTION

SUB INITIALISE
' firstly load the resource file
IF rsrc_load("WRSC.RSC")=0 THEN
	' this alert can't be in the resource file of course..
	junk=form_alert(1,"[3][Resource file error][ Quit ]")
	SYSTEM
END IF

' now install the menu
deskflag=0
junk=rsrc_gaddr(type_tree,Menu1,menu&)
menu_bar menu&,1

' get the screen size
junk=wind_get(0,WF_WORKXYWH,screenx,screeny,screenw,screenh)

graf_mouse 0,0

' set default values for dialog box
edit$=""
radio=DRadio1
END SUB

' set or reset the desktop pattern
SUB SETDESK(BYVAL newdesk&)
junk=wind_set(0,wf_newdesk,PEEKW(VARPTR(newdesk&)),PEEKW(VARPTR(newdesk&)+2),0,0)
' cause the AES to re-draw the whole screen
form_dial FMD_FINISH,0,0,0,0,screenx,screeny,screenw,screenh
END SUB

SUB DEINITIALISE
IF deskflag THEN SETDESK(0) : deskflag=0
menu_bar menu&,0
junk=rsrc_free
END SUB


' a general routine to produce a dialog box and handle interaction
' the return result is the exit object number
FUNCTION handle_dialog(BYVAL d&,BYVAL editnum)
STATIC x,y,w,h,but,t&
form_center d&,x,y,w,h
form_dial FMD_START,0,0,0,0,x,y,w,h
form_dial FMD_GROW,x+w\2,y+h\2,0,0,x,y,w,h
junk=objc_draw(d&,0,10,x,y,w,h)
but=form_do(d&,editnum)
form_dial FMD_SHRINK,x+w\2,y+h\2,0,0,x,y,w,h
form_dial FMD_FINISH,0,0,0,0,x,y,w,h
t&=object&(d&,but)
IF PEEKB(t&+ob_type+1)=G_BUTTON THEN
	POKEW t&+ob_state,PEEKW(t&+ob_state) AND (NOT mask_selected)
END IF
handle_dialog=but
END FUNCTION

' set a tedinfo record
' NOTE: does not handle complex templates
SUB set_tedinfo(BYVAL tree&,BYVAL object,BYVAL newted$)
STATIC t&,maxl,i
t&=PEEKL(tree&+object*ob_sizeof+ob_spec)
maxl=PEEKW(t&+te_txtlen)-1					'-1 for the null
IF LEN(newted$)<maxl THEN maxl=LEN(newted$)
t&=PEEKL(t&)
FOR i=1 TO maxl
	POKEB t&,ASC(MID$(newted$,i,1))
	INCR t&
NEXT i
POKEB t&,0									'must end in null
END SUB

' extract a tedinfo record
' NOTE: does not handle complex templates
FUNCTION get_tedinfo$(BYVAL tree&,BYVAL object)
STATIC t&,a$
a$=""
t&=PEEKL(tree&+object*ob_sizeof+ob_spec)
t&=PEEKL(t&)
WHILE PEEKB(t&)
	a$=a$+CHR$(PEEKB(t&))
	INCR t&
WEND
get_tedinfo$=a$
END FUNCTION

' select a particular radio button in a group
SUB set_button(BYVAL tree&,BYVAL parent,BYVAL button)
STATIC b,t&
b=PEEKW(object&(tree&,parent)+ob_head)		'head object number
DO UNTIL b=parent
	t&=object&(tree&,b)+ob_state
	POKEW t&,PEEKW(t&) AND (NOT mask_selected)		'unlite it
	IF b=button THEN POKEW t&,PEEKW(t&) OR mask_selected	'lite special one
	b=PEEKW(object&(tree&,b)+ob_next)
LOOP
END SUB

' return which button of a group is selected
FUNCTION get_button(BYVAL tree&,BYVAL parent)
STATIC b
b=PEEKW(object&(tree&,parent)+ob_head)		'head object number
DO UNTIL b=PARENT
	IF PEEKW(object&(tree&,b)+ob_state) AND mask_selected THEN
		get_button=b: EXIT FUNCTION
	ELSE
		b=PEEKW(object&(tree&,b)+ob_next)
	END IF
LOOP
END FUNCTION

' a routine to handle a particular dialog box
SUB test_dialog
STATIC dlog&,result
junk=rsrc_gaddr(type_tree,TestDialog,dlog&)
set_tedinfo dlog&,DEditable,edit$
set_button dlog&,DParent,radio
result=handle_dialog(dlog&,DEditable)
IF result=DOK THEN
	edit$=get_tedinfo$(dlog&,DEditable)
	radio=get_button(dlog&,DParent)
END IF
END SUB

' handle a given menu click
SUB handle_menu(BYVAL title,BYVAL item)
STATIC temp&
SELECT CASE item
	=MAbout
		junk=rsrc_gaddr(type_string,AAlert,temp&)
		junk=newform_alert(1,temp&)
	=MQuit
		finished=1
	=MCheckme
		checked=checked XOR 1
		menu_icheck menu&,MCheckme,checked
	=MDialog
		test_dialog
	=MInstall
		IF deskflag THEN
			deskflag=0
			SETDESK 0			'reset it
		ELSE
			deskflag=1
			junk=rsrc_gaddr(0,NewDesktop,temp&)
			POKEW temp&+ob_x,screenx: POKEW temp&+ob_y,screeny
			POKEW temp&+ob_width,screenw: POKEW temp&+ob_height,screenh
			SETDESK temp&
		END IF
END SELECT
menu_tnormal menu&,title,1		'restore to normal state
END SUB

' the main loop of the application, the procedure ends when Quit
' is selected
SUB MAIN
LOCAL mess(7),event
finished=0: checked=0
DO
evnt_mesag VARPTR(mess(0))		'we can avoid the dreaded evnt_multi!
event=mess(0)
SELECT CASE event
	=MN_SELECTED : handle_menu mess(3),mess(4)
' a complete program would have other cases here
END SELECT
LOOP UNTIL finished
END SUB


' the main program starts here

INITIALISE
MAIN
DEINITIALISE
SYSTEM


' that's all folks
