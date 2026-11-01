FUNCTION popable(BYVAL obj)
STATIC disabled,hidden
disabled=curob_state(obj,mask_disabled)	
hidden=curob_flags(obj,mask_hidetree)		
IF (NOT (disabled OR hidden)) THEN 
	popable=-1
ELSE
	popable=0
END IF
END FUNCTION

FUNCTION pop_keybd(BYVAL k,finished_pop)
STATIC last_obj,sel_obj
last_obj=0
sel_obj=0
DO
	INCR last_obj
	IF curob_state(last_obj,mask_selected) THEN sel_obj=last_obj
LOOP UNTIL curob_flags(last_obj,mask_lastob)
SELECT CASE k
	CASE &h5000
		INCR sel_obj
		IF NOT popable(sel_obj) THEN INCR sel_obj
	CASE &h4800
		DECR sel_obj
		IF NOT popable(sel_obj) THEN DECR sel_obj
	CASE &h1C0D:finished_pop=-1
	CASE &h6100:pop_keybd=-1:finished_pop=-1:EXIT FUNCTION
	CASE &h4700:sel_obj=1
	CASE &h4737:sel_obj=last_obj
END SELECT
sel_obj=MAX(1,MIN(sel_obj,last_obj))
pop_keybd=sel_obj
END FUNCTION

SUB DeselectObject(BYVAL obj)
STATIC state
state=getob_state(obj)
junk=objc_change(tree&,obj,0,0,0,0,state AND (NOT mask_selected),1)
END SUB

SUB SelectObject(BYVAL obj)
STATIC state
state=getob_state(obj)
junk=objc_change(tree&,obj,0,0,0,0,state OR mask_selected,1)
END SUB

SUB objc_rect(BYVAL obj,x,y,w,h)
junk=objc_offset(tree&,obj,x,y)
w=getob_width(obj)
h=getob_height(obj)
END SUB

FUNCTION do_popup(BYVAL old_obj)
STATIC mx,my,new_obj
STATIC objx,objy,objw,objh,ev,k,finished_pop
STATIC boxx,boxy,boxw,boxh,mu_flag,flag2
finished_pop=0
new_obj=old_obj
IF old_obj THEN 
	objc_rect old_obj,objx,objy,objw,objh
ELSE
	objw=0:objh=0
END IF
objc_rect 0,boxx,boxy,boxw,boxh
mu_flag=MU_M2
flag2=0
DO
	ev=evnt_multi(MU_BUTTON+mu_flag+MU_KEYBD,257,3,0,_
											1,objx,objy,objw,objh,_
											flag2,boxx,boxy,boxw,boxh,_
											0,0,_
											mx,my,0,0,k,0)
	IF ev AND MU_KEYBD THEN new_obj=pop_keybd(k,finished_pop)
	IF ev AND MU_M2 THEN
		flag2=flag2 XOR 1
		mu_flag=mu_flag XOR MU_M1
		IF flag2 THEN
			objw=0:objh=0
		ELSE
			IF old_obj THEN
				DeselectObject old_obj
				old_obj=0
			END IF
		END IF
	END IF
	IF ev AND MU_M1 THEN 
		new_obj=objc_find(tree&,0,10,mx,my)
		IF new_obj>0 THEN objc_rect new_obj,objx,objy,objw,objh
	END IF
	IF ev AND MU_BUTTON THEN
		IF flag2=0 THEN new_obj=-1 
		finished_pop=-1
	END IF
	IF new_obj<>old_obj AND new_obj>0 THEN
		IF popable(new_obj) THEN
			SelectObject new_obj
			IF old_obj THEN
				DeselectObject old_obj
			END IF
			old_obj=new_obj
		ELSE
			new_obj=0
		END IF
	END IF
LOOP UNTIL finished_pop
IF old_obj THEN exclob_state old_obj,mask_selected
IF new_obj>0 THEN
	do_popup=new_obj
ELSE
	do_popup=0
END IF
junk=evnt_button(0,3,0,0,0,0,0)		'wait for button release
END FUNCTION

FUNCTION popup(BYVAL wind_handle,BYVAL treenum,BYVAL oldpop,BYVAL x,BYVAL y)
STATIC w,h,pop,oldtree&,winx,winy,winw,winh,top,hcell,button
STATIC dskx,dsky,dskh,dskw,x1,y1,w1,h1,add&
'junk=evnt_button(0,3,0,0,0,0,0)		'wait for button release
junk=wind_update(1)							
junk=wind_update(3)
junk=wind_get(0,WF_WORKXYWH,dskx,dsky,dskw,dskh)
IF wind_handle THEN
	junk=wind_get(wind_handle,WF_WORKXYWH,winx,winy,winw,winh)
	intersection dskx,dsky,dskw,dskh,winx,winy,winw,winh,x1,y1,w1,h1
ELSE
	x1=dskx:y1=dsky:w1=dskw:h1=dskh
END IF
oldtree&=tree&
selecttree treenum
IF oldpop THEN 
	inclob_state oldpop,mask_checked+mask_selected
	junk=graf_handle(junk,hcell,junk,junk)
	y=y-((oldpop-1)*hcell)
END IF
w=getob_width(0)+4
h=getob_height(0)+4
IF x+w>x1+w1 THEN
	x=x1+w1-w-1
ELSEIF x<x1 THEN 
	x=x1
END IF
IF y+h>y1+h1 THEN
	y=y1+h1-h-1
ELSEIF y<y1 THEN
	y=y1
END IF
x=byte_align(x)
setob_x 0,x
setob_y 0,y
DECR x:DECR y
save_scr x,y,w,h,1
junk=objc_draw(tree&,0,10,x,y,w,h)
pop=do_popup(oldpop)
exclob_state oldpop,mask_checked
IF pop THEN
	exclob_state pop,mask_selected
ELSE
	pop=oldpop
END IF
save_scr x,y,w,h,0
popup=pop
tree&=oldtree&
junk=wind_update(2)
junk=wind_update(0)
END FUNCTION

SUB save_scr(BYVAL x,BYVAL y,BYVAL w,BYVAL h,BYVAL mode)
STATIC p,size&,tmp(),quick
x=MAX(x,0)				'winx allows negative values
IF mode THEN
	p=PEEKW(SYSTAB)
	size&=2*(h+1)*((w+1)\16+1)+6
	IF size&\2*p<malloc&(-1) THEN 
		quick=-1
		REDIM tmp(size&*p)
		GET (x,y)-(x+w,y+h),tmp
	ELSE
		quick=0
		form_dial FMD_START,0,0,0,0,x,y,w,h
	END IF
ELSE
	IF quick THEN
		PUT(x,y),tmp,PSET
		ERASE tmp
	ELSE
		form_dial FMD_FINISH,0,0,0,0,x,y,w,h
	END IF
END IF
END SUB
