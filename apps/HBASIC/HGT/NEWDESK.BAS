' set or reset the desktop pattern
SUB SetDeskAddr(BYVAL newdesk&)
SHARED windx,windy,windw,windh
SHARED desktree&
desktree&=newdesk&
junk=wind_set(0,WF_NEWDESK,PEEKW(VARPTR(newdesk&)),PEEKW(VARPTR(newdesk&)+2),0,0)
' cause the AES to re-draw the whole screen
form_dial FMD_FINISH,0,0,0,0,Windx,Windy,Windw,Windh
END SUB

SUB SetDesk(BYVAL treeno)
SHARED windx,windy,windw,windh
STATIC formaddr&
IF treeno=-1 THEN
	SetDeskAddr 0
ELSE
	junk=rsrc_gaddr(type_tree,treeno,formaddr&)
	SelectTreeAddr formaddr&
	Setob_x 0,Windx
	Setob_y 0,Windy
	Setob_width 0,Windw
	Setob_height 0,Windh
	SetDeskAddr formaddr&
END IF
END SUB
