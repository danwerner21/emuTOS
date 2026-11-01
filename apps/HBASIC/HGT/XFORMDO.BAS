'needs toolbox.bas

' Returns the object number of this object's parent or -1 if it is the root
FUNCTION GetParent(VAL index)
STATIC nextindex
	IF Index=0 THEN
		GetParent=-1
	ELSE
		DO
			nextindex=Getob_next(index)
			IF Getob_tail(nextindex)=index THEN EXIT LOOP
			index=nextindex
		LOOP
		GetParent=nextindex
	END IF
END FUNCTION

' returns TRUE if PossChild is a child (or the same as) Parent
'	in tree ObjTree.
FUNCTION IsChild(VAL parent, VAL PossChild)
STATIC current
IF parent=0 THEN ischild=-1:EXIT FUNCTION
	current=PossChild
	DO
		IF current=parent THEN
			IsChild=-1
			EXIT LOOP
		END IF
		current=GetParent(current)
		IF current<0 THEN
			IsChild=0
			EXIT FUNCTION
		END IF
	LOOP
END FUNCTION


FUNCTION too_deep(BYVAL start,BYVAL obj,BYVAL depth)
STATIC how_deep
IF depth=10 OR depth=0 THEN 
	too_deep=0
	EXIT FUNCTION
END IF
how_deep=0
DO
	obj=getparent(obj) 
	INCR how_deep
LOOP UNTIL obj=-1 OR obj=start
IF how_deep>depth THEN too_deep=-1 ELSE too_deep=0
END FUNCTION

'work out which objects need underlines
SUB show_cuts(BYVAL object,BYVAL depth)
STATIC i,type,flags
SHARED sysfont_h,sysfont_w
graf_mouse 256,0
junk=graf_handle(sysfont_w,sysfont_h,0,0)
i=object
DO
	type=getob_type(i)
	flags=getob_flags(i)
	IF type AND &hFF00 THEN										'it's xtended type
		IF flags AND (mask_selectable OR mask_exit OR mask_touchexit) THEN 	'if it selectable,exit...
			IF (flags AND mask_hidetree)=0 THEN				'and not hidden
				IF NOT too_deep(object,i,depth) THEN		'if obj depth is within requested depth
					IF ischild(object,i) THEN work_underline i,type	'underline it
				END IF
			END IF
		END IF
	END IF
INCR i
LOOP UNTIL depth=0 OR (flags AND mask_lastob)
graf_mouse 257,0
END SUB

' extract a te_just record
FUNCTION Gette_just(BYVAL object)
STATIC t&
t&=Getob_spec&(object)
gette_just=PEEKW(t&+te_just)
END FUNCTION

' extract a te_font record
FUNCTION Gette_font(BYVAL object)
STATIC t&
t&=Getob_spec&(object)
gette_font=PEEKW(t&+te_font)
END FUNCTION

'workout location for underline
SUB work_underline(BYVAL obj,BYVAL type)
STATIC x,y,w,h,text$,chpos,text_w,char_h,char_w,x2,just,ch_x,ascii
SHARED sysfont_h,sysfont_w
ascii=type\256														'this is the ascii code
type=type AND &hFF												'clean type
char_h=sysfont_h:char_w=sysfont_w							'char dimension
IF type=G_BUTTON OR type=G_STRING THEN						'get text string in object
	text$=getob_spec$(obj)
ELSEIF type=G_TEXT OR type=G_BOXTEXT THEN
	text$=gette_ptext$(obj)
	IF gette_font(obj)=5 THEN char_h=6:char_w=6			'if small font change char dimensions
ELSE
	EXIT SUB
END IF
junk=objc_offset(tree&,obj,x,y)								'get objct co-ordinates
w=getob_width(obj)	
h=getob_height(obj)
text_w=LEN(text$)*char_w										'text width
chpos=INSTR(UCASE$(text$),UCASE$(CHR$(ascii)))			'find char in objct
IF chpos THEN														'if found
	ch_x=(chpos-1)*char_w										'find x offset of char
	IF type=G_BUTTON THEN
		x=x+(w-text_w)\2+ch_x
	ELSEIF type=G_TEXT OR type=G_BOXTEXT THEN
		just=gette_just(obj)
		SELECT CASE just
			CASE=2:x=x+(w-text_w)\2+ch_x
			CASE=0:x=x+ch_x
			CASE ELSE:x=x+w-text_w+ch_x
		END SELECT
	ELSEIF type=G_STRING THEN
		x=x+ch_x
	END IF
	y=y+(h-char_h)\2+char_h-1									'find y
	IF (getob_flags(obj) AND mask_3d)=fl3dact THEN 
		IF aes_version>=&h340 THEN DECR x					'activator
	END IF
	x2=x+char_w-1
	draw_underline obj,x,y,x2
END IF
END SUB

SUB draw_underline(BYVAL obj,BYVAL x1,BYVAL y1,BYVAL x2)
STATIC p()
REDIM p(3)
p(0)=x1:p(1)=y1:p(2)=x2:p(3)=y1
IF Curob_state(obj,mask_selected) THEN
	vsl_color 0
	IF (getob_flags(obj) AND mask_3d)=fl3dact THEN 
		IF aes_version>=&h340 THEN vsl_color 1 
	END IF
ELSE 
	vsl_color 1
END IF
v_pline 2,p()
END SUB

FUNCTION xform_keybd(BYVAL cur_edit,BYVAL kstate,new_edit,kr,idx)
STATIC valid$,nkr
SELECT CASE kr
	CASE=&h4b34		'shift+left
		junk=objc_edit(tree&,cur_edit,kr,idx,3)
		idx=0
		junk=objc_edit(tree&,cur_edit,kr,idx,3)
		kr=0
		xform_keybd=1
	CASE=&h4d36		'shift+right
		junk=objc_edit(tree&,cur_edit,kr,idx,3)
		junk=objc_edit(tree&,cur_edit,kr,idx,1)
		kr=0
		xform_keybd=1
	CASE ELSE
		IF kr=&h5032 OR kr=&h4838 THEN kr=kr AND &hFF00			'shift+up/down cursor fix
		IF kr=&h0f09 AND (kstate AND 3) THEN kr=&h0f00			'backtab
		xform_keybd=form_keybd(tree&,0,cur_edit,kr,new_edit,kr)
END SELECT
END FUNCTION

SUB xobjc_change(BYVAL object,BYVAL x,BYVAL y,BYVAL w,BYVAL h,BYVAL newstate,BYVAL flag)
junk=objc_change(tree&,object,x,y,w,h,newstate,flag)
vs_clip 1,x,y,w,h
IF flag THEN show_cuts object,0
END SUB

SUB xobjc_draw(BYVAL object,BYVAL depth,BYVAL x,BYVAL y,BYVAL w,BYVAL h)
STATIC inf()
REDIM inf(5)
junk=objc_draw(tree&,object,depth,x,y,w,h)
vql_attributes inf()
vsl_type 1:vswr_mode 1:vsl_ends 0,0:vsl_width 1
IF x>0 AND y>0 AND w>0 AND h>0 THEN vs_clip 1,x,y,x+w-1,y+h-1
show_cuts object,depth
'vs_clip 0,0,0,0,0
vsl_type inf(0):vsl_color inf(1):vswr_mode inf(2)
vsl_ends inf(3),inf(4):vsl_width inf(5)
END SUB	

'there was an alt+keypress, check if any object fits
FUNCTION formcuts(BYVAL keypress,BYVAL undo_obj)
STATIC i,xtype,ascii
IF keypress=&h6100 THEN 
	formcuts=undo_obj
	EXIT FUNCTION
END IF
ascii=convertalt(keypress AND &hFF00)
FOR i=1 TO 255
	xtype=getob_type(i)\256
	IF ascii=xtype THEN 
		formcuts=i
		EXIT FOR
	ELSE formcuts=0
	END IF
	IF curob_flags(i,mask_lastob) THEN EXIT FOR
NEXT i
END FUNCTION

FUNCTION xform_do(BYVAL new_edit,BYVAL exit_obj,button)
STATIC cont,cur_edit,idx,ev,x,y,br,kr,kstate
STATIC mclicks,mmask,mstate,old_edit
SHARED mouse_detect_both
junk=wind_update(1)
junk=wind_update(3)
IF mouse_detect_both THEN
	mclicks=258
	mmask=3
	mstate=0
ELSE
	mclicks=2
	mmask=1
	mstate=1
END IF	
cont=1
old_edit=0
cur_edit=0
WHILE cont
	IF new_edit<>0 AND cur_edit<>new_edit THEN
		cur_edit=new_edit
		new_edit=0
		junk=objc_edit(tree&,cur_edit,0,idx,1)
	END IF
	ev=evnt_multi(mu_keybd+mu_button,mclicks,mmask,mstate,_
							0,0,0,0,0,_
							0,0,0,0,0,_
							0,0,_
							x,y,button,kstate,kr,br)
	IF ev AND mu_keybd THEN
		IF kstate=8 OR kr=&h6100 THEN
			new_edit=formcuts(kr,exit_obj)
			old_edit=new_edit
			IF new_edit THEN cont=form_button(tree&,new_edit,br,new_edit)
		ELSE
			cont=xform_keybd(cur_edit,kstate,new_edit,kr,idx)
			IF kr THEN junk=objc_edit(tree&,cur_edit,kr,idx,2)
		END IF
	END IF
	IF ev AND mu_button THEN
		new_edit=objc_find(tree&,0,10,x,y)
		IF new_edit=-1 THEN 
			BEEP		
			new_edit=0
		ELSE
			old_edit=new_edit
			cont=form_button(tree&,new_edit,br,new_edit)
		END IF
	END IF
	IF (NOT cont AND (new_edit<>0 AND new_edit<>cur_edit)) THEN
		junk=objc_edit(tree&,cur_edit,0,idx,3)
	END IF
	IF old_edit THEN
		IF getob_type(old_edit) AND &hFF00 THEN
			IF curob_flags(old_edit,mask_rbutton) THEN 
				old_edit=getparent(old_edit)
			END IF
			show_cuts getparent(old_edit),10
		END IF
	END IF
WEND
junk=wind_update(2)
junk=wind_update(0)
xform_do=new_edit
END FUNCTION

' a general routine to produce a dialog box and handle interaction
' the return result is the exit object number
' button will contain the button state on exit
' if the global variable mouse_detect_both is non-zero
FUNCTION xHandleDialog(BYVAL editnum,BYVAL exit_obj,button)
STATIC x,y,w,h,but
form_center tree&,x,y,w,h
form_dial FMD_START,0,0,0,0,x,y,w,h
'form_dial FMD_GROW,x+w\2,y+h\2,0,0,x,y,w,h
xobjc_draw 0,10,x,y,w,h
but=xform_do(editnum,exit_obj,button) AND &h7fff
'form_dial FMD_SHRINK,x+w\2,y+h\2,0,0,x,y,w,h
form_dial FMD_FINISH,0,0,0,0,x,y,w,h
IF curob_state(but,mask_selected) THEN
	Exclob_state but,mask_selected
END IF
xHandleDialog=but
END FUNCTION

'sets the keyboard shortcut for an object
SUB Setob_scut(BYVAL object,BYVAL ch$)
POKEB ObjectAddr&(object)+ob_type,ASC(UCASE$(ch$))
END SUB
