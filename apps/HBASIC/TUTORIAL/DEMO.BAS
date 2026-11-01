REM A Demonstration Program showing screen blitting in HiSoft BASIC 2

' Run the program, then use the mouse to select a section of the
' picture, by clicking on the top left and dragging down and to
' the right. The section will spin round the screen. Press any key to
' pause it, or Ctrl-C to break out
' needs medium or high res

library "gemaes","gemvdi","xbios"

rem $option b+		' break checks on (Ctrl-C)
defint a-z			' define integers as default

CONST transparent=2

window	off			' program controls events not BASIC 
window fullw : cls	' make GEM window fill screen
dim g(17000)		' for the image

res=peekw(systab)	' get screen resolution
if res=4 then
	dummy=form_alert(1,"[3][This doesn't run in|low res][ Quit ]")
	system
end if

screen_height=400\res
screen_width=640

GrabRect g(),w,h	' grab an image

if res=1 then
	ch=13
	margin=136	'120
	ystep=20
else
	ch=6
	margin=134	'118
	ystep=15
end if

vst_height ch

cls
vswr_mode transparent


' write out the HiSoft BASIC messages on the side of the screen
for i=ystep to screen_height step ystep
	if i mod 2*ystep then
		vst_effects 2	'light intensity i.e. grey
	else
		vst_effects 0	'normal intensity
		v_rbox 0,i-ystep,margin-5,i ' rounded rectangle
	end if
	v_gtext 10,i-5,"HiSoft BASIC 2"	' the text
next i

	vst_effects 0	'back to normal

mouse -1			' hide mouse

' now rotate the image around the screen

xradius=(screen_width-w-margin)\2
yradius=(screen_height-h-18)\2

a$="                  Compiled with HiSoft BASIC 2        Press SPACE for options"
show_text a$

repeat forever
	for theta!=0 to 2*3.14159 step 0.1
	put (xradius+margin+xradius*cos(theta!),yradius+yradius*sin(theta!)),g,pset
	if inkey$=" " then call checkstop
	next theta!
end repeat forever

SUB checkstop STATIC
local click,bl
mouse 0			' show mouse, arrow form
click=form_alert(1,"[3][ |Blitter Demo Program][ Quit | On | Off ]")
select on click
	=1: system
	=2: bl=blitmode(-1) AND 2		'bl=non zero if blitter attached
		if bl then
			bl=blitmode(1)
		else
			click=form_alert(1,"[1][ |Sorry, no blitter!][ Shame ]")
		end if
	=3:	bl=blitmode(0)
end select

mouse -1		' hide mouse
END SUB


' this loads a screen image, and lets you select it
' it returns the result in the array, together with the
' width and height

SUB GrabRect(image%(1),w%,h%)
SHARED res,text_x,text_y
STATIC x,y,a

mouse -1				' hide mouse
if res=2 then
	BLOAD "\tutorial\jackmed.scr",logbase&	' load picture
else
	BLOAD "\tutorial\jack.scr",logbase&		' load picture
end if

show_text "Select an area by clicking and dragging"
mouse 4					' mouse=hand
a= Evnt_button(1,1,1,x,y,0,0)			' wait for single click on left
Graf_Rubberbox x,y,10,10,w,h			' and select a box
linef x,y,x+w,y: linef x+w,y,x+w,y+h	' draw a box around it
linef x+w,y+h,x,y+h: linef x,y+h,x,y	' using ST BASIC graphic calls
get (x,y)-(x+w,y+h),image%		' and Grab it

END SUB

SUB show_text(a$)
SHARED screen_height,screen_width
STATIC x
LOCAL junk(7)

vqt_extent a$,junk()
x=(screen_width-junk(2)-junk(0))\2
v_gtext x,screen_height-2,a$

END SUB
