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
}
