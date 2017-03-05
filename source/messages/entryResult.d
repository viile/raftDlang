module messages.entryResult;

import messages;

class EntryResult : Msg
{
	int term;
	string success;
	int id;
	int index;
	this(int term,string success,int id,int index)
	{
		this.term = term;
		this.success = success;
		this.id = id;
		this.index = index;
	}
	override string toJson()
	{
		JSONValue ret = JSONValue(["Term":term]);
		ret["Success"] = success;
		ret["id"] = id;
		ret["index"] = index;
		return ret.toString;
	}
}
