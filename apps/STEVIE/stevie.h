/*
 * STevie - ST editor for VI enthusiasts.    ...Tim Thompson...twitch!tjt...
 *
 * Extensive modifications by:  Tony Andrews       onecom!wldrdg!tony
 *
 * Savaged to compile under modern gcc and improved (haha) by: George Nakos  ggn@atari.org
 *
 */

#define ATARI		1	/* For the Atari 520 ST */

#define HELP

#define FILELENG 64000
#define NORMAL 0
#define CMDLINE 1
#define INSERT 2
#define APPEND 3
#define FORWARD 4
#define BACKWARD 5
#define WORDSEP " \t\n()[]{},;:'\"-="
#define SLOP 512

#define TRUE 1
#define FALSE 0
#define LINEINC 1

#define CHANGED Changed=1
#define UNCHANGED Changed=0

#define LINEOF(x) x->linep->num

#ifndef INLINE
#ifdef __PUREC__
#define INLINE
#else
#define INLINE inline
#endif
#endif

#ifndef NULL
#define NULL        ((void *)0)
#endif

#include "param.h"
#include "ascii.h"
#include "term.h"
#include "keymap.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __PUREC__
#include <tos.h>
#else
#include <osbind.h>
#endif

typedef int bool_t;
typedef unsigned short UWORD;
typedef short WORD;
typedef unsigned int ULONG;
typedef short LONG;
typedef unsigned char UBYTE;
typedef char BYTE;

struct charinfo {
	char ch_size;
	char *ch_str;
};

struct	_line {
	struct	_line	*prev, *next;	/* previous and next lines */
	char	*s;			/* text for this line */
	int	size;			/* actual size of space at 's' */
	unsigned int	num;		/* line "number" */
}; 

struct	_lptr {
	struct	_line	*linep;		/* line we're referencing */
	int	index;			/* position within that line */
}; 

typedef	struct _line	LINEX;
typedef	struct _lptr	LPTR;

extern struct charinfo chars[];
extern int State;
extern int Rows;
extern int Columns;
extern char *Realscreen;
extern char *Nextscreen;
extern char *Filename;
extern LPTR *Filemem;
extern LPTR *Fileend;
extern LPTR *Topchar;
extern LPTR *Botchar;
extern LPTR *Curschar;
extern LPTR *Insstart;
extern int Cursrow, Curscol, Cursvcol;
extern int Prenum;
extern bool_t Debug;
extern bool_t Changed;
extern char Redobuff[], Undobuff[], Insbuff[];
extern LPTR *Uncurschar;
extern char *Insptr;
extern int Ninsert, Undelchars;
extern bool_t set_want_col;
extern int Curswant;
extern bool_t did_ai;
extern void *fontright;
extern void *fontleft;
extern ULONG *phys;

/* Global functions */

extern char *strsave(char *string);
extern char *alloc(unsigned size); 
extern LPTR *nextline(LPTR *curr);
extern LPTR *prevline(LPTR *curr); 
extern LPTR *coladvance(LPTR *p, int col); 
extern LPTR *ssearch(int dir, char *str);
extern LPTR *getmark(char c); 
extern LPTR *gotoline(int n); 
extern LINEX *newline(int nchars);
extern LPTR *showmatch(void);
extern LPTR *fwd_word(LPTR *p, int type);
extern LPTR *bck_word(LPTR *p, int type);
extern LPTR *end_word(LPTR *p, int type);
extern void updatetabstoptable(void);

/* Inlined functions */

/*
 * gchar(lp) - get the character at position "lp"
 */
static INLINE int gchar(LPTR *lp)
{
	return (lp->linep->s[lp->index]);
}

/*
 * inc(p)
 *
 * Increment the line pointer 'p' crossing line boundaries as necessary.
 * Return 1 when crossing a line, -1 when at end of file, 0 otherwise.
 */
static INLINE int inc(LPTR *lp)
{
	register char *p = &(lp->linep->s[lp->index]);

	if (*p != NUL) {			/* still within line */
		lp->index++;
		return ((p[1] != NUL) ? 0 : 1);
	}

	if (lp->linep->next != Fileend->linep) {  /* there is a next line */
		lp->index = 0;
		lp->linep = lp->linep->next;
		return 1;
	}

	return -1;
}

/* Prototypes */

/* alloc.c */
bool_t buf1line(void);
bool_t bufempty(void);
bool_t canincrease(int n);
bool_t endofline(LPTR *p);
void filealloc(void);
void freeall(void);
bool_t lineempty(void);
void screenalloc(void);

/* cmdline.c */
void emsg(char *s);
void gotocmd(bool_t clr, char firstc);
void msg(char *s);
void readcmdline(int firstc, char *cmdline);
void smsg(char *s, ...);
void wait_return(void);

/* edit.c */
void beginline(bool_t flag);
void edit(void);
void getout(void);
bool_t onedown(int n);
bool_t oneleft(void);
bool_t oneright(void);
bool_t oneup(int n);
void scrolldown(int nlines);
void scrollup(int nlines);

/* fileio.c */
void filemess(char *s);
bool_t readfile(char *fname, LPTR *fromp, bool_t nochangename);
void renum(void);
bool_t writeit(char *fname, LPTR *start, LPTR *end);

/* help.c */
bool_t help(void);

/* main.c */
void addtobuff(char *s, ...);
bool_t anyinput(void);
void stuffin(char *s);
void stuffnum(int n);
int vgetc(void);
int vpeekc(void);

/* mark.c */
void clrall(void);
void clrmark(LINEX *line);
bool_t setmark(char c);
void setpcmark(void);

/* misccmds.c */
int cntllines(LPTR *pbegin, LPTR *pend);
bool_t delchar(bool_t fixpos);
void delline(int nlines);
void fileinfo(void);
void inschar(int c);
void insstr(char *s);
void opencmd(int dir, int can_ai);
int plines(LPTR *p);

/* normal.c */
char *mkstr(char c);
void normal(int c);

/* param.c */
void doset(char *arg, bool_t inter);

/* ptrfunc.c */
int dec(LPTR *lp);
void pchar(LPTR *lp, char c);
void pswap(LPTR *a, LPTR *b);
bool_t lt(LPTR *a, LPTR *b);
bool_t ltoreq(LPTR *a, LPTR *b);

/* screen.c */
void cursupdate(void);
void preshiftfont(void);
void screenclear(void);
void s_del(int row, int nlines);
void s_ins(int row, int nlines);
void updateline(void);
void updatescreen(void);
void updatetabstoptable(void);

/* search.c */
bool_t crepsearch(int flag);
void dosearch(int dir, char *str);
bool_t findfunc(int dir);
void repsearch(int flag);
bool_t searchc(char c, int dir, int type);
LPTR *showmatch(void);

/* tos.c */
void beep(void);
void my_delay(void);
FILE *fopenb(char *fname, char *mode);
int inchar(void);
void outchar(char c);
void outstr(char *s);
void windexit(int r);
void windgoto(int r, int c);
void windinit(void);
