/**
 *  \file timer.h
 *  \brief Timer support
 *  \author Stephane Dallongeville
 *  \date 08/2011
 *
 * This unit provides basic timer functions (useful for profiling).<br>
 * This unit uses V-Int to count frame so disabling V-Int will make timer methods to not work anymore.
 */

#ifndef _TIMER_H_
#define _TIMER_H_

#if defined(__cplusplus)
extern "C"
{
#endif


/**
 *  \brief
 *      Number of subtick per second.
 */
#define SUBTICKPERSECOND    76800
/**
 *  \brief
 *      Number of tick per second.
 */
#define TICKPERSECOND       300
/**
 *  \brief
 *      Time sub division per second.
 */
#define TIMEPERSECOND       256

/**
 *  \brief
 *      Maximum number of timer.
 */
#define MAXTIMER            16

extern vu32 vtimer;


/**
 *  \brief
 *      Returns elapsed subticks from console reset.
 *
 * Returns elapsed subticks from console reset (1/76800 second based).<br>
 * <b>WARNING:</b> this function isn't accurate during VBlank (return fixed value for the whole VBlank).<br>
 * This is to avoid issue with the VCounter rollback during VBlank.
 */
u32  getSubTick(void);
/**
 *  \brief
 *      Returns elapsed ticks from console reset.
 *
 * Returns elapsed ticks from console reset (1/300 second based).
 */
u32  getTick(void);

/**
 *  \brief
 *      Returns elapsed time from console reset.
 *
 *  \param fromTick
 *      Choose tick or sub tick (more accurate) calculation.
 *
 * Returns elapsed time from console reset (1/256 second based).
 */
u32  getTime(u16 fromTick);
/**
 *  \brief
 *      Returns elapsed time in second from console reset.
 *
 *  \param fromTick
 *      Choose tick or sub tick (more accurate) calculation.
 *
 * Returns elapsed time in second from console reset.<br>
 * Value is returned as fix32.
 */
fix32 getTimeAsFix32(u16 fromTick);

/**
 *  \brief
 *      Start internal timer (0 <= numtimer < MAXTIMER)
 *
 *  \param numTimer
 *      Timer number (0-MAXTIMER)
 */
void startTimer(u16 numTimer);
/**
 *  \brief
 *      Get elapsed subticks for specified timer.
 *
 *  \param numTimer
 *      Timer number (0-MAXTIMER)
 *  \param restart
 *      Restart timer if TRUE
 *
 * Returns elapsed subticks from last call to startTimer(numTimer).
 */
u32  getTimer(u16 numTimer, u16 restart);

/**
 *  \brief
 *      Wait for a certain amount of subticks (1/76800 second based).
 *
 *  \param subtick
 *      Number of subtick to wait for.
 *
 * <b>WARNING:</b> this function isn't accurate during VBlank (always wait until the end of VBlank) because of the VCounter rollback.
 */
void waitSubTick(u32 subtick);
/**
 *  \brief
 *      Wait for a certain amount of ticks (1/300 second based).
 *
 *  \param tick
 *      Number of tick to wait for.
 *
 * <b>WARNING:</b> 5/6 (PAL/NTSC) ticks based timer so use 5 or 6 ticks as minimum wait value.
 */
void waitTick(u32 tick);
/**
 *  \brief
 *      Wait for a certain amount of millisecond.
 *
 *  \param ms
 *      Number of millisecond to wait for.
 *
 * <b>WARNING:</b> ~3.33 ms based timer is used when 'ms' is >= 100.
 */
void waitMs(u32 ms);


#if defined(__cplusplus)
} // extern "C"
#endif

#endif // _TIMER_H_
