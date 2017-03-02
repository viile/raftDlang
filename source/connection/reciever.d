module connection.reciever;

import std.socket;

import connection;
import raft;

class Reciever
{
	Socket[int] sockets;
	string[int] messageBuffers;
	bool[int] status;
	this(NodeList list)
	{
	
	}

	void TryConnections(NodeProperties properties,NodeList list,int connectIndex)
	{
	
	}
}
