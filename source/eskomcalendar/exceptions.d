module eskomcalendar.exceptions;

import std.conv : to;

/** 
 * Kind-of error that occurred
 */
public enum ErrType
{
    /** 
     * If there are no areas available
     */
    NO_AREAS_AVAILABLE,

    /** 
     * If there were no schedules available
     for the given area
     */
    NO_SCHEDULES_AVAILABLE,

    /** 
     * On error contacting the calendar server
     */
    NETWORK_ERROR
}

public final class EskomCalendarException : Exception
{
    private ErrType errType;

    this(ErrType errType, string msg = "")
    {
        this.errType = errType;
        super(to!(string)(errType)~(msg.length ? (": "~msg) : ""));
    }
}