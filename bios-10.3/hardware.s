# hardware.s
# 2015-09-13 Will Sowerbutts

.ifndef _hardware_s
_hardware_s = 1

# Target selection: set exactly one of BOARD_ variable to 1, others must be 0
.ifndef BOARD_MINI
BOARD_MINI = 0
.else
M68000 = 68000
.endif
.ifndef BOARD_KISS
BOARD_KISS = 0
.else
M68000 = 68030
.endif

.if BOARD_MINI
BOARD_BASE_ECB      = 0x00200000
BOARD_BASE_ROM      = 0xFFF80000
BOARD_MAX_RAM       = 0x00200000
BOARD_MAX_ROM       = 0x00070000	/* 448K -- next 64K used by I/O space */
BOARD_MAX_ECB       = 0x00180000
BOARD_MAX_4MEM      = 0x00100000
BOARD_INIT_SP       = 0x00070000
.endif

.if BOARD_KISS
#  Cache control bits in the 68030 CACR
CACR_EI   = 1       /* Enable Instruction Cache      */
CACR_DI   = 0       /* Disable Instruction Cache     */
CACR_FI   = 1<<1    /* Freeze Instruction Cache      */
CACR_CEI  = 1<<2    /* Clear Entry in Instr. Cache   */
CACR_CI   = 1<<3    /* Clear Instruction Cache       */
CACR_IBE  = 1<<4    /* Instr. Cache Burst Enable     */

CACR_ED   = 1<<8    /* Enable Data Cache             */
CACR_FD   = 1<<9    /* Freeze Data Cache             */
CACR_CED  = 1<<10   /* Clear Entry in Data Cache     */
CACR_CD   = 1<<11   /* Clear Data Cache              */
CACR_DBE  = 1<<12   /* Data Cache Burst Enable       */
CACR_WA   = 1<<13   /* Write Allocate the Data Cache */


BOARD_BASE_ROM      = 0xFFF00000
BOARD_BASE_ECB      = 0xFFF80000
BOARD_BASE_SRAM     = 0xFFFE0000
BOARD_MAX_ROM       = 0x00080000	/* 512K	*/
BOARD_MAX_ECB       = 0x00040000	/* 256K 4MEM window */
BOARD_MAX_SRAM      = 0x00008000	/* 32K SRAM chip */
#BOARD_MAX2_SRAM    = 0x00010000	/* 64K SRAM window maps the same chip twice */
BOARD_MAX_RAM       = 0x10000000	/* 256M */
BOARD_INIT_SP       = 0xFFFE7FF0
BOARD_CACR0         = (CACR_CI + CACR_EI + CACR_CD + CACR_ED)
.endif


/* common to all CPU boards */
BOARD_BASE_IO       = 0xFFFF0000	/* should include bit 15 */

.endif

