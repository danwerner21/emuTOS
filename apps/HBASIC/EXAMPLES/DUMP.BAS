rem Dumps out a file in hex and ASCII
rem following line turns pause & break checks on
rem $option pb

deflng l,p,t	' define long integers
defint a,i		' define integers

' returns a two-digit hex string given an integer
def fnbhex$(h%)
local a$
a$=hex$(h%): if len(a$)=1 then a$="0"+a$
fnbhex$=a$
end def

' returns an 8-digit hex string given a long integer
def fnlhex$(h&)
local a$
a$=hex$(h&): fnlhex$=string$(8-len(a$),"0"%)+a$
end def


' the actual program
f$=command$
print "DUMP ";chr$(189);" HiSoft 1987 compiled in HiSoft BASIC"

repeat main
if f$="" then input "Filename, ? for DIR, or [Return] to quit";f$
if f$="" then
	stop -1				'return without waiting
elseif f$="?" then
	files				'get a directory
elseif not fexists(f$) then
	print "Error: Cannot find file ";f$
else
	open "i",#2,f$,2000
	l=lof(2)
	p=0
		repeat lineloop
		t=16: if p+16>l then t=l-p
		print fnlhex$(p);" ";
		a$=input$(t,#2)
		for i=1 to t
			print fnbhex$(asc(mid$(a$,i,1)));" ";
		next i
		print tab(58);
		for i=1 to t
			if asc(mid$(a$,i,1))>31 then
				print mid$(a$,i,1);
				else
				print ".";
			end if
		next i
		print
		p=p+16: if p>l then exit lineloop
		end repeat lineloop
		close #2
end if
f$=""
end repeat main
