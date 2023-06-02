module eskomcalendar.calendar;

import std.stdio;
import std.json;
import std.net.curl : get, CurlException;
import std.conv : to;

import eskomcalendar.schedule;

import std.datetime : SysTime;

import eskomcalendar.exceptions;

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

    /** 
     * Performs an HTTP GET request to the provided URL
     * and wraps any exceptions in our `EskomCalendarException`
     * type
     *
     * Params:
     *   url = the URL to perform a GET on
     * Returns: the response body
     */
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

    /** 
     * Gets any schedules in the given area that would be valid for
     * the 24 hours of today's date
     *
     * Params:
     *   area = the area to check for schedules
     * Returns: an array of `Schedule`(s) 
     */
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

    /** 
     * 
     * Params:
     *   area = 
     *   startTime = 
     * Returns: 
     */
    public Schedule[] getSchedulesFrom(string area, SysTime startTime)
    {
        return getSchedules(area, startTime);
    }

    /** 
     * 
     * Params:
     *   area = 
     *   finishTime = 
     * Returns: 
     */
    public Schedule[] getSchedulesUntil(string area, SysTime finishTime)
    {
        return getSchedules(area, SysTime.min(), finishTime);
    }

    /** 
     * Get all the areas
     *
     * Returns: an array of `string` of the area names
     */
    public string[] getAreas()
    {
        return getAreas("");
    }

    /** 
     * Get all areas matching a given regular expression
     *
     * Params:
     *   regex = the regular expression
     * Returns: an array of `string` of the area names
     */
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