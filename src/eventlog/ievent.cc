//=========================================================================
//  IEVENTLOG.CC - part of
//                  OMNeT++/OMNEST
//           Discrete System Simulation in C++
//
//=========================================================================

/*--------------------------------------------------------------*
  Copyright (C) 1992-2006 Andras Varga

  This file is distributed WITHOUT ANY WARRANTY. See the file
  `license' for details on this and other legal matters.
*--------------------------------------------------------------*/

#include "ievent.h"

IEvent::IEvent()
{
    nextEvent = NULL;
    previousEvent = NULL;
}

void IEvent::linkEvents(IEvent *previousEvent, IEvent *nextEvent)
{
    // used to build the linked list
    previousEvent->nextEvent = nextEvent;
    nextEvent->previousEvent = previousEvent;
}

void IEvent::unlinkEvents(IEvent *previousEvent, IEvent *nextEvent)
{
    // used to build the linked list
    previousEvent->nextEvent = NULL;
    nextEvent->previousEvent = NULL;
}
