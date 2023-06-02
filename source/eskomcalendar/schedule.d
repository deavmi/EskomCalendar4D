/** 
 * Scheduling-related definitions
 */
module eskomcalendar.schedule;

import std.datetime.systime : SysTime;
import std.json : JSONValue, JSONException;
import std.conv : to;
import eskomcalendar.exceptions;

/** 
 * Represents a schedule for a given area,
 * this includes the stage and the start
 * and end time
 */
public struct Schedule
{
    /** 
     * Area this schedule applies to
     */
    private string area;

    /** 
     * The stage level (god forbid bigger than a byte)
     */
    private ubyte stage;

    /** 
     * Start and finish time
     */
    private SysTime start, finish;

    /** 
     * Constructs a new `Schedule` for the given area
     * with its stage and starting and ending times
     *
     * Params:
     *   area = the area
     *   stage = the level of load shedding
     *   start = starting time
     *   finish = ending time
     */
    private this(string area, ubyte stage, SysTime start, SysTime finish)
    {
        this.area = area;
        this.stage = stage;
        this.start = start;
        this.finish = finish;

        // TODO: Add source
    }

    /** 
     * Get's the name of the area this schedule is for
     *
     * Returns: the area's name
     */
    public string getArea()
    {
        return area;
    }

    /** 
     * Returns the starting time
     *
     * Returns: the starting time as a `SysTime`
     */
    public SysTime getStart()
    {
        return start;
    }

    /** 
     * Returns the ending time
     *
     * Returns: the starting time as a `SysTime`
     */
    public SysTime getFinish()
    {
        return finish;
    }

    /** 
     * Constructs a new `Schedule` from the provided JSON
     *
     * Params:
     *   json = the json to parse the schedule from
     * Returns: the parsed `Schedule`
     */
    public static Schedule fromJSON(JSONValue json)
    {
        Schedule schedule;

        try
        {
            schedule.area = json["area_name"].str();
            schedule.stage = cast(ubyte)(json["stage"].integer());
            schedule.start = SysTime.fromISOExtString(json["start"].str());
            schedule.finish = SysTime.fromISOExtString(json["finsh"].str());

            // TODO: Parse source
        }
        catch(JSONException e)
        {
            throw new EskomCalendarException(ErrType.INVALID_SCHEDULE_DATA);
        }

        return schedule;
    }

    /** 
     * Returns a string representation of the schedule
     *
     * Returns: a `string` representation
     */
    public string toString()
    {
        return "Schedule [area: "~area~", stage: "~to!(string)(stage)~", from: "~start.toLocalTime().toSimpleString()~", to: "~finish.toLocalTime().toSimpleString()~"]";
    }
}