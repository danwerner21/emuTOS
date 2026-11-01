'$option q80,y
'$include toolbox.bas
'$include menu.bas
'$include objcext.bas
'$include xformdo.bas
'$include window.bas
'$include objwind.bas
'$include formwind.bas
'$include popup.bas

'$INCLUDE popdemo.BH

SUB processusermenus(VAL topwin,VAL item,VAL title)
SHARED myhandle
STATIC res
SELECT CASE item
	CASE mpop
		IF myhandle THEN
			TopAWindow myhandle
		ELSE
			myhandle=openformwindow(" Pop... ",&h0B,dialog,0,ok_but,VARPTRS(close_dialog))
		END IF
	CASE mabout
		junk=form_alert(1,"[0][ Popup module demo | by Ofir Gal ][ OK ]")
END SELECT
END SUB

FUNCTION get_pop_text$(BYVAL poptree,BYVAL popobj)
STATIC oldtree&
oldtree&=tree&
selecttree poptree
get_pop_text$=RTRIM$(LTRIM$(getob_spec$(popobj)))
tree&=oldtree&
END FUNCTION

SUB close_dialog
SHARED commonclose,myhandle,commonobj
STATIC x,y,res$,res
commonclose=0										
SELECT CASE commonobj
	CASE=pop_but
		junk=objc_offset(tree&,pop_but,x,y)		'find object position
		res=popup(0,models_form,res,x,y)			'do the pop
		IF res THEN 									'if there was a result
			res$=get_pop_text$(models_form,res)	'get the text
			sette_ptext pop_but,res$				'display it in the main dialog
			setob_scut pop_but,LEFT$(res$,1)		'change the keybd shortcut
		END IF
	CASE=ok_but
		commonclose=-1
		myhandle=0
END SELECT
IF commonclose=0 THEN Object_Redraw myhandle,commonobj
END SUB

startprogram "POPDEMO.RSC",menu1,mquit
xHGTloop
stopProgram
