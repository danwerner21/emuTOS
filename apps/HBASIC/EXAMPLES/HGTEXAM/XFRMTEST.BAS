'$include toolbox.bas
'$include window.bas
'$include menu.bas
'$include xformdo.bas
'$option y,k100
'$INCLUDE xfrmtest.BH

mouse_detect_both=-1

startprogram "xfrmtest.rsc",menu4,menu_quit
hgtloop
stopprogram

SUB processusermenus(VAL wind,VAL item,VAL mtitle)
STATIC a$
SELECT CASE item
	CASE=m_test1
		CALL do_box
	CASE=m_info
		a$="[0][ Xform_do demo ][ OK ]"
		junk=form_alert(1,a$)
END SELECT
END SUB

SUB do_box
STATIC obj,button,a,x,y,w,h
selecttree form1
form_center tree&,x,y,w,h
form_dial FMD_START,0,0,0,0,x,y,w,h
xobjc_draw 0,10,0,0,0,0
junk=wind_update(1)
DO
	obj=xform_do(obj1,but2,button)
	IF obj=num_but THEN
		a=VAL(gette_ptext$(num_but))
		IF button=2 THEN INCR a ELSE DECR a
		IF a<0 THEN 
			a=0
		ELSEIF a>999 THEN 
			a=999
		END IF
		sette_ptext num_but,LTRIM$(STR$(a))
		xobjc_draw num_but,0,0,0,0,0
	END IF
LOOP UNTIL obj=but1 OR obj=but2
junk=wind_update(0)
form_dial FMD_FINISH,0,0,0,0,x,y,w,h
exclob_state obj,mask_selected
END SUB

