module connections.reciever;

import std.json;
import std.socket;
import std.string;
import std.conv;

import connections;
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
	public JSONValue[] TryRecieve()
	{
		JSONValue[] messages;
		foreach(id,socket;sockets){
			if(id in status){
				ubyte[1024] data;
				auto received = socket.receive(data);
				messageBuffers[id] ~= cast(string)data[0..received];
				int find = indexOf(messageBuffers[id],'#').to!int;
				if(find != -1){
					JSONValue ret = parseJSON(messageBuffers[id][0..find]);
					messages ~= ret;
					messageBuffers[id] = messageBuffers[id][find .. $];
				}
			}
		}
		return messages;
	}
	void CloseConnection()
	{
		foreach(k,v;sockets)
		{
			v.close();
		}
	}
}
