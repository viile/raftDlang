module messages.responseVote;

import messages;

class ResponseVote : Msg
{
	int term;
	string voteGranted;
	this(int term, string voteGranted)
	{
		this.term = term;
		this.voteGranted = voteGranted;
	}

	override string toJson()
	{
		JSONValue ret = JSONValue(["Term":term]);
		ret["VoteGranted"] = voteGranted;
		return ret.toString;
	}

}
