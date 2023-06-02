module eskomcalendar.schedule;

import std.datetime.systime : SysTime;
import std.json : JSONValue, JSONException;
import std.conv : to;
import eskomcalendar.exceptions;

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

    this(string area, ubyte stage, SysTime start, SysTime finish)
    {
        this.area = area;
        this.stage = stage;
        this.start = start;
        this.finish = finish;
    }

    public SysTime getStart()
    {
        return start;
    }

    public SysTime getFinish()
    {
        return finish;
    }

    public static Schedule fromJSON(JSONValue value)
    {
        Schedule schedule;

        try
        {
            schedule.area = value["area_name"].str();
            schedule.stage = cast(ubyte)(value["stage"].integer());
            schedule.start = SysTime.fromISOExtString(value["start"].str());
            schedule.finish = SysTime.fromISOExtString(value["finsh"].str());
        }
        catch(JSONException e)
        {
            throw new EskomCalendarException(ErrType.INVALID_SCHEDULE_DATA);
        }

        return schedule;
    }

    public string toString()
    {
        return "Schedule [area: "~area~", stage: "~to!(string)(stage)~", from: "~start.toLocalTime().toSimpleString()~", to: "~finish.toLocalTime().toSimpleString()~"]";
    }
}