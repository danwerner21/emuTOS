REM A general version of the GEM example
REM in the HiSoft BASIC 2 manual.
REM This should work in any resolution.

defint a-z
library "gemvdi"

REM Length of the box, depth (skew) and letter height
const length=50,skew=20,ch_height=32

b$="HiSoft BASIC 2"

dim ch(7)

'REM Draws a 3D box with top left at (x,y)
'REM and places the letter ch$ in the centre

SUB draw_box (BYVAL x,BYVAL y,BYVAL ch$)
LOCAL pts(11)
shared ch_x,ch_y

	pts(0)=x : pts(1)=y
	pts(2)=x+skew : pts(3)=y-skew
	pts(4)=x+length+skew : pts(5)=y-skew
	pts(6)=x+length+skew : pts(7)=y+length-skew
	pts(8)=x+length : pts(9)=y+length
	pts(10)=x : pts(11)=y+length

	v_fillarea 6,pts()

	pts(2)=x+length : pts(3)=y
	pts(4)=x+length+skew : pts(5)=y-skew
	v_pline 3,pts()

	pts(0)=x+length : pts(1)=y+length
	v_pline 2,pts()

	v_gtext x+(length-ch_x)/2, y+(length+ch_y)/2, ch$

end sub

REM Initialisation. Works out the window size and
REM sets up global variables accordingly.
REM Also works out the character height and therefore
REM where to position the b_string string.
sub init
STATIC xmax, ymax, wx, wy, ww, wh, b_width, b_height
local ch(7)
shared xstart, ystart, b_x, b_y, ch_x, ch_y, b$

	WINDOW GET 2,1,wx,wy,ww,wh
	xmax=ww-wx : ymax=wh-wy
	xstart=xmax/2-(2*length+length/6+skew)/2
	ystart=ymax/2

	vsf_color 1
	vsf_interior 0
	vst_height ch_height

	vqt_extent "A",ch()
	ch_y=ch(7)-ch(1)
	ch_x=ch(2)-ch(0)

	b_width=len(b$)*ch_x
	b_height=ch_y
	b_x=xmax/2-b_width/2
	b_y=ystart+length+3*b_height/2

end sub

REM Initialise variables etc.
init

REM Draw 3 boxes with B, C and A in them.
draw_box xstart,ystart,"B"
draw_box xstart+7*length/6,ystart,"C"
draw_box xstart+7*length/12,ystart-7*length/6,"A"

REM Draw the title string.
v_gtext b_x,b_y,b$
