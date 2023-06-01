module eskomcalendar.app;

import std.stdio;
import std.json;
import std.net.curl : get, CurlException;
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

import std.datetime : SysTime;

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

        schedule.area = value["area_name"].str();
        schedule.stage = cast(ubyte)(value["stage"].integer());
        schedule.start = SysTime.fromISOExtString(value["start"].str());
        schedule.finish = SysTime.fromISOExtString(value["finsh"].str());

        return schedule;
    }

    public string toString()
    {
        return "Schedule [area: "~area~", stage: "~to!(string)(stage)~", from: "~start.toLocalTime().toSimpleString()~", to: "~finish.toLocalTime().toSimpleString()~"]";
    }
}

public class EskomCalendar
{
    private string calendarServer;

    /** 
     * Constructs a new `EskomCalendar` using the provided
     * custom server
     *
     * Params:
     *   calendarServer = URL of the server to use
     */
    this(string calendarServer)
    {
        import std.string : stripRight;
        this.calendarServer = stripRight(calendarServer, "/");
    }

    /** 
     * Constructs a new `EskomCalendar` using the
     * default reference server
     */
    this()
    {
        this("https://eskom-calendar-api.shuttleapp.rs/v0.0.1/");
    }

    private final string doGet(string url)
    {
        try
        {
            return cast(string)get(url);
        }
        catch(CurlException e)
        {
            throw new EskomCalendarException(ErrType.NETWORK_ERROR, "Could not connect to server '"~calendarServer~"'");
        }
    }

    /** 
     * Get schedules from a given area
     *
     * Params:
     *   area = the area to check for schedules
     *   startTime = the lower bound to filter by (none by default)
     *   finishTime = the upper bound to filter by (none by default)
     * Returns: an array of `Schedule`(s)
     */
    public Schedule[] getSchedules(string area, SysTime startTime = SysTime.min(), SysTime finishTime = SysTime.max())
    {
        Schedule[] schedules;

        scope(exit)
        {
            version(unittest)
            {
                writeln("Exiting with '"~to!(string)(schedules.length)~" schedules for area '"~area~"' between '"~startTime.toSimpleString()~"' and '"~finishTime.toSimpleString()~"'");
            }
        }

        /** 
         * Fetch the schedules and parse
         */
        string data = doGet(calendarServer~"/outages/"~area);
        JSONValue[] schedulesJSON = parseJSON(data).array();
        foreach(JSONValue schedule; schedulesJSON)
        {
            Schedule curSchedule = Schedule.fromJSON(schedule);

            if(curSchedule.getStart() >= startTime && curSchedule.getFinish() <= finishTime)
            {
                schedules ~= curSchedule;
            }
        }
        

        


        if(schedules.length == 0)
        {
            throw new EskomCalendarException(ErrType.NO_SCHEDULES_AVAILABLE, "No schedules for area '"~area~"'");
        }

        return schedules;
    }

    public Schedule[] getTodaySchedules(string area)
    {
        import std.datetime.systime :  Clock;
        import std.datetime.date : Date, DateTime;
        import std.datetime.systime : SysTime;
        import core.thread : dur;
        

        // Get just the date of today (no time)
        Date todayDate = cast(Date)Clock.currTime();

        // Get the start and end date+times but with time zeroed out
        SysTime startTime = cast(SysTime)todayDate;
        SysTime endTime = cast(SysTime)todayDate;

        // Make end date+time 24 hours later
        endTime += dur!("hours")(24);

        version(unittest)
        {
            writeln("startTime: ", startTime);
            writeln("endTime: ", endTime);
        }
        
        return getSchedules(area, startTime, endTime);
    }

    public Schedule[] getSchedulesFrom(string area, SysTime startTime)
    {
        return getSchedules(area, startTime);
    }

    public Schedule[] getSchedulesUntil(string area, SysTime finishTime)
    {
        return getSchedules(area, SysTime.min(), finishTime);
    }

    public string[] getAreas()
    {
        return getAreas("");
    }

    public string[] getAreas(string regex)
    {
        // Apply any URL escaping needed
        import std.uri : encode;
        regex = encode(regex);

        string data = doGet(calendarServer~"/list_areas/"~regex);
        JSONValue[] areas = parseJSON(data).array();

        string[] areasStr;
        foreach(JSONValue area; areas)
        {
            areasStr ~= area.str();
        }

        if(areasStr.length == 0)
        {
            throw new EskomCalendarException(ErrType.NO_AREAS_AVAILABLE);
        }

        return areasStr;
    }
}

unittest
{
    EskomCalendar calendar = new EskomCalendar();

    try
    {
        Schedule[] schedules = calendar.getTodaySchedules("western-cape-worscester");
        foreach(Schedule schedule; schedules)
        {
            writeln("Today: "~schedule.toString());
        }
    }
    catch(EskomCalendarException e)
    {
        writeln("Crashed with '"~e.toString()~"'");
        assert(false);
    }
}

unittest
{
    EskomCalendar calendar = new EskomCalendar();

    /** 
     * Get all areas available
     * and take a subset of them
     */
    string[] areas = calendar.getAreas()[0..10];

    /**
     * Get the schedules per-each of them
     */
    foreach(string area; areas)
    {
        Schedule[] schedules = calendar.getSchedules(area);
    }
}

unittest
{
    EskomCalendar calendar = new EskomCalendar();

    try
    {
        Schedule[] schedules = calendar.getSchedules("western-cape-worscester");
        assert(schedules.length > 5);

        foreach(Schedule schedule; schedules)
        {
            writeln(schedule);
        }
    }
    catch(EskomCalendarException e)
    {
        writeln("Crashed with '"~e.toString()~"'");
        assert(false);
    }
}

unittest
{
    EskomCalendar calendar = new EskomCalendar();

    try
    {
        string[] areas = calendar.getAreas();
        writeln(areas);
        assert(areas.length > 40);
    }
    catch(EskomCalendarException e)
    {
        writeln("Crashed with '"~e.toString()~"'");
        assert(false);
    }
}