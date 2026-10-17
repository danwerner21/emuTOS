# 1 "cprintf.c"
# 1 "<built-in>"
# 1 "<command line>"
# 1 "cprintf.c"
# 19 "cprintf.c"
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/stdlib.h" 1 3 4
# 10 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/stdlib.h" 3 4
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/_ansi.h" 1 3 4
# 15 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/_ansi.h" 3 4
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/newlib.h" 1 3 4
# 16 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/_ansi.h" 2 3 4
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/config.h" 1 3 4



# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/machine/ieeefp.h" 1 3 4
# 5 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/config.h" 2 3 4
# 17 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/_ansi.h" 2 3 4
# 11 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/stdlib.h" 2 3 4



# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/include/stddef.h" 1 3 4
# 214 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/include/stddef.h" 3 4
typedef long unsigned int size_t;
# 326 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/include/stddef.h" 3 4
typedef long int wchar_t;
# 15 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/stdlib.h" 2 3 4

# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 1 3 4
# 13 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 3 4
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/_ansi.h" 1 3 4
# 14 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 2 3 4
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/_types.h" 1 3 4
# 12 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/_types.h" 3 4
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/lock.h" 1 3 4





typedef int _LOCK_T;
typedef int _LOCK_RECURSIVE_T;
# 13 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/_types.h" 2 3 4

typedef long _off_t;
__extension__ typedef long long _off64_t;


typedef int _ssize_t;





# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/include/stddef.h" 1 3 4
# 355 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/include/stddef.h" 3 4
typedef unsigned int wint_t;
# 25 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/_types.h" 2 3 4


typedef struct
{
  int __count;
  union
  {
    wint_t __wch;
    unsigned char __wchb[4];
  } __value;
} _mbstate_t;

typedef _LOCK_RECURSIVE_T _flock_t;


typedef void *_iconv_t;
# 15 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 2 3 4




typedef unsigned long __ULong;
# 40 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 3 4
struct _Bigint
{
  struct _Bigint *_next;
  int _k, _maxwds, _sign, _wds;
  __ULong _x[1];
};


struct __tm
{
  int __tm_sec;
  int __tm_min;
  int __tm_hour;
  int __tm_mday;
  int __tm_mon;
  int __tm_year;
  int __tm_wday;
  int __tm_yday;
  int __tm_isdst;
};







struct _on_exit_args {
 void * _fnargs[32];
 void * _dso_handle[32];

 __ULong _fntypes;


 __ULong _is_cxa;
};
# 85 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 3 4
struct _atexit {
 struct _atexit *_next;
 int _ind;

 void (*_fns[32])(void);
        struct _on_exit_args _on_exit_args;
};
# 101 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 3 4
struct __sbuf {
 unsigned char *_base;
 int _size;
};






typedef long _fpos_t;
# 166 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 3 4
struct __sFILE {
  unsigned char *_p;
  int _r;
  int _w;
  short _flags;
  short _file;
  struct __sbuf _bf;
  int _lbfsize;






  void * _cookie;

  int (*_read) (void * _cookie, char *_buf, int _n);
  int (*_write) (void * _cookie, const char *_buf, int _n);

  _fpos_t (*_seek) (void * _cookie, _fpos_t _offset, int _whence);
  int (*_close) (void * _cookie);


  struct __sbuf _ub;
  unsigned char *_up;
  int _ur;


  unsigned char _ubuf[3];
  unsigned char _nbuf[1];


  struct __sbuf _lb;


  int _blksize;
  int _offset;


  struct _reent *_data;



  _flock_t _lock;

};
# 259 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 3 4
typedef struct __sFILE __FILE;


struct _glue
{
  struct _glue *_next;
  int _niobs;
  __FILE *_iobs;
};
# 290 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 3 4
struct _rand48 {
  unsigned short _seed[3];
  unsigned short _mult[3];
  unsigned short _add;




};
# 565 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 3 4
struct _reent
{
  int _errno;




  __FILE *_stdin, *_stdout, *_stderr;

  int _inc;
  char _emergency[25];

  int _current_category;
  const char *_current_locale;

  int __sdidinit;

  void (*__cleanup) (struct _reent *);


  struct _Bigint *_result;
  int _result_k;
  struct _Bigint *_p5s;
  struct _Bigint **_freelist;


  int _cvtlen;
  char *_cvtbuf;

  union
    {
      struct
        {
          unsigned int _unused_rand;
          char * _strtok_last;
          char _asctime_buf[26];
          struct __tm _localtime_buf;
          int _gamma_signgam;
          __extension__ unsigned long long _rand_next;
          struct _rand48 _r48;
          _mbstate_t _mblen_state;
          _mbstate_t _mbtowc_state;
          _mbstate_t _wctomb_state;
          char _l64a_buf[8];
          char _signal_buf[24];
          int _getdate_err;
          _mbstate_t _mbrlen_state;
          _mbstate_t _mbrtowc_state;
          _mbstate_t _mbsrtowcs_state;
          _mbstate_t _wcrtomb_state;
          _mbstate_t _wcsrtombs_state;
        } _reent;



      struct
        {

          unsigned char * _nextf[30];
          unsigned int _nmalloc[30];
        } _unused;
    } _new;


  struct _atexit *_atexit;
  struct _atexit _atexit0;


  void (**(_sig_func))(int);




  struct _glue __sglue;
  __FILE __sf[3];
};
# 799 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/reent.h" 3 4
extern struct _reent *_impure_ptr ;
extern struct _reent *const _global_impure_ptr ;

void _reclaim_reent (struct _reent *);
# 17 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/stdlib.h" 2 3 4
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/machine/stdlib.h" 1 3 4
# 18 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/stdlib.h" 2 3 4
# 26 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/stdlib.h" 3 4


typedef struct
{
  int quot;
  int rem;
} div_t;

typedef struct
{
  long quot;
  long rem;
} ldiv_t;
# 57 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/stdlib.h" 3 4
extern int __mb_cur_max;



void abort (void) __attribute__ ((noreturn));
int abs (int);
int atexit (void (*__func)(void));
double atof (const char *__nptr);



int atoi (const char *__nptr);
int _atoi_r (struct _reent *, const char *__nptr);
long atol (const char *__nptr);
long _atol_r (struct _reent *, const char *__nptr);
void * bsearch (const void * __key, const void * __base, size_t __nmemb, size_t __size, int (* _compar) (const void *, const void *));




void * calloc (size_t __nmemb, size_t __size);
div_t div (int __numer, int __denom);
void exit (int __status) __attribute__ ((noreturn));
void free (void *);
char * getenv (const char *__string);
char * _getenv_r (struct _reent *, const char *__string);
char * _findenv (const char *, int *);
char * _findenv_r (struct _reent *, const char *, int *);
long labs (long);
ldiv_t ldiv (long __numer, long __denom);
void * malloc (size_t __size);
int mblen (const char *, size_t);
int _mblen_r (struct _reent *, const char *, size_t, _mbstate_t *);
int mbtowc (wchar_t *, const char *, size_t);
int _mbtowc_r (struct _reent *, wchar_t *, const char *, size_t, _mbstate_t *);
int wctomb (char *, wchar_t);
int _wctomb_r (struct _reent *, char *, wchar_t, _mbstate_t *);
size_t mbstowcs (wchar_t *, const char *, size_t);
size_t _mbstowcs_r (struct _reent *, wchar_t *, const char *, size_t, _mbstate_t *);
size_t wcstombs (char *, const wchar_t *, size_t);
size_t _wcstombs_r (struct _reent *, char *, const wchar_t *, size_t, _mbstate_t *);






void qsort (void * __base, size_t __nmemb, size_t __size, int(*_compar)(const void *, const void *));
int rand (void);
void * realloc (void * __r, size_t __size);
void srand (unsigned __seed);
double strtod (const char *__n, char **__end_PTR);
double _strtod_r (struct _reent *,const char *__n, char **__end_PTR);
float strtof (const char *__n, char **__end_PTR);






long strtol (const char *__n, char **__end_PTR, int __base);
long _strtol_r (struct _reent *,const char *__n, char **__end_PTR, int __base);
unsigned long strtoul (const char *__n, char **__end_PTR, int __base);
unsigned long _strtoul_r (struct _reent *,const char *__n, char **__end_PTR, int __base);

int system (const char *__string);
# 183 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/stdlib.h" 3 4
char * _dtoa_r (struct _reent *, double, int, int, int *, int*, char**);

void * _malloc_r (struct _reent *, size_t);
void * _calloc_r (struct _reent *, size_t, size_t);
void _free_r (struct _reent *, void *);
void * _realloc_r (struct _reent *, void *, size_t);
void _mstats_r (struct _reent *, char *);

int _system_r (struct _reent *, const char *);

void __eprintf (const char *, const char *, unsigned int, const char *);


# 20 "cprintf.c" 2
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/include/stdarg.h" 1 3 4
# 43 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/include/stdarg.h" 3 4
typedef __builtin_va_list __gnuc_va_list;
# 105 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/include/stdarg.h" 3 4
typedef __gnuc_va_list va_list;
# 21 "cprintf.c" 2
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/string.h" 1 3 4
# 14 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/string.h" 3 4
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/include/stddef.h" 1 3 4
# 15 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/string.h" 2 3 4







void * memchr (const void *, int, size_t);
int memcmp (const void *, const void *, size_t);
void * memcpy (void *, const void *, size_t);
void * memmove (void *, const void *, size_t);
void * memset (void *, int, size_t);
char *strcat (char *, const char *);
char *strchr (const char *, int);
int strcmp (const char *, const char *);
int strcoll (const char *, const char *);
char *strcpy (char *, const char *);
size_t strcspn (const char *, const char *);
char *strerror (int);
size_t strlen (const char *);
char *strncat (char *, const char *, size_t);
int strncmp (const char *, const char *, size_t);
char *strncpy (char *, const char *, size_t);
char *strpbrk (const char *, const char *);
char *strrchr (const char *, int);
size_t strspn (const char *, const char *);
char *strstr (const char *, const char *);


char *strtok (char *, const char *);


size_t strxfrm (char *, const char *, size_t);
# 99 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/string.h" 3 4
# 1 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/sys/string.h" 1 3 4
# 100 "/usr/cross/m68k-elf/lib/gcc/m68k-elf/4.1.1/../../../../m68k-elf/sys-include/string.h" 2 3 4


# 22 "cprintf.c" 2





int _con_out(char);







static unsigned char * __numout(long i, int base, unsigned char out[]);

int cprintf(const char * fmt, ...)
{
   register int c;
   int count = 0;
   int type, base;
   long val;
   char * cp;
   char padch=' ';
   int minsize, maxsize;
   unsigned char out[11 +1];
   va_list ap;

   __builtin_va_start(ap,fmt);

   while((c=*fmt++))
   {
      count++;
      if(c!='%')
      {
  if (c=='\n') _con_out((char)'\r');
  _con_out((char)c);
      }
      else
      {
  type=1;
  padch = *fmt;
  maxsize=minsize=0;
  if(padch == '-') fmt++;

  for(;;)
  {
     c=*fmt++;
     if( c<'0' || c>'9' ) break;
     minsize*=10; minsize+=c-'0';
  }

  if( c == '.' )
     for(;;)
     {
        c=*fmt++;
        if( c<'0' || c>'9' ) break;
        maxsize*=10; maxsize+=c-'0';
     }

  if( padch == '-' ) minsize = -minsize;
  else
  if( padch != '0' ) padch=' ';

  if( c == 0 ) break;
  if(c=='h')
  {
     c=*fmt++;
     type = 0;
  }
  else if(c=='l')
  {
     c=*fmt++;
     type = 2;
  }

  switch(c)
  {
     case 'X':
     case 'x': base=16; type |= 4; if(0) {
     case 'o': base= 8; type |= 4; } if(0) {
     case 'u': base=10; type |= 4; } if(0) {
     case 'd': base=-10; }
        switch(type)
        {
    case 0: val=(short)(__builtin_va_arg(ap,int)); break;
    case 1: val=__builtin_va_arg(ap,int); break;
    case 2: val=__builtin_va_arg(ap,long); break;
    case 4: val=(unsigned short)__builtin_va_arg(ap,unsigned int); break;
    case 5: val=__builtin_va_arg(ap,unsigned int); break;
    case 6: val=__builtin_va_arg(ap,unsigned long); break;
    default:val=0; break;
        }
        cp = (char*) __numout(val,base,out);
        if(0) {
     case 's':
           cp=__builtin_va_arg(ap,char *);
        }
        count--;
        c = strlen(cp);
        if( !maxsize ) maxsize = c;
        if( minsize > 0 )
        {
    minsize -= c;
    while(minsize>0) { _con_out((char)padch); count++; minsize--; }
    minsize=0;
        }
        if( minsize < 0 ) minsize= -minsize-c;
        while(*cp && maxsize-->0 )
        {
    _con_out((char)*cp++);
    count++;
        }
        while(minsize>0) { _con_out((char)' '); count++; minsize--; }
        break;
     case 'c':
        _con_out((char)__builtin_va_arg(ap,int));
        break;
     default:
        _con_out((char)c);
        break;
  }
      }
   }
   __builtin_va_end(ap);
   return count;
}

const char nstring[]="0123456789ABCDEF";



static unsigned char *

__numout(long i, int base, unsigned char out[])
{
   int n;
   int flg = 0;
   unsigned long val;

   if (base<0)
   {
      base = -base;
      if (i<0)
      {
  flg = 1;
  i = -i;
      }
   }
   val = i;

   out[11] = '\0';
   n = 11 -1;
   do
   {

      out[n--] = nstring[val % base];
      val /= base;




   }
   while(val);
   if(flg) out[n--] = '-';
   return &out[n+1];
}
