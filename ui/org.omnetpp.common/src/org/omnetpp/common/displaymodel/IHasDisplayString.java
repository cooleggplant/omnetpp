package org.omnetpp.common.displaymodel;


/**
 * Interface for NED model objects that provide a display string (i.e. have a visual appearance).
 * 
 * @author rhornig
 */
public interface IHasDisplayString extends IDisplayStringChangeListener {
    /**
	 * Returns the display string object. The display string object can be modified 
	 * by clients, and it is automatically kept consistent both ways with the underlying
	 * NEDElement (a LiteralNode) that stores the value for the "@display()" NED property.
	 * The fallback chain for the display string is automatically kept up to date as well.
	 * Any change in the returned DisplayString object (e.g. calling a set(...) method) 
	 * will trigger a displayStringChanged() notification.
	 */
    public DisplayString getDisplayString();
}