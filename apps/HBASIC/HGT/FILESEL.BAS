
' File selector handler - returns a new pathname
' the global variables fspath$ and fsname$ keep the appropriate
' GEM items.
FUNCTION FileSelect$
SHARED fspath$,fsname$,fsmessage$
STATIC ok,i,ch
IF fspath$="" THEN CALL InitFileSelector
IF aes_version<&H130 THEN
	fsel_input fspath$,fsname$,ok
ELSE 
	fsel_exinput fspath$,fsname$,ok,fsmessage$
END IF
IF ok THEN
	i=LEN(fspath$)
	DO
		ch=ASC(MID$(fspath$,i,1))
		IF ch="\"% OR ch=":"% THEN EXIT LOOP
		IF i=1 THEN EXIT LOOP
		DECR i
	LOOP 
	FileSelect$=LEFT$(fspath$,i)+fsname$
ELSE
	FileSelect$=""
END IF
END FUNCTION

' initialise the file selector
SUB	InitFileSelector
SHARED fspath$,fsname$
fspath$=CURDIR$+"\*.*"
fsname$=""
END SUB
