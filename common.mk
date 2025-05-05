# Common definitions

M68K_PREFIX := m68k-elf

ifeq ($(GDK),)
	BIN := bin
	LIB := lib
	M68K_TOOLCHAIN := $(M68K_PREFIX)-toolchain
	M68K_BIN := $(M68K_TOOLCHAIN)/bin

	SRC_LIB := src
	RES_LIB := res
	INC_LIB := inc
else ifeq ($(GDK),.)
	BIN := bin
	LIB := lib
	M68K_TOOLCHAIN := $(M68K_PREFIX)-toolchain
	M68K_BIN := $(M68K_TOOLCHAIN)/bin

	SRC_LIB := src
	RES_LIB := res
	INC_LIB := inc
else
	BIN := $(GDK)/bin
	LIB := $(GDK)/lib
	M68K_TOOLCHAIN := $(GDK)/$(M68K_PREFIX)-toolchain
	M68K_BIN := $(M68K_TOOLCHAIN)/bin

	SRC_LIB := $(GDK)/src
	RES_LIB := $(GDK)/res
	INC_LIB := $(GDK)/inc
endif

ifeq ($(OS),Windows_NT)
	# Native Windows
	SHELL := $(BIN)/sh
	RM := $(BIN)/rm
	CP := $(BIN)/cp
	MKDIR := $(BIN)/mkdir

	AR := $(M68K_BIN)/$(M68K_PREFIX)-ar
	CC := $(M68K_BIN)/$(M68K_PREFIX)-gcc
	CXX := $(M68K_BIN)/$(M68K_PREFIX)-g++
	LD := $(M68K_BIN)/$(M68K_PREFIX)-ld
	NM := $(M68K_BIN)/$(M68K_PREFIX)-nm
	OBJCPY := $(M68K_BIN)/$(M68K_PREFIX)-objcopy
	CONVSYM := $(BIN)/convsym
	ASMZ80 := $(BIN)/sjasm
	MACCER := $(BIN)/mac68k
	BINTOS := $(BIN)/bintos
	GCC_VERSION := $(shell $(CC) -dumpversion)
	LTO_PLUGIN := --plugin=$(M68K_TOOLCHAIN)/libexec/gcc/$(M68K_PREFIX)/$(GCC_VERSION)/liblto_plugin.dll
	LIBGCC := $(LIB)/libgcc.a
else
	# Native Linux and Docker
	SHELL := sh
	RM := rm
	CP := cp
	MKDIR := mkdir

	AR := $(M68K_PREFIX)-ar
	CC := $(M68K_PREFIX)-gcc
	CXX := $(M68K_PREFIX)-g++
	LD := $(M68K_PREFIX)-ld
	NM := $(M68K_PREFIX)-nm
	OBJCPY := $(M68K_PREFIX)-objcopy
	CONVSYM := convsym
	ASMZ80 := sjasm
	MACCER := mac68k
	BINTOS := bintos
	LTO_PLUGIN :=
	LIBGCC := -lgcc
endif

JAVA := java
ECHO := echo
SIZEBND := $(JAVA) -jar $(BIN)/sizebnd.jar
RESCOMP := $(JAVA) -jar $(BIN)/rescomp.jar
