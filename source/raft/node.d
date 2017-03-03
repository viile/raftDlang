module raft.node;

import std.stdio;
import std.socket;
import std.datetime;
import core.time;
import core.stdc.time;
import std.conv;
import std.file;
import std.random;
import std.array;
import std.string;

import raft;
import connections;

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
	string[int] log;
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
	bool clientSocketState;
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
		writeContent("Time\tCommitID\tLogID\tNodeID\tLogs");
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
		while(true)
		{
			if(clientSocketState == false)
			{
				
			}
		}
	}
	void NodeClose()
	{
		socket.close();
		clientSocket.close();
		clientSocketState = false;
		reciever.CloseConnection();
		sender.CloseConnection();
	}

	private void writeContent(string content,string file = null)
	{
		if(!file.length)
			file = "./Node_"~myProperties.id.to!string~"/Debug.txt";
		if(!content.length)return;
		if(!file.isFile){
			auto info = split(file,"/");
			if(info.length > 1)
			{
				string path = join(info[0 .. $-1],"/");
				mkdirRecurse(path);
			}
		}
		file.write(file,content);
	}
	private void writeLog()
	{
		string str = "\n" ~ getCurrUnixStramp ~ "\t" ~ commitIndex.to!string ~ "\t" ~
			lastLogIndex.to!string ~ "\t" ~ myProperties.id.to!string ~ "\t";
		string content;
		foreach(k,v;log)
		{
			//content ~= v.command ~ "\t";
		}
		content ~= "\n";
		writeContent(str~content);
		writeContent(content,"./Node_"~myProperties.id.to!string~"/Latest.txt");
	}
	private string getCurrUnixStramp()
	{
		SysTime currentTime = cast(SysTime)Clock.currTime();
		time_t time = currentTime.toUnixTime;
		return time.to!string;
	}

}

