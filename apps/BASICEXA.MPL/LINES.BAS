WINDOW NAME 2,"LINES DEMO"
WINDOW GET 2,0,wx%,wy%,ww%,wh%
PRINT "WX: "; wx%; "WY: ", wy%
PRINT "WW: "; ww%; "WH: ", wh%
WHILE INKEY$ = ""
    X1% = INT(RND * ww%)
    Y1% = INT(RND * wh%)
    X2% = INT(RND * ww%)
    Y2% = INT(RND * wh%)
    C% = INT(RND * 15)
    COLOR 0,0,C%
    LINEF X1%,Y1%,X2%,Y2%
WEND