EmuTOS - M548x dBUG version

This EmuTOS version runs on ColdFire V4e Evaluation Boards (EVB).
No graphical output, only text mode ColdFire TOS programs through RS-232.

emutos-m548x-dbug.s19 - RAM executable (English)

Supported hardware:

- M5485EVB and M5475EVB (a.k.a. Zoom ColdFire EVB)
https://www.nxp.com/products/no-longer-manufactured/mcf5485-evaluation-board:M5485EVB
https://www.nxp.com/products/no-longer-manufactured/mcf5475-evaluation-board:M5475EVB

- M5484LITE and M5474LITE (a.k.a. Zoom ColdFire LITEKIT)
https://www.nxp.com/products/no-longer-manufactured/mcf5484-lite-evaluation-kit:M5484LITE
https://www.nxp.com/products/no-longer-manufactured/mcf5474-lite-evaluation-kit:M5474LITE

Prerequisites:
On your EVB, you need Freescale's dBUG command-line tool. By default, at startup
the EVB boots straight to the dBUG prompt. If you have lost the dBUG tool, you can
download it at this URL and flash it on your EVB:
https://www.nxp.com/files-static/32bit/software/app_software/M547X-8XEVB-DBBIN.zip

Requirements:
- An RS-232 connection between the EVB and a controlling computer.
- On the computer, an ANSI terminal emulator connected to the RS-232 port.
- An Ethernet connection between the EVB and your network.
- A TFTP server running somewhere on your network (can be the same computer).

Optional supported hardware:
- a CompactFlash card with a FAT16 partition.
- a micro SD card with a FAT16 partition via an Arduino-type adapter.
- PS/2 keyboard connected through an Eiffel/CAN adapter.

The use of CompactFlash and SD cards is described in m54xx-cards.txt.

How to run EmuTOS:

1) Ensure that your serial connection works fine. In the terminal, you should
see the dBUG prompt.

2) Ensure that your TCP/IP connection is properly configured, on both sides.

3) Put emutos-m548x-dbug.s19 at the root of your TFTP server.

4) In the terminal, type the following command to download the binary:
dn emutos-m548x-dbug.s19

5) Then type the following command to run EmuTOS:
go

6) You will see the EmuTOS welcome screen.
Press Escape to enter the early console.

7) If you wait too much, the desktop will run in the background.
Press Control+Z to return to EmuCON.

8) Then you can run EmuCON commands, and ColdFire text mode TOS programs from
the CompactFlash or SD card.

Restrictions:

- No graphical display.
Only text I/O through an RS/232 terminal or PS/2 keyboard

- Support for ColdFire TOS programs only. 680x0 programs will not work.

- No Atari hardware emulated. Clean programs using only the OS will work;
any that attempt direct access to the Atari hardware will not work.

This ROM image has been built using:
make m548x-dbug

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
