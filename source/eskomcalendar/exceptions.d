/** 
 * Error handling definitions
 */
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
     * for the given area
     */
    NO_SCHEDULES_AVAILABLE,

    /** 
     * On error parsing schedule data
     */
    INVALID_SCHEDULE_DATA,

    /** 
     * On error contacting the calendar server
     */
    NETWORK_ERROR
}

/** 
 * Represents an error that occurs using the `EskomCalendar` API
 */
public final class EskomCalendarException : Exception
{
    /** 
     * Kind-of error that occurred
     */
    private ErrType errType;

    /** 
     * Constructs a new `EskomCalendarException` of the given
     * kind-of error that occurred with an optional message
     * which is emoty by default
     *
     * Params:
     *   errType = the kind-of error
     */
    this(ErrType errType, string msg = "")
    {
        this.errType = errType;
        super(to!(string)(errType)~(msg.length ? (": "~msg) : ""));
    }

    /** 
     * Gets the kind-of error that occurred
     *
     * Returns: the error as an `ErrType`
     */
    public ErrType getError()
    {
        return errType;
    }
}