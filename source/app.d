import std.stdio;
import std.json;
import std.net.curl : get;
import std.conv : to;


public enum ErrType
{
    NO_AREAS_AVAILABLE
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

    public string[] getAreas()
    {
        return getAreas("");
    }

    public string[] getAreas(string regex)
    {
        // TODO: Check if we need to URL_encode the `regex`
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
