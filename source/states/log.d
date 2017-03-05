module states.log;

import states;

class Log 
{
	string command;
	int term;
	this(int term,string command)
	{
		this.command = command;
		this.term = term;
	}
}
