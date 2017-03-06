module connections.sender;

import std.socket;

import connections;
import raft;
import messages;

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
	void SendMessage(int id, Message msg)
	{
		clients[id].send(msg.toJson ~ "#");
	}
	void BroadCastMessage(Message msg)
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
