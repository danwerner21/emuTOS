SUB ObjcExtent(BYVAL obj,x,y,w,h)
STATIC ob_spec&,typ,border,offset
static mask3d,w1,h1
	junk=objc_offset(tree&,obj,x,y)
	w=getob_width(obj)
	h=getob_height(obj)
	ob_spec&=getob_spec&(obj)
	IF getob_flags(obj) AND mask_indirect THEN
		ob_spec&=PEEKL(ob_spec&)
	END IF
	typ=getob_type(obj) and &hff
	SELECT CASE typ
	CASE G_TEXT,G_BOXTEXT,G_FBOXTEXT,G_FTEXT:
		border=PEEKW(ob_spec&+te_thickness)
	CASE G_BOXCHAR:
		border=(ob_spec&>>16) AND &hff
		IF border>127 THEN border=border-256
	CASE G_BUTTON:
		border=-1
		IF getob_flags(obj) AND mask_default THEN DECR border
		IF getob_flags(obj) AND mask_exit THEN DECR border
	CASE ELSE:
		border=0
	END SELECT
	IF border>=0 THEN offset=0 ELSE offset=border:border=-border
	IF getob_state(obj) AND mask_outlined THEN
			IF offset>-3 THEN offset=-3
	END IF
	x=x+offset
	y=y+offset
	w=w-offset*2
	h=h-offset*2
	IF aes_version>=&H340 THEN
' 3D stuff available
			mask3d= getob_flags(obj) and mask_3d
			if mask3d=fl3dind or mask3d=fl3dact then
				junk=objc_sysvar( 0,AD3DVALUE,0,0,w1,h1)
				x=x-w1
				y=y-h1
				w=w+w1*2
				h=h+h1*2
			end if
	end if				

	
	IF getob_state(obj) AND mask_shadowed THEN
			w=w+border*2
			h=h+border*2
	END IF
END SUB