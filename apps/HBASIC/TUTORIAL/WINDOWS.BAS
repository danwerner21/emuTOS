DEFINT a-z

' Get the position, width and height of the free
' window that HiSoft BASIC gives you.

WINDOW GET 2,1,wx,wy,ww,wh

' Re-locate and name the free window you get
' when running a HiSoft BASIC GEM program.
' This always has id number 2.

WINDOW LOCATE 2,wx,wy,ww,wh\2
WINDOW NAME 2,"Top window"

' Set up shaded (5,2) fill pattern for the ellipse.
COLOR 1,1,1,5,2

' Draw an ellipse in window 2.
PELLIPSE ww\2,wh\5,ww\3,wh\6

' Open another window: id number is 1, top left is
' below the other window, in the centre of the screen.
' The 1+512+1024+2048 means the window has:
' a title bar, left & right arrows and a
' horizontal slider.

WINDOW OPEN 1,"Another window",wx+ww\4,wy+wh\2,ww\2,wh\2,1+512+1024+2048

' Print something novel in window id 1!
PRINT "Welcome to HiSoft BASIC 2"

' Set horizontal slider of the bottom window halfway.
WINDOW CONTRL 1,0,500

' Set the horizontal slider size to be fairly small.
WINDOW CONTRL 1,2,100
