	IFD	__G2
	opt	p+,c16+
	ENDC

*
*	LIBRARY.H include file for HiSoft BASIC ½ HiSoft 1987
*
* 30 Mar 88	changed for GENST2 compatibility
*  5 May 93	inl_ macros added for inline trap calls
*
* Rules for HiSoft BASIC libraries
* --------------------------------
*
* Libraries be of the form:
*
*	library	NAME
*
*	xref.l	gl_scratch	* all xrefs
*	xref	get_string	
*
*	xdef	test1		* then the user routine names
*	xdef	test2
*
* Note! -> xrefs and xdefs must be together before anything else
*
*	subdef	int,int		* test1  subroutine that's passed 2 ints
*	fn_int	int,int		* test2  function that returns an int
*
* Note! -> The order of appearance *MUST* be the same as the xdefs
*
*	libstart		* after declarations before the code
*
*	then your code...
*
* until there is no more or another library statement
*

	
*
* get_string
*
* takes:	a0	<- string descriptor
*
* returns:	a1	<- address of string
*		d4.l	<- length of string
*
* uses:		a0,a1,d4
*

*
* get_array
*
* takes:	a0	<- array descriptor
*		d0	<- number of dimensions the array should have
*
* returns:	a2	<- address of first element in array
*		d4.l	<- total length in bytes taken by array elements
*
* uses:		a1,a2,d0,d4
*

*
* make_string
*
* takes:	a0	<- string descriptor
*		a1	<- address of user copy of the string
*		d4.l	<- length of string to be
*
* uses:		d0-d4,a0-a2
*

*
* gl_scratch
*
* is a 128 byte buffer which may be used as workspace. It is used by BASIC
* as the DTA, so be careful after Fsfirsts etc. This is the only space on
* the heap that a library may use; if you need more, use the stack.
*

global	equr	a5
local	equr	a4
tos	equr	d7
tos2	equr	d6

library	macro
	module	!\1
	section	CODE
	endm


subdef	macro
	dc.b	48,NARG+1
	params	\1,\2,\3,\4,\5,\6,\7,\8,\9
	endm

fn_int	macro
	dc.b	95,'%',NARG+1
	params	\1,\2,\3,\4,\5,\6,\7,\8,\9
	endm

fn_lng	macro
	dc.b	95,'&',NARG+1
	params	\1,\2,\3,\4,\5,\6,\7,\8,\9
	endm

fn_sng	macro
	dc.b	95,'!',NARG+1
	params	\1,\2,\3,\4,\5,\6,\7,\8,\9
	endm

fn_dbl	macro
	dc.b	95,'#',NARG+1
	params	\1,\2,\3,\4,\5,\6,\7,\8,\9
	endm

params	macro
	ifnc	'\1',''
	dc.b	l_\1
	endc
	ifnc	'\2',''
	dc.b	l_\2
	endc
	ifnc	'\3',''
	dc.b	l_\3
	endc
	ifnc	'\4',''
	dc.b	l_\4
	endc
	ifnc	'\5',''
	dc.b	l_\5
	endc
	ifnc	'\6',''
	dc.b	l_\6
	endc
	ifnc	'\7',''
	dc.b	l_\7
	endc
	ifnc	'\8',''
	dc.b	l_\8
	endc
	ifnc	'\9',''
	dc.b	l_\9
	endc
	endm

array_mask	equ	8
var_para_mask	equ	16

l_int	equ	1
l_lng	equ	2
l_sng	equ	3
l_dbl	equ	4
l_str	equ	5

l_aint	equ	l_int+array_mask
l_alng	equ	l_lng+array_mask
l_asng	equ	l_sng+array_mask
l_adbl	equ	l_dbl+array_mask
l_astr	equ	l_str+array_mask

l_vint	equ	l_int+var_para_mask
l_vlng	equ	l_lng+var_para_mask
l_vsng	equ	l_sng+var_para_mask
l_vdbl	equ	l_dbl+var_para_mask
l_vstr	equ	l_str+var_para_mask

libstart	macro
	dc.b	0
	even
	endm

option	macro	string
	ifc	\1,''
	fail	Bad param to Option
	mexit
	endc
	dc.b	*-z\@+1
	dc.b	\1
z\@
	endm


inl_sub	macro	name,trapno,callno,paras
	dc.b	*-z\@+1
	dc.b	' ',48
	dc.b	'\1'
	dc.b	' '
	dc.b	\2,\3>>8,\3&$FF
	params	\4,\5,\6,\7,\8,\9,\A,\B,\C
z\@
	endm

inl_int	macro	name,trapno,callno,paras
	dc.b	*-z\@+1
	dc.b	' ',95
	dc.b	'\1','%'
	dc.b	' '
	dc.b	\2,\3>>8,\3&$FF
	params	\4,\5,\6,\7,\8,\9,\A,\B,\C
z\@
	endm

inl_lng	macro	name,trapno,callno,paras
	dc.b	*-z\@+1
	dc.b	' ',95
	dc.b	'\1','&'
	dc.b	' '
	dc.b	\2,\3>>8,\3&$FF
	params	\4,\5,\6,\7,\8,\9,\A,\B,\C
z\@
	endm

inl_sng	macro	name,trapno,callno,paras
	dc.b	*-z\@+1
	dc.b	' ',95
	dc.b	'\1','!'
	dc.b	' '
	dc.b	\2,\3>>8,\3&$FF
	params	\4,\5,\6,\7,\8,\9,\A,\B,\C
z\@
	endm

inl_dbl	macro	name,trapno,callno,paras
	dc.b	*-z\@+1
	dc.b	' ',95
	dc.b	'\1','&'
	dc.b	' '
	dc.b	\2,\3>>8,\3&$FF
	params	\4,\5,\6,\7,\8,\9,\A,\B,\C
z\@
	endm

inl_str	macro	name,trapno,callno,paras
	dc.b	*-z\@+1
	dc.b	' ',95
	dc.b	'\1','$'
	dc.b	' '
	dc.b	\2,\3>>8,\3&$FF
	params	\4,\5,\6,\7,\8,\9,\A,\B,\C
z\@
	endm

