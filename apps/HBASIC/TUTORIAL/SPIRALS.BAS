REM The Spirals program discussed in the
REM Tutorial chapter of the HiSoft BASIC 2
REM manual.

REM Move turtle forward by r.
sub fwd(r)
shared curx, cury, dir
static newx, newy
  newx=curx+r*cos(dir)
  newy=cury+r*sin(dir)
  linef curx, cury, newx, newy
  curx=newx
  cury=newy
end sub

REM Turn turtle clockwise through r degrees.
sub right(r)
shared dir
  dir=dir-r/180*3.1415926
end sub

REM The actual spiral routine.
sub spirals (L,A)
  fwd L
  right A
  if L<150 THEN spirals L+1,A
end sub

main:

REM Set this up for a particular screen size.
curx=160 : cury=100 : dir=0

spirals 9,95
