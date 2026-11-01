' The Towers of Hanoi program in HiSoft BASIC

' Doesn't work too well in low res

LIBRARY "gemvdi"

REM $option V

DEFINT a-z

CONST max_rings=25
CONST left=1,middle=2,right=3
CONST pole1=110,pole2=320,pole3=530
CONST space=50
CONST max_width=200
CONST gap=10

full_height=400\peekw(systab)			'mono or medium-rez only

DIM SHARED highest(3)

SUB draw_ring(which_pole,size,type,start)
SHARED ring_height,full_height
STATIC xstart,ystart

VSF_INTERIOR type

SELECT CASE which_pole
	CASE=1
		xstart=pole1-(size)\2
	CASE=2
		xstart=pole2-(size)\2
	CASE=3
		xstart=pole3-(size)\2
END SELECT

ystart=full_height-space-start*ring_height

IF type=0 THEN
  VR_RECFL xstart,ystart,xstart+size,ystart+ring_height-2
ELSE
  V_BAR xstart,ystart,xstart+size,ystart+ring_height-2
END IF	  
		  
END SUB

SUB realmove(val source, val destination)
SHARED poles(2)
STATIC ring_width,ystart

ring_width=poles(source,highest(source))

'erase source ring
draw_ring source,ring_width,0,highest(source)

poles(source,highest(source))=0
DECR highest(source)

'draw destination ring
INCR highest(destination)
poles(destination,highest(destination))=ring_width
VSF_STYLE highest(destination)

draw_ring destination,ring_width,2,highest(destination)

END SUB

SUB move(val howmany, val source, val work, val destination)
    IF howmany<=1 THEN
       realmove source,destination
    ELSE
       move howmany-1,source,destination,work
       realmove source,destination
       move howmany-1,work,source,destination
    END IF
END SUB

'The actual start
DO
    LOCATE 1,2
	INPUT "Number of rings to move: ",num_rings
LOOP UNTIL num_rings>1 AND num_rings<=max_rings

ring_height=(full_height-2*space)\max_rings

MOUSE -1						'turn mouse off
WINDOW OPEN 2,"The Towers of Hanoi in HiSoft BASIC",0,18,640,full_height-18,1

VSF_COLOR 1

DIM SHARED poles(3,num_rings)

'initialise first pole
FOR i=1 TO num_rings
	poles(1,i)=max_width-(i-1)*(max_width\num_rings)
NEXT i

FOR i=1 TO num_rings
	VSF_STYLE(i)
	highest(1)=i
	draw_ring 1,poles(1,i),2,highest(1)
NEXT i

tm!=TIMER

move num_rings,left,middle,right

print num_rings;"rings moved in";TIMER-tm!;"seconds"
