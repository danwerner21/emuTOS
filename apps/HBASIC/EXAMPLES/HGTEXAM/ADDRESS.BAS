REM $option !gy
REM $option k100

REM $include toolbox.bas
REM $include dialog.bas
REM $include menu.bas

REM $include address.bh

' The routines for handling the address book file and data structure
SUB PutRecord(BYVAL i)
SHARED nnames$(1),addr1$(1),addr2$(1),addr3$(1),addr4$(1),phones$(1)
SHARED nname$,addr$(1),phone$
	PUT #1,i+1
	nnames$(i)=nname$
	addr1$(i)=addr$(1)
	addr2$(i)=addr$(2)
	addr3$(i)=addr$(3)
	addr4$(i)=addr$(4)
	phones$(i)=phone$
END SUB

SUB GetRecord(BYVAL i)
SHARED nnames$(1),addr1$(1),addr2$(1),addr3$(1),addr4$(1),phones$(1)
SHARED nname$,addr$(1),phone$
	GET #1,i+1
	nnames$(i)=nname$
	addr1$(i)=addr$(1)
	addr2$(i)=addr$(2)
	addr3$(i)=addr$(3)
	addr4$(i)=addr$(4)
	phones$(i)=phone$
END SUB

SUB OpenFile
SHARED nnames$(1),addr1$(1),addr2$(1),addr3$(1),addr4$(1),phones$(1)
SHARED nname$,addr$(1),phone$,records,max_records,recordcnt$
STATIC newfile,i
newfile= FEXISTS("address.dat")=0
OPEN "address.dat" FOR RANDOM AS #1 LEN=180

DIM addr$(4)
FIELD #1,	20 AS nname$,_
			35 AS addr$(1),_
			35 AS addr$(2),_
			35 AS addr$(3),_
			35 AS addr$(4),_
			20 AS phone$
FIELD #1,	2 AS recordcnt$
IF newfile THEN
	records=0
ELSE
	GET #1,1
	records=CVI(recordcnt$)
END IF
max_records=records+10
DIM nnames$(max_records)
DIM addr1$(max_records)
DIM addr2$(max_records)
DIM addr3$(max_records)
DIM addr4$(max_records)
DIM phones$(max_records)
FOR i=1 TO records
	GetRecord i
NEXT i
END SUB

SUB CloseFile
SHARED recordcnt$,records
LSET recordcnt$=MKI$(records)
PUT #1,1
CLOSE #1
END SUB

FUNCTION AddRecord
SHARED records,max_records,nnames$(1)
SHARED addr1$(1),addr2$(1),addr3$(1),addr4$(1),phones$(1)
	INCR records
	IF records>max_records THEN
		max_records=max_records+10
		REDIM APPEND nnames$(max_records),addr1$(max_records),addr2$(max_records),addr3$(max_records),addr4$(max_records),phones$(max_records)
	END IF
	PutRecord records
	AddRecord=records
END FUNCTION

FUNCTION NextRecord(BYVAL i)
SHARED records,nnames$(1)
DO 
	INCR i
	IF i>records THEN i=0: EXIT LOOP
LOOP WHILE LEFT$(nnames$(i),7)="DELETED"
NextRecord=i
END FUNCTION


FUNCTION PreviousRecord(BYVAL i)
SHARED records,nnames$(1)
DO
	DECR i
	IF i<=0 THEN i=0: EXIT LOOP
LOOP WHILE LEFT$(nnames$(i),7)="DELETED"
PreviousRecord=i
END FUNCTION


FUNCTION FindRecord(partname$,cur_record)
SHARED nnames$(1),records
STATIC start_record,i
start_record=cur_record
i=cur_record
DO
	i=NextRecord(i)
	IF i=0 THEN
		IF start_record=0 THEN
			i=0
		ELSE
			i=NextRecord(0)	
			IF i=0 THEN i=start_record	'no records at all
		END IF
	END IF
	IF i=start_record THEN
		'record not found
		FindRecord=-1
		EXIT LOOP
	END IF
	IF INSTR(nnames$(i),partname$)>0 THEN
		FindRecord=i
		EXIT LOOP
	END IF
LOOP
END FUNCTION

SUB DeleteRecord(BYVAL i)
SHARED nname$
LSET nname$="DELETED"
PutRecord i
END SUB

SUB ReOrganiseFile
SHARED nnames$(1),addr1$(1),addr2$(1),addr3$(1),addr4$(1),phones$(1)
SHARED records,nname$
STATIC i,j
j=1:i=1
DO
	IF i>records THEN EXIT LOOP
	GET #1,i+1
	IF LEFT$(nname$,7)<>"DELETED" THEN
		IF i<>j THEN
			PUT #1,j+1
			nnames$(j)=nnames$(i)
			addr1$(j)=addr1$(i)
			addr2$(j)=addr2$(i)
			addr3$(j)=addr3$(i)
			addr4$(j)=addr4$(i)
			phones$(j)=phones$(i)
		END IF
		INCR j
	END IF
	INCR i
LOOP
records=j-1
END SUB

'Now the routines that handle the user interface/data structure conversions
SUB DisplayRecord(BYVAL i)
SHARED nnames$(1),addr1$(1),addr2$(1),addr3$(1),addr4$(1),phones$(1)
IF i=0 THEN EXIT SUB
SelectTree MAINDIALOG
Sette_ptext MDNAME,RTRIM$(nnames$(i))
Sette_ptext MDADDR1,RTRIM$(addr1$(i))
Sette_ptext MDADDR2,RTRIM$(addr2$(i))
Sette_ptext MDADDR3,RTRIM$(addr3$(i))
Sette_ptext MDADDR4,RTRIM$(addr4$(i))
Sette_ptext MDPHONE,RTRIM$(phones$(i))

END SUB

SUB ExtractInfo
SHARED nname$,addr$(1),phone$
STATIC i
LSET nname$=Gette_ptext$(MDNAME)
FOR i=1 TO 4
	LSET addr$(i)=Gette_ptext$(MDADDR1+i-1)
NEXT i		
LSET phone$=Gette_ptext$(MDPHONE)
END SUB

' Now the purely user interface routines
SUB ClearDialog
SHARED i
SelectTree MAINDIALOG
Sette_ptext MDNAME,""
FOR i=1 TO 4
	Sette_ptext MDADDR1+i-1,""
NEXT i
Sette_ptext MDPHONE,""
END SUB

SUB HandleEdits
SHARED nname$,addr$(1),phone$,cur_record
STATIC Comm,i
cur_record=0
DO
	SelectTree MAINDIALOG
	Comm=HandleDialog(MDNAME)
	SELECT CASE Comm 
	CASE MDNEW:
			ExtractInfo
			cur_record=AddRecord
	CASE MDFIND:
			SelectTree FindDialog
			IF HandleDialog(0)=FDOK THEN
				i=FindRecord(Gette_ptext$(FDSTRING),cur_record)
				IF i>0 THEN
					cur_record=i
					DisplayRecord cur_record
				ELSE
					junk=Newform_alert(ALERTNOTFOUND,1)
				END IF	
			END IF
	CASE MDDELETE:
			IF cur_record=0 THEN
				junk=newform_alert(NOTHINGDEL,1)
			ELSE
				IF Newform_alert(DELETEWARN,1)=2 THEN
					DeleteRecord cur_record
					cur_record=0
				END IF
			END IF
	CASE MDPREVIOUS:
			i=PreviousRecord(cur_record)
			IF i>0 THEN
				cur_record=i
				DisplayRecord cur_record
			END IF
	CASE MDNEXT:
			i=NextRecord(cur_record)
			IF i>0 THEN
				cur_record=i
				DisplayRecord cur_record
			END IF
	CASE MDUPDATE:
			IF cur_record>0 THEN
				ExtractInfo
				PutRecord cur_record
			ELSE
				junk=Newform_alert(NOTHINGUPDATE,1)
			END IF
	CASE MDCLEAR:
			ClearDialog
			cur_record=0
	CASE MDEXIT:
			EXIT SUB
	END SELECT		
LOOP
END SUB

SUB ProcessUserMenus(VAL cur_front,VAL item,VAL title)
SHARED texth,wolines(1),lines$(2),TextWindows
STATIC i,finame$,temp,id
SELECT CASE item
CASE MeAboutAddress:
	SelectTree AboutDialog
	junk=HandleDialog(0)
CASE MeReorganise:	
	ReorganiseFile
CASE MeEdit:
	HandleEdits
END SELECT
END SUB

SUB jokeredraw
END SUB

StartProgram "ADDRESS.RSC",MENU,MEQUIT
OpenFile
ClearDialog
HGTloop
CloseFile
StopProgram
