module messages.message;

import messages;

abstract class Msg
{
	string toJson();
}

class Message
{
	string type;
	Msg msg;

	this(string type,Msg msg)
	{
		this.type = type;
		this.msg = msg;
	}
	string toJson()
	{
		return msg.toJson;
	}
}
