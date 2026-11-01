defint a-z
CONST eofch=-1

'DECLARE SUB getch CDECL
SUB getch
SHARED ch,source$,sx&
IF sx&<=LEN(source$) THEN
	ch=ASC(MID$(source$,sx&,1))
	INCR sx&
ELSE
	ch=eofch
END IF

END SUB

input "enter filename:";filename$
open filename$ for input as #1
DIM freq(255)
source$=INPUT$(LOF(1),1)
sx&=1
DO
	getch
 	IF ch=eofch THEN EXIT LOOP
 	INCR freq(ch)
LOOP
FOR i=0 TO 255
	PRINT i;TAB(6);
	IF i>32 THEN PRINT CHR$(i);
	PRINT ,freq(i)
NEXT i
	
CLOSE #1
