//=========================================================================
//  FILTEREDEVENT.H - part of
//                  OMNeT++/OMNEST
//           Discrete System Simulation in C++
//
//=========================================================================

/*--------------------------------------------------------------*
  Copyright (C) 1992-2006 Andras Varga

  This file is distributed WITHOUT ANY WARRANTY. See the file
  `license' for details on this and other legal matters.
*--------------------------------------------------------------*/

#ifndef __FILTEREDEVENT_H_
#define __FILTEREDEVENT_H_

#include <vector>
#include "eventlogdefs.h"
#include "event.h"

class FilteredEventLog;

class FilteredEvent
{
    public:
        typedef std::vector<FilteredEvent *> FilteredEventList;
        typedef std::vector<long> EventNumberList;

    protected:
        FilteredEventLog *filteredEventLog;

        long eventNumber; // the corresponding event number
        long causeEventNumber; // the event number from which the message was sent that is being processed in this event
        Event::MessageDependencyList *causes;
        Event::MessageDependencyList *consequences; // the message sends and arrivals from this event to another in the filtered set

        long previousFilteredEventNumber; // the event number of the previous matching filtered event or -1 if unknown
        long nextFilteredEventNumber; // the event number of the next matching filtered event or -1 if unknown

    public:
        FilteredEvent(FilteredEventLog *filteredEventLog, long eventNumber);
        static void linkFilteredEvents(FilteredEvent *previousFilteredEvent, FilteredEvent *nextFilteredEvent);

        Event *getEvent();
        long getEventNumber() { return eventNumber; };
        long getPreviousFilteredEventNumber() { return previousFilteredEventNumber; };
        long getNextFilteredEventNumber() { return nextFilteredEventNumber; };

        FilteredEvent *getCause();
        Event::MessageDependencyList *getCauses(); // the returned FilteredEventList must be deleted
        Event::MessageDependencyList *getConsequences(); // the returned FilteredEventList must be deleted

    protected:
        Event::MessageDependencyList *getCauses(Event *event, int consequenceMessageSendEntryNumber, int level);
        Event::MessageDependencyList *getConsequences(Event *event, int causeMessageSendEntryNumber, int level);
};

#endif