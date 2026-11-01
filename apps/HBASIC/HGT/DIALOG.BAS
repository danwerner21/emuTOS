
' an additional GEM call is needed as the built-in form_alert expects a
' BASIC-style string, not a pointer to a C-type string
FUNCTION newform_alertaddr(BYVAL button,BYVAL addr&)
	POKEW PEEKL(GB+8),button	'int_in
	POKEL PEEKL(GB+16),addr&	'addr_in
	GEMSYS(52)
	newform_alertaddr=PEEKW(PEEKL(GB+12))		'int_out!
END FUNCTION

FUNCTION Newform_alert(BYVAL num,BYVAL button)
STATIC junk,alertaddr&
junk=rsrc_gaddr(type_string,num,alertaddr&)
junk=Newform_alertAddr(button,alertaddr&)
Newform_Alert=junk
END FUNCTION

' a general routine to produce a dialog box and handle interaction
' the return result is the exit object number
FUNCTION HandleDialog(BYVAL editnum)
STATIC x,y,w,h,but
form_center tree&,x,y,w,h
form_dial FMD_START,0,0,0,0,x,y,w,h
form_dial FMD_GROW,x+w\2,y+h\2,0,0,x,y,w,h
junk=objc_draw(tree&,0,10,x,y,w,h)
but=form_do(tree&,editnum) AND &h7fff
form_dial FMD_SHRINK,x+w\2,y+h\2,0,0,x,y,w,h
form_dial FMD_FINISH,0,0,0,0,x,y,w,h
IF Getob_type(but)=G_BUTTON THEN
	Exclob_state but,mask_selected
END IF
HandleDialog=but
END FUNCTION

'Set a tedinfo field to a numeric value
SUB SetTedNumber(BYVAL object,BYVAL value#)
Sette_ptext object,MID$(STR$(value#),2)
END SUB

'Return a numeric value from a tedinfo field
FUNCTION GetTedNumber#(BYVAL object)
GetTedNumber#=VAL(Gette_ptext$(object))
END FUNCTION

' select a particular radio button in a group
SUB SetButton(BYVAL parent,BYVAL button)
STATIC b,t&
b=Getob_head(parent)		'head object number
DO UNTIL b=parent
	IF b=button THEN
		Inclob_state b,mask_selected
	ELSE
		Exclob_state b,mask_selected
	END IF
	b=Getob_next(b)
LOOP
END SUB

' return which button of a group is selected
FUNCTION GetButton(BYVAL parent)
STATIC b
b=Getob_head(parent)		'head object number
DO UNTIL (b=parent) OR Curob_state(b,mask_selected)
	b=Getob_next(b)
LOOP
GetButton=b
END FUNCTION
