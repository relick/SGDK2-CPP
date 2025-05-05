/**
 *  \file kdebug.h
 *  \brief Gens KMod debug methods
 *  \author Kaneda
 *  \date XX/20XX
 *
 * This unit provides Gens KMod debug methods support.
 */

#ifndef _KDEBUG_H_
#define _KDEBUG_H_

#if defined(__cplusplus)
extern "C"
{
#endif


extern void KDebug_Halt(void);
extern void KDebug_Alert(const char *str);
extern void KDebug_AlertNumber(u32 nVal);
extern void KDebug_StartTimer(void);
extern void KDebug_StopTimer(void);


#if defined(__cplusplus)
} // extern "C"
#endif

#endif // _KDEBUG_H_
