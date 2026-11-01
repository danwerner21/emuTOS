' Form window handling for HiSoft BASIC GEM Toolbox

SUB InitFormWindows
SHARED woCancelObj(1),woIdx(1),woCur_edit(1),woCloseForm&(1),FormWindowsInitialised,max_windows
REDIM  woCancelObj(max_windows),woIdx(max_windows),woCur_edit(max_windows),woCloseForm&(max_windows)
FormWindowsInitialised=-1
END SUB

SUB FormReDraw
SHARED commonx,commony,commonw,commonh,commonhandle
STATIC i,x,y,w,h
SHARED woObjectTree&(1),woOffX(1),woOffY(1),woBaseX(1),woBaseY(1),woCur_edit(1)

STATIC	oldtree&
	oldtree&=tree&
	i=WhichWindow(commonHandle)
	IF i=0 THEN EXIT SUB ' panic
	SelectTreeAddr woObjectTree&(i)
	junk=wind_get(CommonHandle,WF_CURRXYWH,x,y,w,h)

	Setob_x 0,woBaseX(i)-woOffX(i)+x
	Setob_y 0,woBasey(i)-woOffY(i)+y
	xobjc_draw 0,10,commonx,commony,commonw,commonh
	IF woCur_edit(i) THEN
		junk=wind_get(0,WF_TOP,x,0,0,0)
		IF x=CommonHandle THEN
			do_cursor x,1
		END IF
	END IF
	SelectTreeAddr oldtree&
END SUB

FUNCTION xobj_watch(BYVAL win,BYVAL obj)
STATIC x,y,w,h,ev,flag
junk=objc_offset(tree&,obj,x,y)
w=getob_width(obj)
h=getob_height(obj)
flag=1
DO
	ev=evnt_multi(MU_BUTTON+MU_M1,0,3,0,_
					flag,x,y,w,h,_
					0,x,y,w,h,_
					0,0,0,0,0,0,0,0)
	IF (ev AND MU_BUTTON) THEN
		EXIT DO
	ELSEIF (ev AND MU_M1) THEN
		IF flag THEN 
			exclob_state obj,mask_selected
		ELSE
			inclob_state obj,mask_selected
		END IF
	END IF
	flag=flag XOR 1
	Object_Redraw win,obj
LOOP
xobj_watch=curob_state(obj,mask_selected)
END FUNCTION

FUNCTION reset_radio(VAL win,VAL object)
STATIC first,last,parent,i
parent=getparent(object)
first=Getob_head(parent)
IF first=-1 THEN EXIT FUNCTION
last=getob_tail(parent)
i=first
DO
	IF i<>object AND curob_state(i,mask_selected)<>0 THEN 
		exclob_state i,mask_selected
		reset_radio=i
		EXIT FUNCTION
	END IF
	i=getob_next(i)
LOOP UNTIL i=parent
reset_radio=0
END FUNCTION

FUNCTION xform_button(BYVAL win,BYVAL obj,next_obj)
STATIC res,flags,state,tmp,selectable,radio,selected,deselect,exitable,touchexit
state=getob_state(obj)
flags=getob_flags(obj)
selectable=flags AND mask_selectable
radio=flags AND mask_rbutton
selected=state AND mask_selected
exitable=flags AND mask_exit
touchexit=flags AND mask_touchexit
next_obj=0
IF (state AND mask_disabled) OR (flags AND mask_hidetree) THEN
	xform_button=1
	EXIT FUNCTION
END IF
next_obj=0
deselect=0
res=-1
IF selectable THEN
	IF selected THEN
		IF radio=0 THEN exclob_state obj,mask_selected
	ELSE
		inclob_state obj,mask_selected
		IF radio THEN deselect=reset_radio(win,obj)
	END IF
	Object_Redraw win,obj
	IF deselect THEN Object_Redraw win,deselect
	IF exitable=0 AND touchexit=0 THEN
		junk=evnt_button(0,3,0,0,0,0,0)
	END IF
END IF
IF exitable<>0 AND selectable<>0 THEN
	tmp=xobj_watch(win,obj)
	IF tmp=0 THEN 
		xform_button=1
		EXIT FUNCTION
	END IF
END IF
IF flags AND mask_editable THEN
	next_obj=obj
END IF
IF exitable OR touchexit THEN
	next_obj=obj
	res=0
END IF
xform_button=res
END FUNCTION 

'this utility routine is for general use
'it should only be used to redraw a single object
SUB Object_Redraw(WindowHandle,BYVAL obj)
STATIC x1,y1,w1,h1,x,y,w,h,topwin
SHARED commonx,commony,commonw,commonh
objcextent obj,x,y,w,h
junk=wind_get(0,WF_TOP,topwin,0,0,0)
IF WindowHandle=topwin THEN
	junk=objc_draw(tree&,0,10,x,y,w,h)
	vs_clip 1,x,y,x+w-1,y+h-1
	show_cuts obj,0
ELSE
	junk=wind_get(WindowHandle,WF_FIRSTXYWH,x1,y1,w1,h1)
	WHILE (w1<>0) AND (h1<>0)
		IF MyInterSection(x,y,w,h,x1,y1,w1,h1,commonx,commony,commonw,commonh) THEN
			vs_clip 1,commonx,commony,commonx+commonw-1,commony+commonh-1
			junk=objc_draw(tree&,0,10,commonx,commony,commonw,commonh)
			show_cuts obj,0
		END IF
		junk=wind_get(WindowHandle,WF_NEXTXYWH,x1,y1,w1,h1)
	WEND
END IF
END SUB

'this utility routine should be used to redraw
'one object or more, it is not as fast as Object_Redraw
'but can redraw several objects in one go
SUB MultipleObjectRedraw(BYVAL win,BYVAL obj)
STATIC x,y,w,h
	objcextent obj,x,y,w,h
	redraw win,x,y,w,h
END SUB

FUNCTION FormClose
SHARED commoni,commonobj,wocancelobj(1),wocloseform&(1),woType(1)
SHARED commonclose,woObjectTree&(1)
STATIC j,oldtree&
IF woType(commoni)<> woTform THEN FormClose=-1: EXIT FUNCTION
oldtree&=tree&
SelectTreeAddr woObjectTree&(commoni)
IF commonobj=-1 THEN commonobj=woCancelobj(commoni)
IF curob_flags(commonobj,mask_exit) THEN
	Exclob_state commonobj,mask_selected
END IF
commonclose=-1
CALLS wocloseForm&(commoni)
commonobj=-1
FormClose=commonclose
SelectTreeAddr oldtree&
END FUNCTION

SUB FormDelete
SHARED commoni,wocancelobj(1),Howmanywindows
SHARED woCloseForm&(1),woObjectTree&(1),woBaseX(1),woBaseY(1),woCancelObj(1),woCur_edit(1),woidx(1)
STATIC j
FOR j=commoni TO HowManyWindows
	woCloseForm&(j)=woCloseForm&(j+1)
	woObjectTree&(j)=woObjectTree&(j+1)
	woBaseX(j)=woBaseX(j+1)
	woBaseY(j)=woBaseY(j+1)
	woCancelObj(j)=woCancelObj(j+1)
	woCur_edit(j)=woCur_edit(j+1)
	woIdx(j)=woIdx(j+1)
NEXT j

END SUB

FUNCTION Gette_ptmplt$(BYVAL object)
STATIC t&,a$
a$=""
t&=Getob_spec&(object)
t&=PEEKL(t&+te_ptmplt)
WHILE PEEKB(t&)
	a$=a$+CHR$(PEEKB(t&))
	INCR t&
WEND
Gette_ptmplt$=a$
END FUNCTION

FUNCTION getcur_offset(BYVAL obj,BYVAL idx)
STATIC tmp$,curspos
tmp$=(gette_ptmplt$(obj))
curspos=INSTR(tmp$,"_")-1+idx
getcur_offset=curspos*8
END FUNCTION

SUB do_cursor(BYVAL win_handle,BYVAL mode)
SHARED woCur_edit(),woIdx(),woObjectTree&()
STATIC x1,y1,w1,h1,i
i=WhichWindow(win_Handle)
IF woCur_edit(i) THEN
	SelectTreeAddr woObjectTree&(i)
	objcextent wocur_edit(i),x1,y1,w1,h1
	x1=x1+getcur_offset(wocur_edit(i),woidx(i))
	junk=objc_draw(tree&,0,10,x1,y1-3,1,h1+6)
	IF mode THEN junk=objc_edit(tree&,woCur_edit(i),0,woIdx(i),3)
END IF
END SUB

' 	As OpenAWindow except the Object Tree whose Address is given by
'	p  is always - rather than a specific redraw routine. This will
'	handle scroll events
FUNCTION OpenFormWindow(WindowName$,BYVAL WindComp,BYVAL treeno,BYVAL startobj,BYVAL cancelobj,BYVAL Closeproc&)
STATIC WindowHandle,oldtree&
SHARED woObjectTree&(1),woBaseX(1),woBaseY(1),forms_enabled
SHARED woType(1),HowManyWindows,ObjectWindowsInitialised,FormWindowsInitialised
STATIC WindowHandle,t$
STATIC x,y,w,h,id,x1,y1
SHARED WindX,WindY,WindW,WindH,HowManyWindows,WindowsInitialised,max_windows
SHARED woHandle(1),woRedraw&(1),woSliderMax&(1),woClose&(1)
SHARED woType(1),woOffx(1),woOffy(1),woCloseForm&(1),woCancelObj(1),woCur_edit(1),woidx(1)

	IF WindowsInitialised=0 THEN CALL InitWindowSystem
	IF ObjectWindowsInitialised=0 THEN  CALL InitObjectWindows
	IF FormWindowsInitialised=0 THEN CALL InitFormWindows
	IF HowManyWindows=max_windows THEN
		CALL NoMoreWindows
		EXIT SUB
	END IF
	SelectTree treeno
	form_center tree&,x1,y1,w,h
	x1=byte_align(x1)
	setob_x 0,x1
	junk=wind_calc(0,WindComp,x1,y1,w,h,x,y,w,h)
'Find an unused BASIC window id
	id=0
	DO WHILE VARPTR(#257+id)
		INCR id
	LOOP
' OK we can use BASIC window id - we will get a runtime error if
' this doesn't work.
	graf_mouse 256,0

	WINDOW OPEN id,WindowName$,x,y,w,h,WindComp
	
	INCR HowManyWindows
	
	WINDOW READ id,5,WindowHandle	'read the AES handle
	woHandle(HowManyWindows)=WindowHandle
	woRedraw&(HowManywindows)=VARPTRS(FormRedraw)
	woSliderMax&(HowManyWindows)=VARPTRS(ObjectSliderMax)
	woClose&(HowManyWindows)=VARPTRS(FormDelete)
	woCloseForm&(HowManyWindows)=closeproc&
	woType(HowManyWindows)=woTform
	woObjectTree&(HowManyWindows)=tree&
	woOffX(HowManyWindows)=0
	woOffy(HowManyWindows)=0

	woBaseX(HowManyWindows)=x1-x
	woBaseY(HowManyWindows)=y1-y
	woCancelObj(HowManywindows)=cancelobj
	IF startobj THEN
		t$=gette_ptext$(startobj)
		IF LEFT$(t$,1)="@" THEN woidx(HowManyWindows)=0 ELSE woidx(HowManyWindows)=LEN(t$)
	END IF

	graf_mouse 257,0
	woCur_edit(HowManywindows)=startobj
	forms_enabled=-1	
	OpenFormWindow=WindowHandle

END FUNCTION

SUB move_cursor(idx,BYVAL obj,BYVAL xpos,BYVAL new)
STATIC curs_pos,chars,t$,objx,old_obj,new_idx
IF curob_flags(obj,mask_editable)=0 THEN EXIT SUB
junk=objc_offset(tree&,obj,objx,junk)
curs_pos=objx+getcur_offset(obj,idx)
new_idx=Idx+(xpos-curs_pos)/8
t$=gette_ptext$(obj)
IF LEFT$(t$,1)="@" THEN chars=0 ELSE chars=LEN(t$)
new_idx=MAX(0,MIN(new_idx,chars))
IF obj=old_obj AND idx=new_idx THEN
	EXIT SUB
ELSE

	old_obj=obj
END IF
IF NOT new THEN junk=objc_edit(tree&,obj,0,Idx,3)
idx=new_idx
junk=objc_edit(tree&,obj,0,Idx,3)
END SUB

FUNCTION ProcessFormClicks(byval button,BYVAL clicks,BYVAL kstate,BYVAL x,BYVAL y)
SHARED woType(1),woObjectTree&(1),tree&,commonobj
SHARED woCancelObj(1),woIdx(1),woCur_edit(1),woclose&(1)
STATIC cur_win,cur_wind,cont,new_edit,oldtree&,cur_front
	cur_win=wind_find(x,y)
	cur_wind=WhichWindow(cur_win)
	IF woType(cur_wind)<> woTform THEN EXIT FUNCTION
	oldtree&=tree&
	SelectTreeAddr woObjecttree&(cur_wind)
	cont=-1
	new_edit=objc_find(tree&,0,10,x,y)
	IF button=1 or curob_flags(new_edit,mask_editable)<>0 THEN				
		junk=wind_get(0,WF_TOP,cur_front,junk,junk,junk)
		IF cur_win<>cur_front THEN
			SelectTreeAddr oldtree&
			EXIT FUNCTION
		END IF
	END IF
	IF new_edit=-1 THEN 
		new_edit=0
	ELSE
		cont=xform_button(cur_win,new_edit,new_edit)
		IF new_edit=wocur_edit(cur_wind) THEN
			move_cursor woIdx(cur_wind),new_edit,x,0
		END IF
	END IF
	IF (cont<>0) AND (new_edit<>0 AND new_edit<>wocur_edit(cur_wind)) THEN
		junk=objc_edit(tree&,wocur_edit(cur_wind),0,woIdx(cur_wind),3)
	END IF
	IF cont=0 THEN
		commonobj=new_edit
		CloseAwindow cur_win
		commonobj=-1
	ELSE
		IF new_edit<>0 AND wocur_edit(cur_wind)<>new_edit THEN
			wocur_edit(cur_wind)=new_edit
			move_cursor woIdx(cur_wind),new_edit,x,-1
			new_edit=0
		END IF

	END IF
	SelectTreeAddr oldtree&
END FUNCTION


FUNCTION ProcessFormKey(BYVAL key_pressed,BYVAL kstate)
SHARED woType(1),woObjectTree&(1),commonobj
SHARED woExit_obj(1),woIdx(1),woCur_edit(1),wocancelobj(1)
STATIC cur_front,cur_wind,cont,new_edit,oldtree&
STATIC old_curpos
	ProcessFormkey=0
	junk=wind_get(0,WF_TOP,cur_front,junk,junk,junk)
	cur_wind=WhichWindow(cur_front)
	IF woType(cur_wind)<> woTform THEN EXIT FUNCTION
	oldtree&=tree&
	SelectTreeAddr woObjecttree&(cur_wind)
	cont=-1
	IF kstate=8 OR key_pressed=&h6100 THEN
		new_edit=formcuts(key_pressed,woCancelObj(cur_wind))
		if new_edit then ProcessFormKey=-1
		IF new_edit THEN cont=xform_button(cur_front,new_edit,new_edit)
	ELSE
		cont=xform_keybd(wocur_edit(cur_wind),kstate,new_edit,key_pressed,woIdx(cur_wind))
		IF key_pressed THEN
			old_curpos=woIdx(cur_wind) 
			junk=objc_edit(tree&,wocur_edit(cur_wind),key_pressed,woIdx(cur_wind),2)
			IF old_curpos<>woIdx(cur_wind) THEN ProcessFormKey=-1
		END IF
	END IF


	IF (cont<>0) AND (new_edit<>0 AND new_edit<>wocur_edit(cur_wind)) THEN
		junk=objc_edit(tree&,wocur_edit(cur_wind),0,woIdx(cur_wind),3)
	END IF
	IF  cont=0 THEN
		commonobj=new_edit
		CloseAwindow cur_front
		commonobj=-1
	ELSE
		IF new_edit<>0 AND wocur_edit(cur_wind)<>new_edit THEN
			wocur_edit(cur_wind)=new_edit
			junk=objc_edit(tree&,new_edit,0,woIdx(cur_wind),1)
			new_edit=0
		END IF

	END IF
	SelectTreeAddr oldtree&
END FUNCTION	


SUB KeyboardEvent(BYVAL key_pressed,BYVAL kstate)
SHARED menus_enabled,keys_enabled,forms_enabled
	IF forms_enabled THEN
		IF ProcessFormKey(key_pressed,kstate) THEN EXIT SUB
	END IF
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
END SUB

'The New Toolbox's main loop
SUB xHGTloop
STATIC ev,key_pressed,clicks,x,y,kstate,button
STATIC mclicks,mmask,mstate
SHARED finished_flag,Mess(1),clicks_enabled,keys_enabled,menus_enabled,forms_enabled
 REDIM mess(7)
SHARED mouse_detect_both
IF mouse_detect_both THEN
	mclicks=258
	mmask=3
	mstate=0
ELSE
	mclicks=2
	mmask=1
	mstate=1
END IF	

 finished_flag=0
 DO
	junk=wind_update(END_UPDATE)
	ev=evnt_multi(MU_MESAG+MU_KEYBD+MU_BUTTON,mclicks,mmask,mstate, _
			0,0,0,0,0,_
			0,0,0,0,0,_
			VARPTR(mess(0)),0,_
			x,y, _
			button,kstate, _
			key_pressed,clicks)
	junk=wind_update(BEG_UPDATE)

	IF ev AND MU_KEYBD THEN	KeyboardEvent key_pressed,kstate
	IF ev AND MU_MESAG THEN
		do_message
	END IF
	IF ev AND MU_BUTTON THEN
		IF forms_enabled THEN
			IF NOT ProcessFormClicks(button,clicks,kstate,x,y) THEN
				IF clicks_enabled THEN 	ProcessClicks clicks,kstate,x,y
			END IF
		ELSE
			IF clicks_enabled THEN 	ProcessClicks clicks,kstate,x,y
		END IF
	END IF
 LOOP UNTIL finished_flag
END SUB
