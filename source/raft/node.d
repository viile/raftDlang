module raft.node;

import std.stdio;
import std.socket;
import std.datetime;
import core.time;
import std.conv;
import std.file;
import std.random;
import std.array;
import std.string;

import raft;
import connection;

class Node
{
	NodeProperties myProperties;
	NodeList nodeList;
	Sender sender;
	Reciever reciever;
	string state = "Initialized";
	int currentTerm;
	int votedFor;
	int votes;
	string[] log;
	int leaderId;
	int commitIndex;
	int lastApplied;
	int lastLogIndex;
	int[] nextIndex;
	int[] matchIndex;
	Duration timeoutInterval = dur!"msecs"(150);
	Duration heartbeatInterval = dur!"msecs"(75);
	Duration timeout;
	Socket socket;
	Socket clientSocket;
	int leader;
	bool close;
	bool exiting;
	int exitTime;
	int exitCount;
	int logWriter;
	int connectIndex;

	this(NodeProperties properties,NodeList list)
	{
		this.myProperties = properties;
		this.nodeList = list;
		this.sender = new Sender(properties);
		this.reciever = new Reciever(list);
		this.socket = new TcpSocket();
		this.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
		this.socket.bind(new InternetAddress(properties.addr,
					(properties.port.to!int+list.len+1).to!ushort));
		this.socket.listen(1);
	}

	void NodeStart()
	{
		writeContent("./Node_"~myProperties.id.to!string~"/Debug.txt",
				"Time\tCommitID\tLogID\tNodeID\tLogs");
		state = "Follower";
		int x,y;
		while(connectIndex <= nodeList.len)
		{
			if(myProperties.id == connectIndex){
				sender.AcceptConnection(myProperties,nodeList.len);
			}else{
				reciever.TryConnections(myProperties,nodeList,connectIndex);
			}
			connectIndex++;
		}
		timeout = timeoutInterval + dur!"msecs"(uniform(0,150));
		NodeRunning();
		NodeClose();

	}

	void NodeRunning()
	{
	
	}
	void NodeClose()
	{
	
	}

	private void writeContent(string file,string content)
	{
		if(!file.length)return;
		if(!content.length)return;
		if(!file.isFile){
			auto info = split(file,"/");
			if(info.length > 1)
			{
				string path = join(info[0 .. $-1],"/");
				mkdirRecurse(path);
			}
		}
		file.write(file,"");
	}
}

