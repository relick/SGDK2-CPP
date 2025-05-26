#ifndef _GENESIS_H_
#define _GENESIS_H_

#if defined(__cplusplus)
extern "C"
{
#endif

#define SGDK_VERSION    2.12

#include "SGDK/types.h"

#define SGDK            TRUE

#include "SGDK/config.h"
#include "SGDK/asm.h"

#include "SGDK/sys.h"
#include "SGDK/sram.h"
#include "SGDK/mapper.h"
#include "SGDK/memory.h"
#include "SGDK/tools.h"

#include "SGDK/pool.h"
#include "SGDK/object.h"

#include "SGDK/font.h"
#include "SGDK/str.h"

#include "SGDK/tab_cnv.h"

#include "SGDK/maths.h"
#include "SGDK/maths3D.h"

#include "SGDK/vdp.h"
#include "SGDK/vdp_bg.h"
#include "SGDK/vdp_spr.h"
#include "SGDK/vdp_tile.h"
#include "SGDK/vdp_pal.h"

#include "SGDK/pal.h"

#include "SGDK/vram.h"
#include "SGDK/dma.h"

#include "SGDK/map.h"

#include "SGDK/bmp.h"
#include "SGDK/sprite_eng.h"
#include "SGDK/sprite_eng_legacy.h"

#include "SGDK/z80_ctrl.h"
#include "SGDK/ym2612.h"
#include "SGDK/psg.h"

#include "SGDK/snd/sound.h"
#include "SGDK/snd/xgm.h"
#include "SGDK/snd/xgm2.h"
#include "SGDK/snd/smp_null.h"
#include "SGDK/snd/smp_null_dpcm.h"
#include "SGDK/snd/pcm/snd_pcm.h"
#include "SGDK/snd/pcm/snd_dpcm2.h"
#include "SGDK/snd/pcm/snd_pcm4.h"

#include "SGDK/joy.h"
#include "SGDK/timer.h"

#include "SGDK/task.h"

// modules
#if (MODULE_EVERDRIVE != 0)
#include "SGDK/ext/everdrive.h"
#endif

#if (MODULE_FAT16 != 0)
#include "SGDK/ext/fat16.h"
#endif

#if (MODULE_MEGAWIFI != 0)
#include "SGDK/ext/mw/megawifi.h"
#endif

#if (MODULE_FLASHSAVE != 0)
#include "SGDK/ext/flash-save/flash.h"
#include "SGDK/ext/flash-save/saveman.h"
#endif

#if (MODULE_CONSOLE != 0)
#include "SGDK/ext/console.h"
#endif

// preserve compatibility with old resources name
#define logo_lib sgdk_logo
#define font_lib font_default
#define font_pal_lib font_pal_default

#if defined(__cplusplus)
} // extern "C"
#endif

#endif // _GENESIS_H_
