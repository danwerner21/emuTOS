' The Fast to HiSoft compiler ½ HiSoft 1987
'
' SCS
'
' 26 july	1.0
'

rem $option u,v,z				'underlines ok, variable checks, Zzzz mode
rem $option n-,a-,o-,p-			'max speed

library "gemaes","gemdos"		'these libraries are used

defint a-z

' the table of the simple replacement keywords Fast BASIC,HiSoft BASIC
'

data "ENDPROC","END SUB"
data "ENDIF","END IF"
data "REPEAT","DO"
data "UNTIL","LOOP UNTIL"
data "SWITCH","SELECT CASE"
data "ENDSWITCH","END SELECT"
data "HIDEMOUSE","MOUSE -1"
data "SHOWMOUSE","MOUSE 0"
data "DEFAULT","CASE ELSE"

data "BEGINUPDATE","Dummy%=FNwind_update%(1)"
data "ENDUPDATE","Dummy%=FNwind_update%(0)"
data "CREATEWIND","FNwind_create%"
data "FINDOBJECT","FNobjc_find%"
data "FINDWIND","FNwind_find%"
data "FSELECT","fsel_input"
data "GROWBOX","graf_growbox"
data "MOVEBOX","graf_movebox"
data "SHRINKBOX","graf_shrinkbox"
data "SLIDEBOX","FNgraf_slidebox%"
data "TRACKBOX","FNgraf_watchbox%"
data "WAITMSG","evnt_mesag"
data "WAITTIMER","evnt_timer"

data "DELDIR","RMDIR"
data "DELFILE","KILL"
data "DIR","FILES"
data "FREE",FRE("")
data "GETREC","GET"
data "HOME","LOCATE 1,1"
data "MAKEDIR","MKDIR"
data "PUTREC","PUT"
data "SETMOUSE","MOUSE"
data "INKEY","ASC(INKEY$)"
data "TIME24$(SYSTIME)","TIME$"
data "DATEUS$(SYSDATE)","DATE$"
data ""

if peekw(systab)=4 then
	dummy=FNform_alert(1,"[3][This doesn't run in|low res][ Quit ]")
	system
end if

crlf$=chr$(13)+chr$(10)				'various values
copyright$=chr$(189)


dim srcsym$(100)					'dimension the symbol tables
dim trgsym$(100)

do									'build the symbol tables
	read temp$
	if temp$="" then exit loop
	incr ctr
	srcsym$(ctr)=temp$
	read temp$
	trgsym$(ctr)=temp$
loop


nkey=ctr							'return what's not used
redim append srcsym$(nkey)
redim append trgsym$(nkey)

fil$=command$

m=peek(systab)						'get resolution
window open 2,"Fast BASIC to HiSoft BASIC converter "+copyright$+" HiSoft 1987",110,20\m,418,362\m,1

if len(fil$)=0 then					'no filename was specified on the cmdlin
	fil$=FNselect_file$
end if

do until fexists(fil$)				'if file not found
	but=FNform_alert(1,"[1][|  "+fil$+"  |  not found  ][  OK  ]")
	fil$=FNselect_file$
loop

mouse 2								'busybee

open fil$ for input as #1 len=5120	'open source with some buffer space

filel&=lof(1)

filst$=input$(filel&,#1)			'read entire file

close #1

dott=instr(fil$,".")
mid$(fil$,dott,4)=".BAS"			'create target's extension

open fil$ for output as #2 len=5120	'open target with some buffer space


mouse 0								'arrow

but=FNform_alert(1,"[2][| Do you want 16-bit or | 32-bit integers? ][  16  |  32  ]")

mouse -1							'no rodent (takes up too much time)

if but=1 then
	intflg=0
else
	intflg=1
end if

check_corrupt						'make sure all lines end with cr-lf

print #2,"' ";fil$;" converted from Fast BASIC to HiSoft BASIC"
print #2,"LIBRARY ""GEMAES"""

locate 9,21
print "line";

done=-1

fp&=1

nix&=fre("")

main:

do											'this is the main prog

	tokoffs=FNgetnxtok

	if done then

		if tokoffs=0 then
			print #2,notaword$;
		elseif tokoffs>0 then
			print #2,trgsym$(tokoffs);
		end if

		if hcfl then print #2,holdchr$;

	end if

	done=-1
	hcfl=0

loop


terminator:
close #2
mouse 0										'mouse is back
john=FNform_alert(1,"[1][|     All done!| |"+str$(lino)+" lines processed  ][  OK  ]")
stop -1										'exit


sub getnxlin								'get a line of Fast BASIC
shared parslin$,ll,lp,fp&,crlf$,filel&,filst$,lino
static cr&

	if fp& >= filel& then goto terminator	'(slap on wrist)
	cr&=instr(fp&,filst$,crlf$)
	parslin$=mid$(filst$,fp&,cr&-fp&)
	fp&=cr&+2
	incr lino
	if (lino and 7)=0 then					'don't always print (eats time)
		locate 9,25
		print lino;
	end if
	ll=len(parslin$)

	lp=0

end sub


DEF FNgetnxchr$								'get a character from the line
shared parslin$,word$,ll,lp,funcflag,nxchr$,wf,intflg,wl,hcfl,holdchr$
static quotct,nxchr,temp,chrfl,achr$

getachr:

	incr lp

	if lp > ll then exit def				'NOT EQUAL!

	chrfl=1
	hcfl=0

	nxchr=asc(mid$(parslin$,lp,1))		'get the next character as integer

	if nxchr=""""% then incr quotct			'smart quoted strings

	select case nxchr						'integer comparisons are quicker

		case " "%
			if wl<>0 then wf=1				'new word
			hcfl=-1
			holdchr$=chr$(nxchr)

		case 9								'tab
			print #2,chr$(9);
			chrfl=0

	end select

	if (quotct and 1)=1 then goto after_select

	select case nxchr

		case "%"%
			if intflg=1 then
				nxchr="&"%
			else
				nxchr="%"%
			end if

		case "\"%
			nxchr="'"%

		case "("%
			wf=1
			hcfl=-1
			holdchr$=chr$(nxchr)

		case "="%
			if funcflag=0 then
				if wl<>0 then
					wf=1
					hcfl=-1
					holdchr$=chr$(nxchr)
					exit select
				end if
			end if

			if funcflag=1 then					'it's the end of a DEF FN
				if wl=0 then
					exit select
					call spcase_endef
					chrfl=0
					exit def					'the routine did everything
				end if
			end if

		case "@"%
			call spcase_at
			exit def

		case "$"%
			if wl=0 then
				print #2,"&H";
				chrfl=0
			end if

		case "&"%
			nxchr="%"%

		case ":"%
			if wl<>0 then
				wf=1
				hcfl=-1
				holdchr$=chr$(nxchr)
			end if

		case "|"%
			nxchr="%"%
		
	end select

after_select:

if chrfl=0 then goto getachr

Fngetnxchr$=chr$(nxchr)

end def


DEF FNgetnxwrd$									'get a word
shared parslin$,lp,ll,wl,wf,xwf,xword$
static word$,nxchr$,temp$

	word$=""
	wl=0
	wf=0

	do
		nxchr$=FNgetnxchr$

		if xwf then
			word$=word$+xword$
			xwf=0
		end if

		if wf<>1 then

			word$=word$+nxchr$

			incr wl

			if wl=1 then						
			temp$=mid$(parslin$,lp,4)
				if temp$="PROC" then
					call spcase_proc
					exit def
				end if
			end if
			if lp >= ll then exit loop

		end if

	loop until wf=1

	if word$="DEF" then
		call spcase_defs
		exit def
	end if

	FNgetnxwrd$=word$

end def


DEF FNgetnxtok%									'see if it's a token
shared crlf$,lp,ll,srcsym$(),notaword$,done,nkey
static srch,word$,offs

	if lp >= ll then
		print #2,crlf$;
		call getnxlin
	end if

	word$=FNgetnxwrd$

	if not done then exit sub
	
	for srch=1 to nkey							'hunt through symbol table
		if word$=srcsym$(srch) then			'the most used line in the prog
			FNgetnxtok=srch
			exit def
		end if
	next srch

	FNgetnxtok=0

	notaword$=word$
	
end def

' all the special cases follow

sub spcase_defs
shared parslin$,ll,lp,wl,funcflag,done,funcname$
static temp$,nxchr$,rest$,name$,paren$,achr$

	temp$=mid$(parslin$,lp+1,2)

	if temp$="FN" then
		print #2,"DEF ";

		funcflag=1
		funcname$=""
		rest$=""
		
		do
			nxchr$=FNgetnxchr$

			if nxchr$="(" then					'the VAR business
				paren$="("

				do
					nxchr$=FNgetnxchr$

					achr$=mid$(parslin$,lp-1,1)
					if achr$="," or achr$="(" then
						if mid$(parslin$,lp,3)="VAR" then
							nxchr$=""
							lp=lp+3
						else
							paren$=paren$+"VAL "
						end if
					end if
					paren$=paren$+nxchr$

				loop until nxchr$=")"
				goto 42

			end if

			funcname$=funcname$+nxchr$
			if lp > ll then exit loop
		loop

42		print #2,funcname$+paren$;
		done=0

	else

		name$=""
		lp=lp+4									'skip over DEF

		do
			nxchr$=FNgetnxchr$

			if nxchr$="(" then					'the VAR business
				paren$="("

				do
					nxchr$=FNgetnxchr$

					achr$=mid$(parslin$,lp-1,1)
					if achr$="," or achr$="(" then
						if mid$(parslin$,lp,3)="VAR" then
							nxchr$=""
							lp=lp+3
						else
							paren$=paren$+"VAL "
						end if
					end if
					paren$=paren$+nxchr$

				loop until nxchr$=")"
				goto 43

			end if

			name$=name$+nxchr$
			if name$="PROC" then name$=""
			if lp > ll then exit loop
		loop

43		print #2,"SUB "+name$+paren$;
		done=0
	end if

end sub


sub spcase_endef
shared funcname$,ll,lp,parslin$,done,funcflag
static name$,nxchr$

	print #2,funcname$;
	name$=""
	do
		nxchr$=FNgetnxchr$
		if nxchr$=" " then
			exit loop
		elseif lp > ll then
			exit loop
		end if
		name$=name$+nxchr$
	loop
	print #2,"="+name$
	print #2,"END DEF";
	funcflag=0
	done=0

end sub


sub spcase_at
shared done,lp,ll,xwf,xword$
static nxchr$,name$

	xwf=0
	name$=""

	do
		nxchr$=FNgetnxchr$
	
		select case nxchr$

			case "$"
				name$=name$+"$"
dolloop:		nxchr$=FNgetnxchr$
				if nxchr$=")" or nxchr$=" " or nxchr$="," or lp > ll
					name$="SADD("+name$+")"+nxchr$
					xword$=name$
					xwf=-1
					exit sub
				else
					name$=name$+nxchr$
					goto dolloop
				end if

			case " "
				name$="VARPTR("+name$+") "
				xword$=name$
				xwf=-1
				exit sub
			
			case ")"
				name$="VARPTR("+name$+"))"
				xword$=name$
				xwf=-1
				exit sub

			case ","
				name$="VARPTR("+name$+"),"
				xword$=name$
				xwf=-1
				exit sub

		end select
		name$=name$+nxchr$

		if lp > ll
			name$="VARPTR("+name$+")"
			xword$=name$
			xwf=-1
			exit sub
		end if

	loop

end sub


sub spcase_proc
shared parslin$,lp,ll,done
static name$,word$,nxchr$

	name$=""

	lp=lp+3							'not 4 because getnxchr pre-increments

	do
		nxchr$=FNgetnxchr$
		if nxchr$=" " then
			exit loop
		elseif lp > ll then						'NOT EQUAL!
			exit loop
		end if
		name$=name$+nxchr$
	loop

	print #2,"CALL "+name$;

	if nxchr$=" " then print #2," ";

	done=0

end sub


sub check_corrupt						'occasionally Fast BASIC produces
shared filst$,filel&,holdst$,crlf$		'bad ASCII files
static nix&,hold&,where&

	locate 9,19
	print "having a think..."

	hold&=1

	do
		where&=instr(hold&,filst$,chr$(10))					'check for lf
		if where&=0 then exit loop
		hold&=where&+1

		if mid$(filst$,where&-1,1)<>chr$(13) then			'without cr
			holdst$=left$(filst$,where&-1)
			holdst$=holdst$+crlf$
			filst$=holdst$+right$(filst$,filel&-where&)
			holdst$=""
			filel&=len(filst$)
			nix&=fre("")
		end if

	loop

	cls											'lazy

end sub


DEF FNselect_file$
static path$,name$,but,drv$,where

	path$=space$(64)							'set up buffer
	drv$=chr$(FNdgetdrv+"A"%)					'get current drive
	dgetpath sadd(path$),0						'get current path
	if left$(path$,1)=chr$(0) then				'add *.ASC
		path$=drv$+":\*.ASC"
	else
		path$=drv$+":"+path$
		where=instr(path$,chr$(0))
		path$=left$(path$,where-1)
		path$=path$+"\*.ASC"
	end if
	
	fsel_input path$,name$,but					'the file selector appears!
	cls											'naughty naughty
	if but=0 then stop -1						'cancel button
	where=instr(path$,"*")						'build the file name
	path$=left$(path$,where-1)
	FNselect_file$=path$+name$

end def
