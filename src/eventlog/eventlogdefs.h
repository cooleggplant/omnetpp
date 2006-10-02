//=========================================================================
//  EVENTLOGDEFS.H - part of
//                  OMNeT++/OMNEST
//           Discrete System Simulation in C++
//
//=========================================================================

/*--------------------------------------------------------------*
  Copyright (C) 1992-2005 Andras Varga

  This file is distributed WITHOUT ANY WARRANTY. See the file
  `license' for details on this and other legal matters.
*--------------------------------------------------------------*/

#ifndef _EVENTLOGDEFS_H_
#define _EVENTLOGDEFS_H_

#include "exception.h"

// define int64, our equivalent of Java's "long" type
#ifdef _MSC_VER
typedef __int64 int64;
#else
typedef long long int64;
#endif

#ifndef NDEBUG
#define EASSERT(expr)  \
  ((void) ((expr) ? 0 : \
           (throw new Exception("ASSERT: condition %s false, %s line %d", \
                             #expr, __FILE__, __LINE__), 0)))
#else
#define ASSERT(expr)  ((void)0)
#endif

/**
 * variables which store event numbers throughout the API may have these additional values (positive values are real event numbers)
 */
enum EventNumberKind
{
    /**
     * The event number is not yet calculated before.
     */
    EVENT_NOT_YET_CALCULATED = -1,
    /**
     * There is no such event and will never be because it is impossible. (e.g. the previous event of the first event)
     */
    NO_SUCH_EVENT = -2,
    /**
     * The event is not and will never be in the log, although it could be. (e.g. filtered by the user from the file)
     */
    FILTERED_EVENT = -3,
    /**
     * The event is not yet in the log, but it might appear in the future (e.g. simulation not there yet)
     * The last event number is added to the constant and returned.
     * (e.g. reading the event 1000 when the file ends at 100 will give -104)
     */
    EVENT_NOT_YET_REACHED = -4
};

enum MatchKind
{
    EXACT, // means only one key is allowed to match and returns the offset of that key
    FIRST, // multiple matches allowed and returns the first one or the previous if there are not matches at all
    LAST // as FIRST but just the opposite
};

#endif
