EmuTOS - FireBee version

These ROMs are suitable for FireBee hardware.  See:
https://firebee.org/

The desktop features are comparable to Atari TOS 4.

Each ROM contains a single language for display:

etosfbca.s16 - Catalan (PAL)
etosfbcz.s19 - Czech (PAL)
etosfbde.s19 - German (PAL)
etosfbes.s19 - Spanish (PAL)
etosfbfi.s19 - Finnish (PAL)
etosfbfr.s19 - French (PAL)
etosfbgr.s19 - Greek (PAL)
etosfbhu.s19 - Hungarian (PAL)
etosfbit.s19 - Italian (PAL)
etosfbnl.s19 - Dutch (PAL)
etosfbno.s19 - Norwegian (PAL)
etosfbpl.s19 - Polish (PAL)
etosfbru.s19 - Russian (PAL)
etosfbse.s19 - Swedish (PAL)
etosfbsg.s19 - Swiss German (PAL)
etosfbtr.s19 - Turkish (PAL)
etosfbus.s19 - English (NTSC)
etosfbuk.s19 - English (PAL)

However, note that these ROMs will use the standard values from NVRAM
for keyboard, date/time etc.

The following optional files are also supplied:
emuicon.rsc - contains additional icons for the desktop
emuicon.def - definition file for the above

Notes on possible points of confusion
1. The emuicon.rsc file format differs from deskicon.rsc used by later
versions of the Atari TOS desktop.
2. Selecting Norwegian/Swedish currently sets the language to English,
but the keyboard layout to Norwegian/Swedish.

This ROM image can be flashed into the FireBee flash memory using any supported
flash tool, including:

1) Freescale's CF Flasher
https://www.nxp.com/downloads/en/programmers/CFFLASHER.zip
This tool runs on MS Windows and requires additional hardware.

2) Didier Méquignon's FLASH060.PRG
http://didier.mequignon.free.fr/firebee.htm
Get it from the tos060.lzh archive, in the tos060/flash.too folder.
On your FireBee, start FireTOS, run FLASH060.PRG and flash etosfbXX.s19,
where XX is the country code with the desired language.
You can also use FLASH_CF.PRG from EmuTOS itself.

In both cases, the correct EmuTOS flash parameters are prefilled,
you don't need to change anything.

To start EmuTOS on the FireBee, you have 2 options.

1) Put DIP switch #5 down and DIP switch #6 up. This is the preferred
method; EmuTOS will be started directly from the BaS in fully native mode.

2) Start FireTOS. At the very beginning, a boot menu appears. Select 2 - EMUTOS.
This will run EmuTOS over FreeRTOS and enable extra features, such as support
for USB keyboard and mouse.

The FireBee ROM features:
- Pure ColdFire OS: ColdFire TOS programs only, 680x0 programs unsupported
- IDE support for both internal CompactFlash and external IDE connector
- MMC/SD-Card support, including hot swap
- Longer welcome screen delay to allow monitors to recover from sleep modes
- NVRAM boot resolution is currently ignored, 640x480x16 is always used

These ROM images have been built using:
make allfirebee

This release has been built using Vincent Rivière's GCC 4.6.4 cross-compiler.

The source package and other binary packages are available at:
https://sourceforge.net/projects/emutos/files/emutos/1.4/

An online manual is available at the following URL:
https://emutos.github.io/manual/

The extras directory (if provided) contains:
(1) one or more alternate desktop icon sets, which you can use to replace
    the builtin ones.  You can use a standard resource editor to see what
    the replacement icons look like.
    To use a replacement set, move or rename the existing emuicon.rsc &
    emuicon.def files in the root directory, then copy the files containing
    the desired icons to the root, and rename them to emuicon.rsc/emuicon.def.
(2) a sample mouse cursor set in a resource (emucurs.rsc/emucurs.def).  This
    set is the same as the builtin ones, but you can use it as a basis to
    create your own mouse cursors.
    To use a replacement set, copy the files containing the desired mouse
    cursors to the root, and rename them to emucurs.rsc/emucurs.def.
For further information on the above, see doc/emudesk.txt.

If you want to read more about EmuTOS, please take a look at these files:

doc/announce.txt      - Introduction and general description, including
                        a summary of changes since the previous version
doc/authors.txt       - A list of the authors of EmuTOS
doc/bugs.txt          - Currently known bugs
doc/changelog.txt     - A summarised list of changes after release 0.9.4
doc/emudesk.txt       - A brief guide to the newer features of the desktop
doc/incompatible.txt  - Programs incompatible with EmuTOS due to program bugs
doc/license.txt       - The FSF General Public License for EmuTOS
doc/status.txt        - What is implemented and running (or not yet)
doc/todo.txt          - What should be done in future versions
doc/tools.txt         - Tools to customize EmuTOS ROM images
doc/xhdi.txt          - Current XHDI implementation status

Additional information for developers (just in the source archive):

doc/install.txt       - How to build EmuTOS from sources
doc/coding.txt        - EmuTOS coding standards (never used :-) )
doc/country.txt       - An overview of i18n issues in EmuTOS
doc/dual_kbd.txt      - An explanation of the dual keyboard layout feature
doc/fat16.txt         - Notes on the FAT16 filesystem in EmuTOS
doc/m54xx-cards.txt   - Using CF cards on ColdFire V4e Evaluation Boards
doc/memdetect.txt     - Memory bank detection during EmuTOS startup
doc/nls.txt           - How to add a native language or use one
doc/old_changelog.txt - A summarised list of changes up to & including
                        release 0.9.4
doc/osmemory.txt      - All about OS internal memory in EmuTOS
doc/reschange.txt     - How resolution change works in the desktop
doc/resource.txt      - Modifying resources in EmuTOS
doc/startup.txt       - Some notes on the EmuTOS startup sequence
doc/tools.txt         - User tools to customise EmuTOS ROM images
doc/tos14fix.txt      - Lists bugs fixed by TOS 1.04 & their status in EmuTOS
doc/version.txt       - Determining the version of EmuTOS at run-time

The following documents are principally of historical interest only:

doc/old_code.txt      - A museum of bugs due to old C language
doc/vdibind.txt       - Old information on VDI bindings

-- 
The EmuTOS development team
https://emutos.sourceforge.io/
