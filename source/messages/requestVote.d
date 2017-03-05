module messages.requestVote;

import messages;

class RequestVote : Msg
{
	int term;
	override string toJson()
	{
		return "";
	}
}
