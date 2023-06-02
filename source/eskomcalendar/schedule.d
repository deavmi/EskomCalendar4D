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
public class Schedule
{
    /** 
     * Area this schedule applies to
     */
    private string area;

    /** 
     * The stage level
     */
    private ubyte stage;

    /** 
     * Start and finish time
     */
    private SysTime start, finish;
    
    /** 
     * The source this schedule was gleamed from
     */
    private string source;

    /** 
     * Private constructor to disallow creation except
     * via the static factory method
     */
    private this()
    {

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
     * Returns the load shedding stage level
     *
     * Returns: the stage
     */
    public ubyte getStage()
    {
        return stage;
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
     * Returns the source this schedule was gleamed from
     *
     * Returns: the source
     */
    public string getSource()
    {
        return source;
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
        Schedule schedule = new Schedule();

        try
        {
            schedule.area = json["area_name"].str();
            schedule.stage = cast(ubyte)(json["stage"].integer());
            schedule.start = SysTime.fromISOExtString(json["start"].str());
            schedule.finish = SysTime.fromISOExtString(json["finsh"].str());
            schedule.source = json["source"].str();
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
    public override string toString()
    {
        return "Schedule [area: "~area~", stage: "~to!(string)(stage)~", from: "~start.toLocalTime().toSimpleString()~", to: "~finish.toLocalTime().toSimpleString()~"]";
    }
}

version(unittest)
{
    import std.json : parseJSON;
}

/**
 * Test building a `Schedule` from the example JSON
 */
unittest
{
    string json = `
    {
    "area_name": "western-cape-worscester",
    "stage": 4,
    "start": "2023-06-01T14:00:00+02:00",
    "finsh": "2023-06-01T14:30:00+02:00",
    "source": "https://twitter.com/Eskom_SA/status/1664250326818365440"
  }`;

    try
    {
        Schedule schedule = Schedule.fromJSON(parseJSON(json));

        assert(schedule.getArea() == "western-cape-worscester");
        assert(schedule.getStage() == 4);
        assert(schedule.getStart() == SysTime.fromISOExtString("2023-06-01T14:00:00+02:00"));
        assert(schedule.getFinish() == SysTime.fromISOExtString("2023-06-01T14:30:00+02:00"));
        assert(schedule.getSource() == "https://twitter.com/Eskom_SA/status/1664250326818365440");        
    }
    catch(EskomCalendarException e)
    {
        assert(false);
    }
}

/**
 * Test building a `Schedule` from the example JSON
 * buit where the JSON is BROKEN
 */
private unittest
{
    string json = `
    {
    "area_name": "western-cape-worscester",
    "stage": 4,
    "start": "2023-06-01T14:00:00+02:00",
    "finsh": 2
  }`;

    try
    {
        Schedule schedule = Schedule.fromJSON(parseJSON(json));

        assert(false);       
    }
    catch(EskomCalendarException e)
    {
        assert(e.getError() == ErrType.INVALID_SCHEDULE_DATA);
    }
}