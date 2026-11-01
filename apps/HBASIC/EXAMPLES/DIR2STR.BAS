' this is an example of GEMDOS library usage. ½ HiSoft 1987
' the sub-program copies the filenames of files in the given directory
' into a string
'
' SCS
'
' updated for version 2 Oct 91 djn

REM $option v									'variable checks on
REM $option #+									'No FNs in libraries
DEFINT a-z
LIBRARY "gemdos"

DIM SHARED dta(22)								'our DTA


DO												'the main program
	INPUT path$
	IF LEN(path$)=0 THEN STOP -1				'just hit return to quit
	dirstr$=""
	dir2str path$,dirstr$
	PRINT dirstr$
LOOP

'returns in targstr$ a list of files
SUB dir2str(BYVAL pathstr$,targstr$)
STATIC isitthere,olddta&,addr&,hold

	olddta&=fgetdta&							'get the old dta

	fsetdta VARPTR(dta(0))						'this is where we want it

	isitthere=fsfirst(pathstr$,0)				'look for the file

	IF isitthere>=0 THEN						'some files available

		DO
			addr&=VARPTR(dta(15))
			DO									'look for null byte
				hold=PEEKB(addr&)
				IF hold=0 THEN EXIT LOOP
				targstr$=targstr$+CHR$(hold)
				INCR addr&
			LOOP

			targstr$=targstr$+CHR$(13)+CHR$(10)		'add cr-lf

			isitthere=fsnext
		LOOP UNTIL  isitthere<0 					'is there another file
	END IF
	fsetdta olddta&								'if not restore dta and exit
END SUB
