import std.stdio;
import std.json;
import std.net.curl : get, CurlException;
import std.conv : to;


public enum ErrType
{
    NO_AREAS_AVAILABLE,
    NO_SCHEDULES_AVAILABLE
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

    this(string calendarServer)
    {
        import std.string : stripRight;
        this.calendarServer = stripRight(calendarServer, "/");
    }

    this()
    {
        this("https://eskom-calendar-api.shuttleapp.rs/v0.0.1/");
    }

    public Schedule[] getSchedules(string area, SysTime startTime = SysTime.min(), SysTime finishTime = SysTime.max())
    {
        Schedule[] schecules;

        /** 
         * Fetch the schedules and parse
         */
        string data = cast(string)get(calendarServer~"/outages/"~area);
        JSONValue[] schedulesJSON = parseJSON(data).array();
        foreach(JSONValue schedule; schedulesJSON)
        {
            Schedule curSchedule = Schedule.fromJSON(schedule);

            if(curSchedule.getStart() >= startTime && curSchedule.getFinish() <= finishTime)
            {
                schecules ~= curSchedule;
            }
        }
        

        


        if(schecules.length == 0)
        {
            throw new EskomCalendarException(ErrType.NO_SCHEDULES_AVAILABLE, "No schedules for area '"~area~"'");
        }

        return schecules;
    }

    // FIXME: This should basically make time left min and time right max
    public Schedule[] getTodaySchdules(string area)
    {
        import std.datetime.systime :  Clock;
        import std.datetime.date : Date, DateTime;
        import std.datetime.systime : SysTime;
        

        
        Date today = cast(Date)Clock.currTime();

        SysTime startTime;

        // DateTime startD
        

        return getSchdulesFrom(area, Clock.currTime());
    }

    public Schedule[] getSchdulesFrom(string area, SysTime startTime)
    {
        return getSchedules(area, startTime);
    }

    public Schedule[] getSchdulesUntil(string area, SysTime finishTime)
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

        string data = cast(string)get(calendarServer~"/list_areas/"~regex);
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
        Schedule[] schedules = calendar.getTodaySchdules("western-cape-worscester");
        foreach(Schedule schedule; schedules)
        {
            writeln("Today: "~schedule.toString());
        }
    }
    catch(EskomCalendarException e)
    {
        assert(false);
    }
    catch(CurlException e)
    {
        writeln(e);
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
        assert(false);
    }
    catch(CurlException e)
    {
        writeln(e);
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
        assert(false);
    }
}

void main()
{
	// string data = cast(string)get("https://eskom-calendar-api.shuttleapp.rs/v0.0.1/list_areas");
    // writeln(data);
    EskomCalendar calendar = new EskomCalendar();
    string[] areas = calendar.getAreas();
    writeln(areas);
}
