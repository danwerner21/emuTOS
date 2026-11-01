' $option b
' this program uses the operating system libraries to copy a single
' sided disk from drive a: to drive B:
' the following three lines specify the libraries which are needed
' ½ HiSoft 1987
'
' SCS
'

library "BIOS","XBIOS"

defint a-z

cls
locate 1,14
print "Disk Copier ";chr$(189);" HiSoft 1987 - written in HiSoft BASIC";
locate 3,19
print "copies a single sided disk from A: to B:";

srcd=0							'source drive number
trgd=1							'target drive number

gfm:
locate 5,28
print "format target (y/n): ";
ans$=inkey$
if ans$=="y" then
	dim fmtbuf(4608)			'dimension the format buffer
	print ans$;
	fm=1
elseif ans$=="n" then
	print ans$;
	fm=0
else
	goto gfm
end if

wpr:
frmem&=fre("")					'figure out how many tracks can be buffered
frmem&=frmem&-5120
ttb&=frmem&\4608
if ttb&>81 then ttb&=81
ttbi&=(ttb&*2304)

dim trkbuf(ttbi&)				'this is the buffer

locate 10,21
print "insert source in A: and target in B:";

ere1:
locate 14,28
print "hit any key to continue";

repeat getkey					'use the BIOS to check if a key was pressed
	if FNbconstat(2)=-1 then exit getkey
end repeat getkey

nix&=FNbconin&(2)		'make sure no characters are buffered; call BIOS

locate 14,28
print string$(23,32)

strk=0
etrk=ttb&-2

do

	elf&=0						'the current array element
	for trk=strk to etrk		'the loop to read as much of the disk
		rdtrk trk,elf&			'as memory allows
		elf&=elf&+2308			'update element counter
	next trk

	elf&=0
	for trk=strk to etrk		'writes contents of buffer
		if fm=1 then fmtrk trk	'format track if so desired
		wrtrk trk,elf&
		elf&=elf&+2308
	next trk

	if etrk=79 then exit loop

	strk=etrk+1					'next set of tracks
	etrk=strk+ttb&-2
	if etrk>79 then etrk=79

loop

locate 14,28
print string$(23,32);
locate 14,37
nix=FNbconout(2,27)
nix=FNbconout(2,"p"%)
print "DONE!";
nix=FNbconout(2,27)
nix=FNbconout(2,"q"%)
end

sub rdtrk(tct,el&)
shared errno,srcd,trkbuf(1)

	locate 14,28
	print "   reading track";tct;
	errno=FNfloprd(varptr(trkbuf(el&)),srcd,1,tct,0,9)	'XBIOS floprd call
	if errno<0 then call errorhndl
end sub


sub fmtrk(tct)
shared errno,trgd,fmtbuf(1)

	locate 14,28
	print "formatting track";tct;" ";
	errno=FNflopfmt(varptr(fmtbuf(0)),0,trgd,9,tct,0,1)	'XBIOS flopfmt call
	if errno<0 then call errorhndl
end sub

sub wrtrk(tct,el&)
shared errno,trgd,trkbuf(1)

	locate 14,28
	print "   writing track";tct;" ";
	errno=FNflopwr(varptr(trkbuf(el&)),trgd,1,tct,0,9)	'XBIOS flopwr call
	if errno<0 then call errorhndl
end sub

sub errorhndl
shared errno

	locate 14,30
	print string$(3,32);
	nix=FNbconout(2,27)
	nix=FNbconout(2,"p"%)
	print "TOS error ";abs(errno);" ";
	nix=FNbconout(2,27)
	nix=FNbconout(2,"q"%)
	stop

end sub
