module messages.appendEntries;

import messages;

class AppendEntries : Msg
{
	int term;
	int leaderId;
	int prevLogIndex;
	int prevLogTerm;
	int entries;
	int leaderCommit;
	this(int term,int leaderId,int prevLogIndex,int prevLogTerm,int entries,int LeaderCommit){
		this.term = term;
		this.leaderId = leaderId;
		this.prevLogIndex = prevLogIndex;
		this.prevLogTerm = prevLogTerm;
		this.entries = entries;
	}
	override string toJson()
	{
		JSONValue ret = JSONValue([
			"Term":term,
			"LeaderId":leaderId,
			"PrevLogIndex":prevLogIndex,
			"PrevLogTerm":prevLogTerm,
			"Entries":entries,
			"LeaderCommit":leaderCommit
			]);
		return ret.toString;
	}
}
