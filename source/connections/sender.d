module connections.sender;

import std.socket;

import connections;
import raft;

class Sender
{
	Socket socket;
	Socket[int] clients;
	this(NodeProperties properties)
	{
	
	}

	void AcceptConnection(NodeProperties properties,int len)
	{
	
	}
	void SendMessage()
	{
	
	}
	void BroadCastMessage()
	{
	
	}
	void CloseConnection()
	{
		foreach(k,v;clients)
		{
			v.close();
		}
		socket.close();
	}
}
