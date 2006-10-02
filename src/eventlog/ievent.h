//=========================================================================
//  IEVENT.H - part of
//                  OMNeT++/OMNEST
//           Discrete System Simulation in C++
//
//=========================================================================

/*--------------------------------------------------------------*
  Copyright (C) 1992-2006 Andras Varga

  This file is distributed WITHOUT ANY WARRANTY. See the file
  `license' for details on this and other legal matters.
*--------------------------------------------------------------*/

#ifndef __IEVENT_H_
#define __IEVENT_H_

#include <sstream>
#include "eventlogentry.h"
#include "messagedependency.h"

class IEvent
{
    protected:
        IEvent *previousEvent;
        IEvent *nextEvent;

    public:
        IEvent::IEvent();

        /** 
         * Returns the 'E' entry (line) corresponding to this event.
         */
        virtual EventEntry *getEventEntry() = 0;
        /**
         * Returns the number of log file entries (lines) for this event.
         */
        virtual int getNumEventLogEntries() = 0;
        /**
         * Returns the nth entry (line) for this event.
         */
        virtual EventLogEntry *getEventLogEntry(int index) = 0;

        // some of the data found in the 'E' entry (line), to get additional data query the entries
        virtual long getEventNumber() = 0;
        virtual simtime_t getSimulationTime() = 0;
        virtual long getMessageId() = 0;
        virtual long getCauseEventNumber() = 0;

        /**
         * Returns the immediately preceding event or NULL if there's no such event.
         */
        virtual IEvent *getPreviousEvent() = 0;
        /**
         * Returns the immediately following event or NULL if there's no such event.
         */
        virtual IEvent *getNextEvent() = 0;

        /**
         * Returns the closest preceding event which caused this event by sending a message.
         */
        virtual IEvent *getCauseEvent() = 0; 
        virtual MessageDependency *getCause() = 0;
        virtual MessageDependencyList *getCauses() = 0;
        virtual MessageDependencyList *getConsequences() = 0;

        /**
         * Print all entries of this event.
         */
        virtual void print(FILE *file = stdout) = 0;

        /**
         * Used to maintain the double linked list.
         */
        static void linkEvents(IEvent *previousEvent, IEvent *nextEvent);
        static void unlinkEvents(IEvent *previousEvent, IEvent *nextEvent);
};

#endif
