/* main68.c  --  main program started by booting the 68000 system  */
/*
	Copyright (C) 2011-2016 John R. Coffman.
	Copyright (C) 2015 William R. Sowerbutts
	Licensed for hobbyist use on the RetroBrew 68000 CPU boards.
***********************************************************************

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    in the file COPYING in the distribution directory along with this
    program.  If not, see <http://www.gnu.org/licenses/>.

**********************************************************************/
#include <stdlib.h>
#include <string.h>
/*#include <ctype.h>*/
#include "mytypes.h"
#include "ctype.h"
#include "string.h"
#include "packer.h"
#include "mfpic.h"
#include "dosdisk.h"
#include "ide.h"
#include "coff.h"
#include "cout.h"
#include "main68.h"
#include "bootinfo.h"
#include "bioscall.h"
#if !RETAIL
#include "debug.h"
#endif
#include "version.h"
#include "ff.h"
#include "diskio.h"
#include "elf.h"
#include "errno.h"


int sio_get(void);
int _con_out(char);
void _run_us_mode(word mode, void *pc, long usp, long ssp);
#define LOADPOINT 0x1000
#define round(x,n) (((x)+(n-1))&(-n))
#define ONE_MEG  0x100000

const char msg_welcome[] =
#ifdef WYSE
		"\r\n"
		"\033+"
#endif
		"\r\n\r\n"
		"        Welcome to the "
#if CPU<68010
				"MINI-M6800"
#else
				"KISS-6803"
#endif
#ifdef WYSE
		"\033\""		/* Wyse ESC "  => Unlock the Keyboard */
#endif
		"0 System     BIOS "  VERSION_STRING "\r\n\r\n"

;
/* Copyright moved to startup.s       
		"Copyright (C) 2011-2015 John R. Coffman  <johninsd@gmail.com>" "\r\n"  */
#if 1
const char msg_GNU_license[] =
	 "\r\n"
    "This program is free software: you can redistribute it and/or modify\r\n"
    "it under the terms of the GNU General Public License as published by\r\n"
    "the Free Software Foundation, either version 3 of the License, or\r\n"
    "(at your option) any later version.\r\n"
	 "\r\n"
    "This program is distributed in the hope that it will be useful,\r\n"
    "but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n"
    "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\r\n"
    "GNU General Public License for more details.\r\n"
	 "\r\n"
    "You should have received a copy of the GNU General Public License\r\n"
    "in the file COPYING in the distribution directory along with this\r\n"
    "program.  If not, see <http://www.gnu.org/licenses/>.\r\n"
	 "\r\n"
    "Licensed for hobbyist use on the RetroBrew " 
#if CPU<68010
				"MINI-M6800"
#else
				"KISS-6803"
#endif
					"0 CPU board."
#endif
		"\r\n\r\n"
;


/* The 'static' declarations place the work area FIRST in the .bss area */
/* This is desirable for FUZIX, since its default configuration wants to
   allocate all 256 trap vectors; 64 would be quite sufficient
*/
static
FATFS fat_fs_workarea[_VOLUMES];  /* used as stack area for 'debug68' */



char cmd_buffer[LINELEN+FUDGE];		/* used in debug68.c also */
#define inputbuffer (cmd_buffer+FUDGE)
dword auto_boot_time;			/* if non-zero, the auto-boot timer is active */
#define AUTOBOOT "0:/BOOT.CMD"		/* the auto-boot command string */
#define CMD_LEVEL_MAX 4
word cmd_level;
bool usermode;


#if !RETAIL
void prline(byte *buff)
{	/* print a line of 16 byte values */
	word i, j;
	byte *buf = buff;
	for (j=2; j--; ) {
		for (i=8; i--; ) {
			cprintf(" %02x", (int)(*buf++));
		}
		cprintf(" ");
	}
	cprintf(" ");
	buf = buff;
	for (i=16; i--; buf++) cprintf("%c", *buf>=' ' && *buf<0177 ? *buf : '.');
}

void prbuf(dword addr, byte *buf, int n)
{
	word i;
	int ch;
	while (n>0) {
		for (i=0; i<8 && n>0; i++) {
			cprintf("\n%04x: ", addr);
			prline(buf);
			buf+=16;
			addr+=16;
			n-=16;
		}
		cprintf("\n");
		if (n>0) {
			do ch = sio_get();
			while (ch<0);
		}
	}
}
#endif

#if 0
void show_bpb(struct BPB *bp)
{
	cprintf("%6hd : bytes per sector\n", bp->bps);
	cprintf("%6hu : sectors per cluster\n", (short)(bp->spc));
	cprintf("%6hu : reserved sectors\n", bp->rsvd);
	cprintf("%6hd : number of FATs\n", bp->nfat);
	cprintf("%6hd : number of root directory entries\n", bp->nrde);
	cprintf("%6lu : total number of sectors\n",
		bp->tsec ? (long)(bp->tsec) : bp->tsec2);
	cprintf("%6hx : media descriptor\n", bp->md);
	cprintf("%6hu : sectors per FAT\n", bp->spf);
	cprintf("%6hd : sectors per track\n", bp->spt);
	cprintf("%6hd : number of heads\n", bp->nhd);
	cprintf("%6lu : number of hidden sectors\n", bp->hid);
	cprintf("%6hx : BPB version info\n", bp->vers);
	cprintf("   Volume ID : %08lx \n", bp->id);
}


int uc_string(char *str, int length)
{
	int i = length;
	while( i-- ) {
		*str = toupper(*str);
		++str;
	}
	return length;
}
#endif




void rubout(void)
{
	_con_out('\b');
	_con_out(' ');
	_con_out('\b');
}

int getline(char *line, int linesize)
{
	int k = 0;
	signed char ch;

	do {
		do {
			ch = sio_get();
			if (auto_boot_time && ( (dword)daytime_c(1) >= auto_boot_time) ) {
			/* the auto-boot timer has expired */
/* bugfix 11/9/2021 jrc */	auto_boot_time = 0;
				strcpy(line, AUTOBOOT);
				cprintf("%s\n", line);
				return strlen(line);
			}
		} while (ch < 0);
		auto_boot_time = 0;	/* any key defeats auto-boot */

		if (ch >= ' ' && ch < 0177) {
			line[k++] = ch;
			_con_out(ch);
		}
		else if (ch == '\r' || ch == '\n') {
			ch = 0;
			_con_out('\r');
			_con_out('\n');
		}
		else if ( (ch == '\b' || ch == 0177) && k>0) {
			rubout();
			--k;
		}
		else if (ch == ('X' & 037) /* Ctrl-X */) {
			while (k) { rubout(); --k; }
		}
		else _con_out('G' & 037);	/* BEL */

	} while (ch && k < linesize-1);
	line[k] = 0;
#if !RETAIL
	if (debug>=5) cprintf("\ngetline: k=%d\n", k);
#endif
	return k;
}


unsigned int readline(char *line, unsigned int len, FIL *fd)
{
	unsigned int k = 0;
	unsigned int nread;
	char ch;
	FRESULT fres;
	
	while (k < len-1) {
		fres = f_read(fd, (void*)&ch, 1, &nread);
		if (fres != FR_OK  ||  nread != 1 ) {
			line[k] = 0;
			if (k == 0) return EOF;
			else return k;
		}
		if ( ch == 0x0a /* NL or LF */ ||  ch == 0) {
		/* it is end of line */
			line[k] = 0;	/* terminating NUL */
			return k;
		} else if (ch == 0x0d /* CR */) ;	/* strip it */
		else  line[k++] = ch;
	}
	line[k] = 0;
	return k;
}


void run_program(word usermode, void *start)
{
	long stack = (long)((void*)fat_fs_workarea)+sizeof(fat_fs_workarea);

	stack &= 0xFFFFFFFC;

#if !RETAIL
	if (debug>0) {
		state.usp = h_m_a - 0x1000;
		state.ssp = h_m_a;
		state.frame = 0x0FFF;	/* invalid format 0 */
		state.pc = (uint32)start;
		state.sr = usermode ? 0 : 0x2000;
#if 0
		debug68(0);
#else
		stack -= 4;
		*(long*)stack = 0;

		_run_us_mode( 1, (void*)debug68, h_m_a-0x1000, (long)stack);
#endif
		
		exit(0);
	}
	else
#endif
	{
		_run_us_mode(!usermode, start, h_m_a - 0x1000, h_m_a );
	}
}


void do_set_mode(bool us_mode, char *argv[], int argc)
{
	bool user_mode_save;

#if !RETAIL
	if (debug>=2) {
	    int i;
	    cprintf("do_set_mode: >>");
	    for (i=0; i<argc; ++i)
		cprintf("%s ", argv[i]);
	    cprintf("\n");
	}
#endif
	
	if (argc == 0) {
		usermode = us_mode;
	}
	else {
		user_mode_save = usermode;
		usermode = us_mode;
		handle_any_command(argv, argc);
		usermode = user_mode_save;
	}

}


void do_set_user(char *argv[], int argc) {
	do_set_mode(true, argv, argc);
}

void do_set_supv(char *argv[], int argc) {
	do_set_mode(false, argv, argc);
}


void do_today(char *argv[], int argc)
{
extern const char * dow[];	/* in setup.c */

	union {
		qword info;
		struct {
			unsigned yr:16;
			unsigned mo:4;
			unsigned da:8;
			unsigned dow:4;
			
			unsigned hr:16;
			unsigned min:8;
			unsigned sec:8;
		} bits;
	} daytime;
	
	daytime.info = daytime_c(2);
	cprintf("(%s)  %4d-%02d-%02d  at  %2d:%02d:%02d\n",
		dow[daytime.bits.dow],
		daytime.bits.yr,
		daytime.bits.mo,
		daytime.bits.da,
		daytime.bits.hr,
		daytime.bits.min,
		daytime.bits.sec   );
}



void do_run_rom_cpm(char *argv[], int argc)
{
extern byte location_zero;
	struct hdr *phdr;
	int size;
	byte *at;
	byte *addr = &location_zero  +  BIOSSIZE * 1024L;
	
	
	if (strncmp("CPM     SYS", (char*)addr+1, 11)) {
		cprintf("No CPM.SYS in ROM found.\n");
		return;
	}
	addr += 2048;
	phdr = (void*)addr;
	if (phdr->ch_magic != MAGIC_M68K) {
		cprintf("Bad header on CPM.SYS file.\n");
		return;
	}
	addr += sizeof(struct hdr);
	size = phdr->ch_tsize + phdr->ch_dsize;
	at = (byte*)(phdr->ch_entry);
	if ( (int)at < LOADPOINT || (int)at + size + phdr->ch_bsize > ONE_MEG ) {
		cprintf("Cannot load CPM.sys out of allowable address range.\n");
		return;
	}
	memmove(at, addr, size);

	*(long*)0x000000 = BIOSSIZE * 1024;	/* tell CPM where the ROM is */

	run_program(0, at);
	return;
}



void f_perror(int error_no)
{
static
const char *fatfs_errmsg[20] = 
{
    /* 0  */ "Succeeded",
    /* 1  */ "A hard error occurred in the low level disk I/O layer",
    /* 2  */ "Assertion failed",
    /* 3  */ "The physical drive is not operational",
    /* 4  */ "Could not find the file",
    /* 5  */ "Could not find the path",
    /* 6  */ "The path name format is invalid",
    /* 7  */ "Access denied due to prohibited access or directory full",
    /* 8  */ "Access denied due to prohibited access",
    /* 9  */ "The file/directory object is invalid",
    /* 10 */ "The physical drive is write protected",
    /* 11 */ "The logical drive number is invalid",
    /* 12 */ "The volume has no work area",
    /* 13 */ "There is no valid FAT volume",
    /* 14 */ "The f_mkfs() aborted due to any parameter error",
    /* 15 */ "Could not get a grant to access the volume within defined period",
    /* 16 */ "The operation is rejected according to the file sharing policy",
    /* 17 */ "LFN working buffer could not be allocated",
    /* 18 */ "Number of open files > _FS_LOCK",
    /* 19 */ "Given parameter is invalid"
};

    if(error_no <= 19)
        cprintf("Error: %s\n", fatfs_errmsg[error_no]);
    else
        cprintf("Error: Unknown error %d. Hold tight.\n", error_no);
}



unsigned long dm_start, dm_count, dm_format;

void do_dump(char *argv[], int argc)
{

/*	cprintf("dump argc=%d\n",argc);		*/

    if (argc >=2) 
	dm_count = strtoul(argv[1], NULL, 16);
    if (argc >=1) {
	if (*argv[0] == '*') ;
	else  dm_start = strtoul(argv[0], NULL, 16);
    }

/*    pretty_dump_memory((void*)dm_start, dm_count); */
    fmt_dump(dm_format,  dm_start, dm_count);

    dm_start += dm_count;
}



bool load_command_file(char *arg[], int numarg, FIL *fd)
{
	bool echo_cmd = true;
	unsigned int n;
	
	
	if (++cmd_level > CMD_LEVEL_MAX) return false;

	for (;;) {
		n = readline(inputbuffer, LINELEN, fd);
		if (n == EOF) break;
		
		if (echo_cmd) cprintf("%s\n", inputbuffer);
		
		if (inputbuffer[0] == '#') continue;
		else if (n>0)  execute_cmd(&handle_any_command, inputbuffer);
	}
	
	--cmd_level;
	return true;
}




bool load_m68k_executable(char *arg[], int numarg, FIL *fd)
{
	struct hdr hdr68k;
	unsigned int bytes_read;
	byte *addr;
	int size;
	
	if (f_read(fd, &hdr68k, sizeof(hdr68k), &bytes_read) != FR_OK ||
			bytes_read < sizeof(hdr68k) ) {
		cprintf("Cannot read .68K file header.\n");
		return false;
	}
	size = round(hdr68k.ch_tsize,2) + round(hdr68k.ch_dsize,2);
	addr = (byte*)hdr68k.ch_entry;
	if (hdr68k.ch_magic != MAGIC_M68K || hdr68k.ch_entry < LOADPOINT ||
		    hdr68k.ch_entry + size + round(hdr68k.ch_bsize,2) > ONE_MEG ) {
		cprintf("Unable to load file below 0x%04x or above 0x%x\n",
				LOADPOINT, ONE_MEG);
		return false;
	}
	if (f_read(fd, addr, size, &bytes_read) != FR_OK || bytes_read < size) {
		cprintf("Error loading .68K file.\n");
		return false;
	}
	run_program(usermode, addr);
	
	return true;
}

bool load_coff_executable(char *arg[], int numarg, FIL *fd)
{
/*    bool usermode = true;  */
    unsigned int bytes_read;
    int i;
    T_aout_head header;

#if 0
    for(i=1; i<numarg; i++){
        switch(arg[i][0]){
            case 'u':
            case 'U':
                usermode = true;
                break;
            case 's':
            case 'S':
                usermode = false;
                break;
            default:
                cprintf("Unrecognised argument \"%s\".\n", arg[i]);
                return false;
        }
    }
#endif

    if(f_read(fd, &header, sizeof(header), &bytes_read) != FR_OK || bytes_read < AOUT_HEAD_SIZE){
        cprintf("Cannot read COFF file header.\n");
        return false;
    }

    if(header.magic != MAGIC_COFF || header.n_sects < 1 || header.n_sects > COFF_MAXSECTION){
        cprintf("Bad COFF header.\n");
        return false;
    }

    /* check load addresses */
    for(i=0; i<header.n_sects; i++){
        if(header.section[i].file_pos && header.section[i].load_at < LOADPOINT){
            cprintf("COFF file would overwrite processor vectors.\n");
            return false;
        }
    }

    /* load the resident sections */
    for(i=0; i<header.n_sects; i++){
        if(header.section[i].length){
            if(header.section[i].file_pos){
                cprintf("Loading section \"%s\": %d bytes from offset 0x%x to memory at 0x%x\n",
                        header.section[i].section_name, header.section[i].length,
                        header.section[i].file_pos, header.section[i].load_at);

                f_lseek(fd, header.section[i].file_pos);
                if(f_read(fd, (char*)header.section[i].load_at, header.section[i].length, &bytes_read) != FR_OK || 
                        bytes_read != header.section[i].length){
                    cprintf("Unable to read section from COFF file.\n");
                    return false;
                }
            }else{
                cprintf("Zeroing section \"%s\": %d bytes at 0x%x\n",
                        header.section[2].section_name, header.section[2].length,
                        header.section[2].load_at);
                memset((char*)header.section[2].load_at, 0, header.section[2].length);
            }
        }
    }

    cprintf("Entry at 0x%x in %s mode\n", header.entry_point, usermode ? "user" : "supervisor");
    run_program(usermode, (void*)header.entry_point);

    return true;
}

bool load_flat_executable(char *arg[], int numarg, FIL *fd)
{
    unsigned long loadaddr;
    unsigned int bytes_read;

    if(numarg != 2){
        cprintf("Please specify the load address as an argument (in hex).\n");
        return false;
    }

    loadaddr = strtoul(arg[1], NULL, 16);

    cprintf("Loading flat binary at 0x%x\n", loadaddr);

    bytes_read = f_size(fd);

    if(f_read(fd, (char*)loadaddr, bytes_read, &bytes_read) != FR_OK || bytes_read != f_size(fd)){
        cprintf("Unable to load file.\n");
        return false;
    }

    return true;
}


void help(char *argv[], int argc)
{
extern const cmd_entry_t cmd_table[];
	int i = 0;
	
	cprintf("\nBuilt-in commands:\n");
	while (cmd_table[i].name) {
		cprintf("%12s : %s\n", cmd_table[i].name,
					cmd_table[i].helpme);
		++i;
	}
	cprintf("\nCommand syntax:  [u|s] [<builtin>|<file[.ext]>] [<args> ...]\n"
		"    <file[.ext]> may be *.CMD *.OUT *.68K *.SYS *.ELF  (all with Magic ID)\n\n");
}




static int fromhex(char c)
{
    if(c >= '0' && c <= '9')
        return c - '0';
    if(c >= 'a' && c <= 'f')
        return 10 + c - 'a';
    if(c >= 'A' && c <= 'F')
        return 10 + c - 'A';
    return -1;
}

void do_writemem(char *argv[], int argc)
{
    unsigned long value;
    unsigned char *ptr;
    int i, j, l;

    value = strtoul(argv[0], NULL, 16);
    ptr = (unsigned char*)value;

    /* This can deal with values like: 1, 12, 1234, 123456, 12345678.
       Values > 2 characters are interpreted as big-endian words ie
       "12345678" is the same as "12 34 56 78" */

    /* first check we're happy with the arguments */
    for(i=1; i<argc; i++){
        l = strlen(argv[i]);
        if(l != 1 && l % 2){
            cprintf("Ambiguous value: \"%s\" (odd length).\n", argv[i]);
            return; /* abort! */
        }
        for(j=0; j<l; j++)
            if(fromhex(argv[i][j]) < 0){
                cprintf("Bad hex character \"%c\" in value \"%s\".\n", argv[i][j], argv[i]);
                return; /* abort! */
            }
    }

    /* then we do the write */
    for(i=1; i<argc; i++){
        l = strlen(argv[i]);
        if(l <= 2) /* one or two characters - a single byte */
            *(ptr++) = strtoul(argv[i], NULL, 16);
        else{
            /* it's a multi-byte value */
            j=0;
            while(j<l){
                value = (fromhex(argv[i][j]) << 4) | fromhex(argv[i][j+1]);
                *(ptr++) = (unsigned char)value;
                j += 2;
            }
        }
    }
}

void do_execute(char *argv[], int argc)
{
    unsigned long address;
/*    bool usermode = true;  */

    address = strtoul(argv[0], NULL, 16);
#if 0
    if(argc == 2){
        switch(argv[1][0]){
            case 'u':
            case 'U':
                usermode = true;
                break;
            case 's':
            case 'S':
                usermode = false;
                break;
            default:
                cprintf("Unrecognised argument \"%s\".\n", argv[1]);
                return;

        }
    }
#endif
    cprintf("Entry at 0x%x in %s mode\n", address, usermode ? "user" : "supervisor");
    run_program(usermode, (void*)address);

}

void do_cd(char *argv[], int argc)
{
    FRESULT r;

    r = f_chdir(argv[0]);
    if(r != FR_OK)
        f_perror(r);
}

void do_remark(char *argv[], int argc) {
	; /* null */
}


void do_ls(char *argv[], int argc)
{
    FRESULT fr;
    const char *path, *filename;
    DIR fat_dir;
    FILINFO fat_file;
    bool dir, left = true;
    int i;

    if(argc == 0)
        path = "";
    else
        path = argv[0];

    fr = f_opendir(&fat_dir, path);
    if(fr != FR_OK){
        cprintf("f_opendir(\"%s\"): ", path);
        f_perror(fr);
        return;
    }

    while(1){
        fr = f_readdir(&fat_dir, &fat_file);
        if(fr != FR_OK){
            cprintf("f_readdir(): ");
            f_perror(fr);
            break;
        }
        if(fat_file.fname[0] == 0) /* end of directory? */
            break;
        filename = 
#if _USE_LFN
            *fat_file.lfname ? fat_file.lfname : 
#endif
            fat_file.fname;

        dir = fat_file.fattrib & AM_DIR;

        if(dir){
            /* directory */
            cprintf("         %04d-%02d-%02d %02d:%02d %s/", 
                    1980 + ((fat_file.fdate >> 9) & 0x7F),
                    (fat_file.fdate >> 5) & 0xF,
                    fat_file.fdate & 0x1F,
                    fat_file.ftime >> 11,
                    (fat_file.ftime >> 5) & 0x3F,
                    filename);
            for(i=strlen(fat_file.fname); i<12; i++)
                cprintf(" ");
        }else{
            /* regular file */
            cprintf("%8d %04d-%02d-%02d %02d:%02d %-12s", fat_file.fsize, 
                    1980 + ((fat_file.fdate >> 9) & 0x7F),
                    (fat_file.fdate >> 5) & 0xF,
                    fat_file.fdate & 0x1F,
                    fat_file.ftime >> 11,
                    (fat_file.ftime >> 5) & 0x3F,
                    filename);
        }

        if(!left)
            cprintf("\n");
        else if(!dir)
            cprintf("  ");
        else
            cprintf(" ");
        left = !left;
    }

    if(!left)
        cprintf("\n");

    fr = f_closedir(&fat_dir);
    if(fr != FR_OK){
        cprintf("f_closedir(): ");
        f_perror(fr);
        return;
    }
}

#if !RETAIL
void do_debug(char *argv[], int argc);		/* in 'beetle.s' */

void do_do_debug(char *argv[], int argc)
{
	if (argc == 2) do_debug(argv, argc);
	else if (argc == 1) {
		debug = (7u & strtoul(argv[0], NULL, 0));
		if (debug > 5) debug = 5;
	}
	cprintf("debuglevel %hd\n", debug);
}
#endif

const cmd_entry_t cmd_table[] = {
    /* name         min max function */
    {"cd",          1,  1,  &do_cd,	"change directory <dir>"},
    {"cpm",	    0,  1,  &do_run_rom_cpm, "run ROM CP/M-68"	},
#if !RETAIL
    {"debug",       0,  2,  &do_do_debug, "set/get debug level [<n>]"	},
#endif
    {"dir",         0,  1,  &do_ls,	"list directory [<vol>:]"	},
    {"dm",          0,  2,  &do_dump,	"synonym for DUMP"	},
    {"dump",        0,  2,  &do_dump,	"dump memory <from> <count>" },
    {"execute",     1,  2,  &do_execute,"execute <addr>"	},
    						   /* execute <addr> [u|s] */
    {"help",	    0,  0,  &help,	"list this help info"	},
    {"ls",          0,  1,  &do_ls,	"synonym for DIR"	},
    {"rem",	    0,  0,  &do_remark,	"remark (in command file)"},
    {"s",           0,  0,  &do_set_supv, "synonym for SUPV"	},
    {"supv",        0,  0,  &do_set_supv, "set Supervisor mode (prefix or command)"},
    {"today",       0,  0,  &do_today,    "dispay the date and time"},
    {"u",           0,  0,  &do_set_user, "synonym for USER"	},
    {"user",	    0,  0,  &do_set_user, "set User mode (prefix or command)"},
    {"wm",          2,  0,  &do_writemem, "synonym for WRITEMEM"},
    {"writemem",    2,  0,  &do_writemem, "write memory <addr> [byte ...]" },
    						  /* writemem <addr> [byte...] */
    {0, 0, 0, 0, 0 } /* terminator */
};

bool handle_cmd_builtin(char *arg[], int numarg)
{
    FRESULT fr;
    const cmd_entry_t *cmd;

    if(numarg == 1 && arg[0][strlen(arg[0])-1] == ':'){
        /* change drive */
        fr = f_chdrive(arg[0]);
        if(fr) {
        	f_perror(fr);
        	cprintf("Cannot use drive %s\n", arg[0]);
        }
        
        return true;
    } else {
        /* built-in command */
        for(cmd = cmd_table; cmd->name; cmd++){
            if(!my_strcasecmp(arg[0], cmd->name)){
                if((numarg-1) >= cmd->min_args && 
                        (cmd->max_args == 0 || (numarg-1) <= cmd->max_args)){
                    cmd->function(arg+1, numarg-1);
                }else{
                    if(cmd->min_args == cmd->max_args){
                        cprintf("%s: takes exactly %d argument%s\n", arg[0], cmd->min_args, cmd->min_args == 1 ? "" : "s");
                    }else{
                        cprintf("%s: takes %d to %d arguments\n", arg[0], cmd->min_args, cmd->max_args);
                    }
                }
                return true;
            }
        }
    }
    return false;
}

bool load_elf_executable(char *arg[], int numarg, FIL *fd)
{
    int i, proghead_num;
#define MAXCMDLEN 200
    char kernel_cmdline[MAXCMDLEN];
    unsigned int bytes_read;
    unsigned int highest=0;
    unsigned int lowest=~0;
    elf32_header header;
    elf32_program_header proghead;
    struct bootversion *bootver;
    struct bi_record *bootinfo;
    struct mem_info *meminfo;
    bool loaded = false;
    bool umode = true;

    f_lseek(fd, 0);
    if(f_read(fd, &header, sizeof(header), &bytes_read) != FR_OK || bytes_read != sizeof(header)){
        cprintf("Cannot read ELF file header\n");
        return false;
    }

    if(header.ident_magic[0] != 0x7F ||
       header.ident_magic[1] != 'E' ||
       header.ident_magic[2] != 'L' ||
       header.ident_magic[3] != 'F' ||
       header.ident_version != 1){
        cprintf("Bad ELF header\n");
        return false;
    }

    if(header.ident_class != 1 || /* 32-bit */
       header.ident_data != 2 ||  /* big-endian */
       header.ident_osabi != 0 ||
       header.ident_abiversion != 0){
        cprintf("Not a 32-bit ELF file.\n");
        return false;
    }

    if(header.type != 2){
        cprintf("ELF file is not an executable.\n");
        return false;
    }

    if(header.machine != 4){
        cprintf("ELF file is not for 68000 processor.\n");
        return false;
    }

    for(proghead_num=0; proghead_num < header.phnum; proghead_num++){
        f_lseek(fd, header.phoff + proghead_num * header.phentsize);
        if(f_read(fd, &proghead, sizeof(proghead), &bytes_read) != FR_OK || bytes_read != sizeof(proghead)){
            cprintf("Cannot read ELF program header.\n");
            return false;
        }
        switch(proghead.type){
            case PT_NULL:
            case PT_NOTE:
            case PT_PHDR:
                break;
            case PT_SHLIB: /* "reserved but has unspecified semantics" */
            case PT_DYNAMIC:
                cprintf("ELF executable is dynamically linked.\n");
                return false;
            case PT_LOAD:
                if(proghead.paddr == 0){
                    /* patch up sections which want to overwrite the processor vectors */
                    proghead.offset += 0x1000;
                    proghead.paddr += 0x1000;
                    proghead.filesz -= 0x1000;
                    proghead.memsz -= 0x1000;
                }
                cprintf("Loading %d bytes from file offset 0x%x to memory at 0x%x\n", 
					proghead.filesz, proghead.offset, proghead.paddr);
                f_lseek(fd, proghead.offset);
                if(f_read(fd, (char*)proghead.paddr, proghead.filesz, &bytes_read) != FR_OK || 
                        bytes_read != proghead.filesz){
                    cprintf("Unable to read segment from ELF file.\n");
                    return false;
                }
                if(proghead.memsz > proghead.filesz)
                    memset((char*)proghead.paddr + proghead.filesz, 0, 
                            proghead.memsz - proghead.filesz);
                if(proghead.paddr < lowest)
                    lowest = proghead.paddr;
                if(proghead.paddr + proghead.filesz > highest)
                    highest = proghead.paddr + proghead.filesz;
                loaded = true;
                break;
            case PT_INTERP:
                cprintf("ELF executable requires an interpreter.\n");
                return false;
        }
    }

    if(loaded){
        /* check for linux kernel */
        bootver = (struct bootversion*)lowest;
        if(bootver->magic == BOOTINFOV_MAGIC){
            cprintf("Linux kernel detected:");

            /* check machine type is supported by this kernel */
            i=0;
            while(true){
                if(!bootver->machversions[i].machtype){
                    cprintf(" does not support KISS68030.\n");
                    return false;
                }
                if(bootver->machversions[i].machtype == MACH_KISS68030){
                    if(bootver->machversions[i].version == KISS68030_BOOTI_VERSION){
                        break; /* phew */
                    }else{
                        cprintf(" wrong bootinfo version.\n");
                        return false;
                    }
                }
                i++; /* next machversion */
            }

            /* now we write a linux bootinfo structure at the start of the 4K page following the kernel image */
            bootinfo = (struct bi_record*)((highest + 0xfff) & ~0xfff);

            cprintf(" creating bootinfo at 0x%x\n", bootinfo);

            /* machine type */
            bootinfo->tag = BI_MACHTYPE;
            bootinfo->data[0] = MACH_KISS68030;
            bootinfo->size = sizeof(struct bi_record) + sizeof(long);
            bootinfo = (struct bi_record*)(((char*)bootinfo) + bootinfo->size);

            /* CPU type */
            bootinfo->tag = BI_CPUTYPE;
            bootinfo->data[0] = CPU_68030;
            bootinfo->size = sizeof(struct bi_record) + sizeof(long);
            bootinfo = (struct bi_record*)(((char*)bootinfo) + bootinfo->size);

            /* MMU type */
            bootinfo->tag = BI_MMUTYPE;
            bootinfo->data[0] = MMU_68030;
            bootinfo->size = sizeof(struct bi_record) + sizeof(long);
            bootinfo = (struct bi_record*)(((char*)bootinfo) + bootinfo->size);

            /* FPU type */
            bootinfo->tag = BI_FPUTYPE;
            bootinfo->data[0] = 0; /* no FPU */
            bootinfo->size = sizeof(struct bi_record) + sizeof(long);
            bootinfo = (struct bi_record*)(((char*)bootinfo) + bootinfo->size);

            /* RAM location and size */
            bootinfo->tag = BI_MEMCHUNK;
            bootinfo->size = sizeof(struct bi_record) + sizeof(struct mem_info);
            meminfo = (struct mem_info*)bootinfo->data;
            meminfo->addr = 0;
            meminfo->size = (unsigned long)h_m_a;
            bootinfo = (struct bi_record*)(((char*)bootinfo) + bootinfo->size);

            /* Now let's process the user-provided command line */
            const char *initrd_name = NULL;


            kernel_cmdline[0] = 0;
            for(i=1; i<numarg; i++){
                if(!my_strncasecmp(arg[i], "initrd=", 7)){
                    initrd_name = &arg[i][7];
                }else{
                    if(kernel_cmdline[0])
                        strncat(kernel_cmdline, " ", MAXCMDLEN);
                    strncat(kernel_cmdline, arg[i], MAXCMDLEN);
                }
            }

            /* Command line */
            i = strlen(kernel_cmdline) + 1;
            i = (i+3) & ~3; /* pad to 32-bit boundary */
            bootinfo->tag = BI_COMMAND_LINE;
            bootinfo->size = sizeof(struct bi_record) + i;
            memcpy(bootinfo->data, kernel_cmdline, i);
            bootinfo = (struct bi_record*)(((char*)bootinfo) + bootinfo->size);

            /* check for initrd */
            FIL initrd;
            if(initrd_name && (f_open(&initrd, initrd_name, FA_READ) == FR_OK)){
                bootinfo->tag = BI_RAMDISK;
                bootinfo->size = sizeof(struct bi_record) + sizeof(struct mem_info);
                meminfo = (struct mem_info*)bootinfo->data;
                /* we need to locate the initrd some distance above the kernel -- 4MB should be enough? */
                meminfo->addr = ((((unsigned long)bootinfo) + 0xfff) & ~0xfff) + 0x400000;
                meminfo->size = f_size(&initrd);
                cprintf("Loading initrd \"%s\": %d bytes at 0x%x\n", initrd_name, meminfo->size, meminfo->addr);
                if(f_read(&initrd, (char*)meminfo->addr, meminfo->size, &bytes_read) != FR_OK || 
                        bytes_read != meminfo->size){
                    cprintf("Unable to load initrd.\n");
                    /* if loading initrd fails, we replace this bootinfo record with BI_LAST */
                }else{
                    bootinfo = (struct bi_record*)(((char*)bootinfo) + bootinfo->size);
                }
                f_close(&initrd);
            }else if(initrd_name){
                cprintf("Unable to open \"%s\": No initrd.\n", initrd_name);
            }

            /* terminate the bootinfo structure */
            bootinfo->tag = BI_LAST;
            bootinfo->size = sizeof(struct bi_record);

            /* Linux expects us to enter with:
             * - interrupts disabled (_run_us_mode does this for us)
             * - CPU cache disabled
             * - CPU in supervisor mode
             */
            umode = false; /* force supervisor mode */
            cpu_cache_disable(); /* disable cache */
        }
	else {
            /* not linux */
#if 1
	    umode = usermode;
#else            
            for(i=1; i<numarg; i++){
                switch(arg[i][0]){
                    case 'u':
                    case 'U':
                        usermode = true;
                        break;
                    case 's':
                    case 'S':
                        usermode = false;
                        break;
                    default:
                        cprintf("Unrecognised argument \"%s\".\n", arg[i]);
                        return false;
                }
            }
#endif

	/* restore command line to buffer */
		kernel_cmdline[0] = 0;
		for (i=1; i < numarg; i++) {
			strncat(kernel_cmdline, " ", MAXCMDLEN);
			strncat(kernel_cmdline, arg[i], MAXCMDLEN );
		}
		cprintf("COMMAND LINE: ||%s||\n", kernel_cmdline);
		*(char**)0x000000 = kernel_cmdline;	/* which is on the STACK */

	/* check for FUZIX 68k stuff at the normal entry point */
		if ( *(long*)header.entry == 0x1505C0DE ) {
			header.entry += 4;
			umode = false;		/* must start in Supervisor mode */
		}
        }
        cprintf("Entry at 0x%x in %s mode\n", header.entry, umode ? "user" : "supervisor");
	run_program(umode, (void*)header.entry);
    } /* else not (linux) */

    return true;
}

bool is_cmd_head(char *cp, int len)
{
	int i;
	bool yes = true;

	for (i=0; i<len && yes; i++, cp++) {
		yes &= (isprint(*cp) ||
			 *cp==0x0d ||
			 *cp==0x0a ||
			 *cp==0x09);
	}
	return yes;	
}

static
const char *exts[] = {
	"CMD", "ELF", "OUT", "68K", "SYS", NULL
};

char *extend_filename(char *argv[])
{
	char *np, *tp;
	int i, j;
	
	np = argv[0];
	if ( f_stat(np, NULL) == FR_OK ) return np;
	
	j = strlen(np);
	tp = np + j;
	while (--tp) {
		if (tp == np || *tp == '/' || *tp == ':' || *tp == '\\' ) {
				/* there was no qualification on the name */
			strcpy(np-FUDGE, np);
			np -= FUDGE;
			argv[0] = np;
			tp = np + j;	/* place for suffix tries */
			*tp++ = '.';	/* add the dot for the suffix */
			i = 0;
			while (exts[i]) {
				strcpy(tp, exts[i]);
				if (f_stat(np, NULL) == FR_OK) return np;
				++i;
			}
			*--tp = 0;  /* erase the added dot */
			return NULL;
		}
		if (*tp == '.') break;	/* name was qualified, but not found */
	}

	return NULL;	
}



#define HEADER_EXAMINE_SIZE 4 /* number of bytes we need to load to determine the file type */
const char coff_header_bytes[2] = { 0x01, 0x50 };
const char elf_header_bytes[4]  = { 0x7F, 0x45, 0x4c, 0x46 };
const char m68k_header_bytes[2] = { 0x60, 0x1a };

bool handle_cmd_executable(char *arg[], int numarg)
{
    FIL fd;
    FRESULT fr;
    char buffer[HEADER_EXAMINE_SIZE];
    unsigned int br;
    
    if (extend_filename(arg) == NULL) return false;

    fr = f_open(&fd, arg[0], FA_READ);

    if(fr == FR_NO_FILE || fr == FR_NO_PATH) /* file doesn't exist? */
        return false;

    if(fr != FR_OK){
        cprintf("%s: Cannot load: ", arg[0]);
        f_perror(fr);
        return true; /* we tried and failed */
    }

    memset(buffer, 0, HEADER_EXAMINE_SIZE);

    cprintf("%s: %d bytes, ", arg[0], f_size(&fd));

    /* sniff the first few bytes, then rewind to the start of the file */
    fr = f_read(&fd, buffer, HEADER_EXAMINE_SIZE, &br);
    f_lseek(&fd, 0);

    if(fr == FR_OK){
        if(memcmp(buffer, elf_header_bytes, sizeof(elf_header_bytes)) == 0){
            cprintf("ELF.\n");
            load_elf_executable(arg, numarg, &fd);
        }else if(memcmp(buffer, coff_header_bytes, sizeof(coff_header_bytes)) == 0){

            cprintf("COFF.\n");
            load_coff_executable(arg, numarg, &fd);
        }else if(memcmp(buffer, m68k_header_bytes, sizeof(m68k_header_bytes)) == 0){
            cprintf("68K or SYS\n");
            load_m68k_executable(arg, numarg, &fd);
        }else if(is_cmd_head(buffer, HEADER_EXAMINE_SIZE)) {
	    cprintf("Command file.\n");
	    load_command_file(arg, numarg, &fd);
        }else{
            cprintf("unknown format.\n");
            load_flat_executable(arg, numarg, &fd);
        }
    }else{
        cprintf("%s: Cannot read: ", arg[0]);
        f_perror(fr);
    }

    f_close(&fd);

    return true;
}



#define MAXARG 40
int execute_cmd(t_handler *handle_any, char *linebuffer)
{
    char *p, *arg[MAXARG+1];
    int numarg;

    /* parse linebuffer into list of args */
    numarg = 0;
    p = linebuffer;
    while(true){
        if(numarg == MAXARG){
            cprintf("Limiting to %d arguments.\n", numarg);
            *p = 0;
        }
        if(!*p){ /* end of string? */
            arg[numarg] = 0;
            break;
        }
        while(isspace(*p))
            p++;
        if(!isspace(*p)){
            arg[numarg++] = p;
            while(*p && !isspace(*p))
                p++;
            if(!*p)
                continue;
            while(isspace(*p)){
                *p=0;
                p++;
            }
        }
    }
    return (*handle_any)(arg, numarg);
}

int handle_any_command(char *argv[], int argc) {
    if(argc > 0){
        if(!handle_cmd_builtin(argv, argc) &&
                !handle_cmd_executable(argv, argc)) {
            cprintf("%s: Unknown command.  Try 'help'.\n", argv[0]);
	    return 1;
	}
    }
    return 0;
}

int main68(void)
{
	int i;
extern DSTATUS drive_status[_VOLUMES];
extern T_nv_struct  nvram;  /* non-volatile RAM in the DS1302 */

#if !RETAIL
	lites(0xA5);
	cprintf("debuglevel %hd\n", debug);
#endif

	cpu_cache_disable();	/* needed to make PPIDE work ?? */
	usermode = true;	/* good modal start value */
/* for 'do_dump' */
	dm_count = 0x80;
	dm_start = 0;

    /* set up work areas for each volume */
    for(i=0; i<_VOLUMES; i++){
    	drive_status[i] = STA_NOINIT;
        inputbuffer[0] = '0' + i;
        inputbuffer[1] = ':';
        inputbuffer[2] = 0;
        f_mount(&fat_fs_workarea[i], inputbuffer, 0); /* permit lazy mounting */
    }

    /* set the initial boot drive */
    inputbuffer[0] = 'A' + nvram.boot_disk_1;
    inputbuffer[1] = ':';
    inputbuffer[2] = 0;
    execute_cmd(&handle_any_command, inputbuffer);

	/* check for autoboot possible */
	if (nvram.autoboot && f_stat(AUTOBOOT, NULL) == FR_OK) {
			/* N seconds to auto-boot */
		auto_boot_time = (dword)daytime_c(1) + nvram.autoboot;
		cprintf("Auto boot in %d seconds; hit any key to cancel.\r\n", (int)nvram.autoboot);
	} else	auto_boot_time = 0;		/* defeat auto-boot */
	
    while(true){
    	cmd_level = 0;
        f_getcwd(inputbuffer, LINELEN/sizeof(TCHAR));
    /* there are better ways to do this:     */
        if ('0'<=inputbuffer[0] && inputbuffer[0]<='9') inputbuffer[0] += 'C'-'0';
        putch( usermode ? '-' : '+' );
        cprintf("%s> ", inputbuffer);
        getline(inputbuffer, LINELEN);
        execute_cmd(&handle_any_command, inputbuffer);
    }


	return 0;
}

