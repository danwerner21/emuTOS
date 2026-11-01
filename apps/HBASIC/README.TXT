Readme file for HiSoft BASIC 2 for the Atari
============================================

This is version 2.10.

Additional files on Disk 1
--------------------------

HB2INST.RSC
HBDISKS.DIR     are additional files required by the installation program.
HB2INST.INF

HGT\TOOLBOX.T   are now on disk 2
HGT\HGT.T


Additional files on disk 2
--------------------------
AUTO\HRAM1MEG.PRG  ramdisk for users with at least 2M of RAM
HGT\TOOLBOX.T      files that were originally on disk 1
HGT\HGT.T

The file MOST.T mentioned on Page 164 of the user Manual is no longer
included. Use HGT.T from the HGT folder instead.

Installation program
====================

We have tried to make this as self explainatory as possible. Please
click on the Help button for information applicable to your configuration.
For people who don't like installation programs, we've included
a Show command to display where the files would be copied.

The installation program does not support single sided floppy disk
drives. Users without a hard disk should disconnect any single sided
drive before running the installation program.

 
Editor additions
================

The editor now supports up to 7 windows.

The editor displays a 'beach ball' when compilation takes place. Do
not be alarmed when it stops rotating this is quite normal! The
compiler messages windows scrolls so that you can still see the
results of previous compilations.

If you select the 'Make resident' button in the tools dialog box
this will take affect immediately, loading the appropriate tool.
Similarly de-selecting 'Make resident' will cause the memory that
was used by the tool to be freed. 
Note that this can easily fragment your memory - you should re-load
the editor to give the maximum free contiguous memory.


Changes from First edition manual
================================

The XBIOS library rsconf call (page 222 of the technical reference is now
a function rsconf&. This returns the previous  ucr,rsr,tsr and scr parameters
packed into bytes with ucr as the most significant; scr is the least
signicicant.


Additional GEMDOS library functions
===================================
crawio_&,crawcin_&,cnecin_& are versions of crawio%,crawcin% and cnecin%
which return full 32 bit values enabling you to check the scan code
shift keys in a similar way as with cconin&
 
GEMAES library changes
======================

The last two parameters to shel_write are now long integers. So its
parameters are:

FUNCTION shel_write(BYVAL ex, BYVAL gr, BYVAL over,BYVAL nameptr&, BYVAL commandptr&)
The GemAES library  shel_get call is now a FUNCTION, FNshel_get%

GEM Toolbox change
==================

The Other Object routines (OTHEROBJ.BAS) are not included in HGT.BAS and
HGT.T to save space as few users have needed these. 

Further extensions to the GEM toolbox
=====================================
The formwind.bas Object_Redraw routine now takes two parameters.
The first is the window handle to be redrawn. The second is the object
number. Note that this can only redraw a single object.


The popup facilities in POPUP.BAS have been extended so that you can
now use the following keyboard short cuts to walk the popup menus:

Cursor Up/Down - to move up and down the menu items
ClrHome -        jump to the first item
Shift+ClrHome -  jump to last item
Return -         OK the selection and exit menu
Undo -           Cancel and exit menu

If the global variable mouse_detect_both=-1 then both mouse buttons
are active inside the popup menu.


Mistakes in the First Edition manuals
=====================================

The example in the User manual on Page 49 should include the line
LINEF 50,50,50,100 rather than LINEF 50,50,50,50.

At the bottom of Page 152 you should press the TAB key not the Escape
key to move to the next field.

Many thanks to Ofir Gal for his work on the new Popup and Form Windows of
the GEM toolbox.

Dave Nutkins
HiSoft
The Old School
Greenfield
BEDFORD
MK45 5DE
U.K.

