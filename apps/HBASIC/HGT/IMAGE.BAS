	library "bios"
' Palette reading changed 15.4.92
' Colour Degasde-cimpressed properly 18.5.92
' Fixes for 'odd' size IMG files 19.5.92
' NEO/Degas files for TT resolutions added 5.6.92

'Image handling routines
' The structure of an image header
CONST imh_vrsn=0,imh_hdlen=1,imh_nplanes=2,imh_patlen=3,imh_pixelw=4
CONST imh_pixelh=5,imh_width=6,imh_height=7,imh_size=16

' The MFDB structure
CONST fd_addr=0,fd_w=2,fd_h=3,fd_wdwidth=4,fd_stand=5,fd_nplanes=6
CONST fd_r1=7,fd_r2=8,fd_r3=9,fd_size=9

'NEO chrome header
CONST neo_ver=0,neo_mode=1,neo_palette=2,neo_size=128

'DEGAS header
CONST deg_mode=0,deg_palette=1,deg_size=34

SUB res_to_wh(BYVAL res,w,h)
SELECT CASE res
CASE 0 : w=320: h=200
CASE 1 : w=640: h=200
CASE 2 : w=640: h=400
CASE 4 : w=1280 : h=960
CASE 5 : w=640: h=480
CASE 7 : w=320: h=480
CASE ELSE: AbortProgram " Can't cope with this resolution NEO file"
END SELECT
END SUB


SUB	vr_image_load(BYVAL addr&,BYVAL bytes)
SHARED fx$,fx&
blockmove SADD(fx$)+fx&,addr&,bytes
fx&=fx&+bytes
END SUB

FUNCTION vr_image_load_one
SHARED fx$,fx&
vr_image_load_one=PEEKB(SADD(fx$)+fx&)
INCR fx&
END FUNCTION

FUNCTION imglin(BYVAL dest&,BYVAL bytes,BYVAL patlen, patbuf(1))
STATIC c,byte
	DO WHILE bytes>0
		c=vr_image_load_one
		IF c=0 THEN
			c=vr_image_load_one
			IF c=0 THEN
				IF vr_image_load_one=255 THEN
					imglin=vr_image_load_one
					EXIT FUNCTION
				ELSE
					AbortProgram "unknown escape"
				END IF
			ELSE
				vr_image_load VARPTR(patbuf(0)),patlen
				bytes=bytes-c*patlen
				DO WHILE c>0
					blockmove VARPTR(patbuf(0)),dest&,patlen
					dest&=dest&+patlen
					DECR c
				LOOP
			END IF
		ELSEIF c=128 THEN
			c=vr_image_load_one
			vr_image_load dest&,c
			bytes=bytes-c
			dest&=dest&+c
		ELSE
			IF c>128 THEN
				byte=255
				c=c-128
			ELSE
				byte=0
			END IF
			bytes=bytes-c
			WHILE c>0
				POKEB dest&,byte
				INCR dest&
				DECR c
			WEND
		END IF
	LOOP
	imglin=0
END FUNCTION

SUB DegasLine(BYVAL dest&,BYVAL bytes)
STATIC c,byte
	DO WHILE bytes>0
		c=vr_image_load_one
		IF c<127 THEN
			vr_image_load dest&,c+1: dest&=dest&+c+1
			bytes=bytes-c-1
		ELSEIF c>128 THEN
			byte=vr_image_load_one
			c=257-c
			bytes=bytes-c
			WHILE c>0
				POKEB dest&,byte
				INCR dest&
				DECR c
			WEND
		END IF
	WEND
END SUB


CONST im_img=0,im_neo=1,im_degas=2
SUB LoadImage(BYVAL index,BYVAL im_type,BYVAL header_size,BYVAL mode_offset, BYVAL palette_offset)

SHARED images(2),palettes(2),palettes_used,fx&,fxmax&
STATIC rast&,patbuf(1),junk(1)
STATIC sce_planes,pwidth,nlines,patlen,bytes
STATIC plane_index&(1)
STATIC rastlen&,sce_mode,dest_mode
STATIC extra_header,rept,i,plane,dest&
STATIC a$,c,dest_planes,destrast&
STATIC monopic,compressed
STATIC ms(1),md(1),hdr(1),x(1)

	REDIM ms(fd_size),md(fd_size),hdr(neo_size\2)


	vr_image_load VARPTR(hdr(0)),header_size
	IF palettes_used THEN palettes(index,0)=0	'ie. unused
	monopic=0
	dest_planes=PEEKW(SYSTAB)
	SELECT CASE im_type
	CASE im_img:
		extra_header=hdr(imh_hdlen)*2-imh_size
		IF extra_header>0 THEN
			REDIM junk(extra_header\2)
			vr_image_load VARPTR(junk(0)),extra_header
			IF palettes_used THEN
				IF junk(0)= &h80THEN
					'HyperPaint hardware palette
					FOR i=1 TO 16
						palettes(index,i)=junk(i)
					NEXT i
					palettes(index,0)=-1	'i.e. used
				END IF
			END IF
			ERASE junk
		END IF
		nlines=hdr(imh_height)
		pwidth=hdr(imh_width)
		sce_planes=hdr(imh_nplanes)
		ms(fd_stand)=1
		patlen=hdr(imh_patlen)
		IF dest_planes<>sce_planes OR sce_planes=1 THEN
			IF sce_planes<>1 THEN
				AbortProgram "this image is designed for the wrong resolution"
			END IF
			monopic=1
		END IF
		compressed=-1
		REDIM patbuf(patlen\2)
	CASE im_neo,im_degas:
		compressed=0
		sce_mode=hdr(mode_offset)
		IF sce_mode<0 THEN	
			compressed=-1
			sce_mode=sce_mode AND &h7FFF
			ms(fd_stand)=1
		END IF
		res_to_wh sce_mode,pwidth,nlines
		dest_mode=getrez
		IF dest_mode<>sce_mode THEN
			IF (sce_mode=2) OR (sce_mode=6) THEN
				'its mono
				monopic=1
				sce_planes=1
				ms(fd_stand)=1
			ELSE
				AbortProgram "this image is designed for the wrong resolution"
			END IF
		ELSE
			sce_planes=PEEKW(SYSTAB)
			IF palettes_used THEN
				palettes(index,0)=-1	'i.e. used
				FOR i=1 TO 16
					palettes(index,i)=hdr(palette_offset+i-1)
				NEXT i
			END IF
		END IF
	END SELECT

	ms(fd_w)=pwidth
	ms(fd_h)=nlines
	ms(fd_wdwidth)= (ms(fd_w)+15)>>4
	ms(fd_nplanes)=sce_planes
	

	FOR i=0 TO fd_size:	md(i)=ms(i): NEXT i

	md(fd_stand)=0
	md(fd_nplanes)=dest_planes
	
	rastlen&=CLNG(ms(fd_wdwidth))*nlines*2
	rast&=Malloc&(rastlen&*sce_planes)
	IF rast&=0 THEN AbortProgram "out of memory - panic!"
	POKEL VARPTR(ms(fd_addr)),rast&

	IF compressed OR monopic THEN
		destrast&=Malloc&(rastlen&*dest_planes)	
		IF destrast&=0 THEN AbortProgram "out of memory - panic!"
	ELSE		destrast&=rast&
	END IF
	
	POKEL VARPTR(md(fd_addr)),destrast&
		
	
	REDIM plane_index&(sce_planes-1)
	IF compressed THEN
		FOR i=0 TO sce_planes-1
			plane_index&(i)=rast&+rastlen&*i
		NEXT i
		bytes= (ms(fd_w)+7)>>3
 			WHILE nlines>0 AND (fx&<fxmax&)
			rept=0
			FOR plane=0 TO sce_planes-1
				dest&=plane_index&(plane)
				IF im_type=im_img THEN
					IF rept=0 THEN
						rept=imglin(dest&,bytes,patlen,patbuf())
					END IF
					IF rept THEN
						junk=imglin(dest&,bytes,patlen,patbuf())
					END IF
					dest&=dest&+ms(fd_wdwidth)*2
					FOR i=1 TO rept-1
						BLOCKMOVE plane_index&(plane),dest&,bytes
						dest&=dest&+ms(fd_wdwidth)*2
					NEXT i
				ELSE
					DegasLine dest&,bytes
					dest&=dest&+ms(fd_wdwidth)*2
				END IF	
				plane_index&(plane)=dest&
			NEXT plane
			IF rept THEN nlines=nlines-rept ELSE DECR nlines
		WEND


		FOR plane=0 TO sce_planes-1
			dest&=plane_index&(plane)
			WHILE nlines>0
			' clear out any junk at the end
				c=bytes
				WHILE c>0
					POKEB dest&,0
					INCR dest&
					DECR c
				WEND
				DECR nlines
			WEND
		NEXT plane
	
	ELSE
' not compressed

		vr_image_load rast&,rastlen&*sce_planes
	END IF
	
	IF monopic OR compressed THEN
		IF monopic THEN
			REDIM x(7)
			x(0)=0: x(1)=0: x(2)=ms(fd_w)-1: x(3)=ms(fd_h)-1
			x(4)=0: x(5)=0: x(6)=x(2): x(7)=x(3)
	 		vrt_cpyfm 1,x(),VARPTR(ms(0)),VARPTR(md(0)),1,0
		ELSEIF compressed THEN
			vr_trnfm VARPTR(ms(0)),VARPTR(md(0))
		END IF
		junk=Mfree(rast&)
	END IF
	FOR i=0 TO fd_size
		 images(index,i)=md(i)
	NEXT i

END SUB



SUB LoadPicture(fname$,index)
SHARED fxmax&,fx$,fx&,images_used
STATIC fp,ext$
	images_used=-1
	fp=FREEFILE
	IF NOT FEXISTS(fname$) THEN 
		Debug "file not found": EXIT SUB
	END IF
	BusyBee 1

	OPEN fname$ FOR INPUT AS #fp
	fxmax&=LOF(fp)
	fx$=INPUT$(fxmax&,#fp)
	fx&=0
	CLOSE #fp

	ext$=UCASE$(MID$(fname$,LEN(fname$)-3,3))
	SELECT CASE ext$
	CASE ".PI",".PC": LoadImage index,im_degas,deg_size,deg_mode,deg_palette
	CASE ".IM": LoadImage index,im_img,imh_size,0,0
	CASE ".NE": LoadImage index,im_neo,neo_size,neo_mode,neo_palette
	END SELECT
	BusyBee 0
END SUB

SUB DisplayImage(BYVAL index,BYVAL x,BYVAL y)
STATIC i,local_mfdb(1),x(1),pal(1)
SHARED images(2),mscr(1),palettes(2),palettes_used
	REDIM local_mfdb(fd_size),mscr(fd_size),x(8),pal(15)
	IF palettes_used THEN
		IF palettes(index,0) THEN
			FOR i=0 TO 15
				pal(i)=palettes(index,i+1)
			NEXT i
			setpalette pal()
		END IF
	END IF

	FOR i=0 TO fd_size: 	local_mfdb(i)=images(index,i): NEXT i
	x(0)=0: x(1)=0: x(2)=local_mfdb(fd_w)-1: x(3)=local_mfdb(fd_h)-1
	x(4)=x: x(5)=y: x(6)=x(2)+x: x(7)=x(3)+y
	vro_cpyfm 3,x(),VARPTR(local_mfdb(0)),VARPTR(mscr(0))
END SUB

SUB CloseImage(BYVAL index)
SHARED images(2)
junk=Mfree(PEEKL(VARPTR(images(index,0))))
POKEL VARPTR(images(index,0)),0 
END SUB

SUB CloseAllImages
SHARED images(2),images_used
STATIC i
IF images_used THEN
	FOR i=LBOUND(images,1) TO UBOUND(images,1)
		IF images(i,0)<>0 OR images(i,1)<>0 THEN
			CloseImage i
		END IF
	NEXT i
END IF
END SUB
