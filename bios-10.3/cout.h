/* cout.h */

#pragma pack(2)
struct hdr {
        uint16 ch_magic;         /*c.out magic number 060016 = $600E*/
        uint32 ch_tsize;          /*text size*/
        uint32 ch_dsize;          /*data size*/
        uint32 ch_bsize;          /*bss size*/
        uint32 ch_ssize;          /*symbol table size*/
        uint32 ch_stksize;        /*stack size*/
        uint32 ch_entry;          /*entry point*/
        uint16 ch_rlbflg;        /*relocation bits suppressed flag*/
};

#define MAGIC   0x601a      /* bra .+26 instruction*/
#define MAGIC_M68K  0x601a  /* second definition */


/* end cout.h */

