OUTPUT_ARCH(m68k)
SEARCH_DIR(.)
/*GROUP(-lbcc -lc -lgcc)*/
__DYNAMIC  =  0;

/*
 * Setup the memory map of the SEGA Genesis.
 * stack grows down from high memory.
 *
 * The memory map look like this:
 * +--------------------+ <- low memory
 * | .text              |
 * |        _etext      |
 * |        ctor list   | the ctor and dtor lists are for
 * |        dtor list   | C++ support
 * +--------------------+
 * .                    .
 * .                    .
 * .                    .
 * +--------------------+ <- 0xE0FF0000
 * | .data              | initialized data goes here
 * |        _data       |
 * |        _edata      |
 * +--------------------+
 * | .bss               |
 * |        _bstart     | start of bss, cleared by crt0
 * |        _bend       | start of heap, used by sbrk()
 * +--------------------+
 * .                    .
 * .                    .
 * .                    .
 * |        __stack     | top of stack
 * +--------------------+ <- 0xE1000000
 */
MEMORY
{
	rom (rx) : ORIGIN = 0x00000000, LENGTH = 0xE0000000
	ram : ORIGIN = 0xE0FF0000, LENGTH = 0x00010000
}

/*
 * allocate the stack to be at the top of memory, since the stack
 * grows down
 */

PROVIDE (__stack = 0xE1000000);


SECTIONS
{
  .text 0x00000000:
  {
    KEEP(*(.text.keepboot)) *(.text.*) *(.text)
    . = ALIGN(0x4);
    __PRE_INIT_ARRAY_LIST__ = .;
    LONG((__PRE_INIT_ARRAY_END__ - __PRE_INIT_ARRAY_LIST__) / 4 - 2)
    KEEP(*(SORT(.preinit_array.*)))
    *(.preinit_array)
    LONG(0)
    __PRE_INIT_ARRAY_END__ = .;
     __CTOR_LIST__ = .;
    LONG((__CTOR_END__ - __CTOR_LIST__) / 4 - 2)
    KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
    *(.init_array .ctors)
    LONG(0)
    __CTOR_END__ = .;
    __DTOR_LIST__ = .;
    LONG((__DTOR_END__ - __DTOR_LIST__) / 4 - 2)
    KEEP(*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
    *(.fini_array .dtors)
    LONG(0)
    __DTOR_END__ = .;

    *(.rodata .rodata.*)
    *(.gcc_except_table .gcc_except_table.*)

    . = ALIGN(0x4);
    __INIT_SECTION__ = . ;
    *(.init)
    SHORT (0x4E75)	/* rts */

    __FINI_SECTION__ = . ;
    *(.fini)
    SHORT (0x4E75)	/* rts */

    _etext = .;
    *(.lit)

    *(.rodata_bin)
    *(.rodata_binf)
  } > rom
  _stext = SIZEOF (.text);

  .data 0xE0FF0000 :
  AT ( ADDR (.text) + SIZEOF (.text) )
  {
    *(.got.plt) *(.got)
    *(.shdata)
    *(.data .data.*)
    *(.ramprog .ramprog.*)
    _edata = .;
  } > ram
  _sdata = SIZEOF (.data);

  .bss 0xE0FF0000 + SIZEOF (.data) :
  {
    _start = . ;
    *(.shbss)
    *(.bss .bss.*)
    *(COMMON)
    _bend = . ;
  } > ram

  .stab 0 (NOLOAD) :
  {
    *(.stab)
  }

  .stabstr 0 (NOLOAD) :
  {
    *(.stabstr)
  }

  .eh_frame 0 (NOLOAD) :
  {
    *(.eh_frame)
  }
}
