 
'Menu short cut routines for the tool box
CONST MaxShortCut=100


SUB Record(BYVAL a,BYVAL c,BYVAL o,BYVAL t)
SHARED scShortCuts,scascii(1),scch(1),scobj(1),sctitle(1)
	INCR scShortCuts
	IF scShortCuts>MaxShortCut THEN
' Error no room for shortcuts
		DECR scShortCuts
	ELSE
		scascii(scShortCuts)=a
		scobj(scShortCuts)=o
		scch(scShortCuts)=c
		sctitle(scShortCuts)=t
	END IF
END SUB

SUB ConsiderString(BYVAL obj,BYVAL title,BYVAL st$)
SHARED scspecval(1),scspec$(1),scspcount
STATIC i,j,l,modifier,ch
	i=LEN(st$)
	IF i<1 THEN EXIT SUB
	IF RIGHT$(st$,1)=" " THEN st$=LEFT$(st$,i-1):DECR i
	IF i<3 THEN EXIT SUB
' Now check the named keys
	FOR j=1 TO scspcount
		l=LEN(scspec$(j))
		IF i>l+2 THEN
			IF RIGHT$(st$,l)=scspec$(j) THEN
				Record 1,scspecval(j),obj,title
				EXIT SUB
			END IF
		END IF
	NEXT j

	modifier=ASC(MID$(st$,i-1,1))
	ch=ASC(UCASE$(RIGHT$(st$,1)))
	SELECT CASE modifier
	CASE " "%,1:	Record -1,ch,obj,title
	CASE "^"%:		Record -1,ch-&h40,obj,title
	CASE 7:			Record 0,ch,obj,title
	END SELECT

END SUB

SUB RecordSpecial(a$,BYVAL ScanCode)
SHARED scspec$(1),scspecval(1),scspcount
INCR scspcount
scspec$(scspcount)=a$
scspecval(scspcount)=ScanCode
END SUB

SUB ScanMenu
SHARED menutree&,scShortCuts,tree&,scspec$(1),scspecval(1),scspcount
SHARED scascii(1),scch(1),scobj(1),sctitle(1)
STATIC obj,title,oldtree&,typ,i
REDIM scspecval(29),scspec$(29)

	scspcount=0
	RecordSpecial "Help",&h6200
	RecordSpecial "Undo",&h6100
	RecordSpecial "BS",&hE08
	RecordSpecial "Del",&h537F
	RecordSpecial "Esc",&h011b
	RecordSpecial "Ins",&h5200
	RecordSpecial "Home",&h4700
	RecordSpecial "Clr",&h4737
	RecordSpecial "Tab",&h0f09
	FOR i=1 TO 10
		RecordSpecial "F"+CHR$(i+"0"%),&h3A00+&h100*i
		RecordSpecial CHR$(1)+"F"+CHR$(i+"0"%),&h5300+&h100*i
	NEXT i
	REDIM scascii(MaxShortCut),scch(MaxShortCut),scobj(MaxShortCut),sctitle(MaxShortCut)

	oldtree&=tree&
	SelectTreeAddr menutree&
	obj=0
	scShortCuts=0
	title=1
	DO
		typ=Getob_type(obj)
		SELECT CASE typ
		CASE G_TEXT:
			ConsiderString obj,title,Gette_ptext$(obj)
		CASE G_STRING:
			ConsiderString obj,title,Getob_spec$(obj)
		CASE G_BOX:
			INCR title
		END SELECT
		IF Curob_flags(obj,mask_lastob) THEN EXIT LOOP
		INCR obj
	LOOP
END SUB

FUNCTION CreateShortCut(BYVAL Scancode)
SHARED scShortCuts,scascii(1),scch(1),sctitle(1),scobj(1),Mess(1)
STATIC ch,i,Altcode
	ch=Scancode MOD 256
	Altcode=ConvertAlt(ScanCode)
 	FOR i=1 TO scShortCuts
		IF (scascii(i)=-1 AND scch(i)=ch) _
		OR (scascii(i)=0 AND ch=0 AND altcode=scch(i)) _
		OR (scascii(i)=1 AND Scancode=scch(i)) THEN
				CreateShortCut=-1
				Mess(0)=MN_SELECTED
				Mess(3)=sctitle(i)
				Mess(4)=scobj(i)
				EXIT FUNCTION
		END IF
	NEXT i
	CreateShortCut=0
END FUNCTION

'Initialise the menu system to use the the given treenumber
'from the resource file. exititem gives the umber of the item
'that will cause termination
SUB InitMenuSystem(BYVAL treenumber,BYVAL exititem)
SHARED menutree&,exit_item,menus_enabled
junk=rsrc_gaddr(0,treenumber,menutree&)
menu_bar menutree&,1
exit_item=exititem
menus_enabled=-1
ScanMenu
END SUB
