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
import core.thread;
import std.json;

import raft;
import connections;
import states;
import messages;

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
	Log[int] log;
	int leaderId;
	int commitIndex;
	int lastApplied;
	int lastLogIndex;
	int[int] nextIndex;
	int[int] matchIndex;
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
				auto sets = new SocketSet();
				sets.add(socket);
				if(socket.select(sets,sets,sets))
					clientSocket = socket.accept();

			}

			if(clientSocketState == true)
			{
				clientSocket.blocking(true);
				ubyte[1024] data;
				auto received = clientSocket.receive(data);
				if(received)
				{
					string command = cast(string)data[0..received];
					writeln("received : ",command);
					if(command == "Sleep"){
						Thread.sleep(dur!("seconds")(5));	
					} else if (command == "Quit") {
						return;
					} else if (command == "CloseSocket") {
						clientSocket.close();
						clientSocketState = false;
					} else if (state == "Leader") {
						lastLogIndex++;
						log[lastLogIndex] = new Log(currentTerm,command);
						writeLog();
					} else {
						clientSocket.send(cast(ubyte[])[leaderId]);
					}

				}
			}

			if(state == "Leader" && getCurrUnixStrampInt >= leader+2)
			{
				leader = 10000000;
			}

			JSONValue[] messages = reciever.TryRecieve();

			foreach(msg;messages){
				int drop = uniform(0,30);
				if(drop == 0)
					continue;
				if(msg["Type"].str == "RequestVote"){
					if(msg["ResponseVote"]["Term"].str.to!int <= currentTerm){
						writeln("false");
						Message _msg = new Message("ResponseVote",new ResponseVote(currentTerm,"False"));
						sender.SendMessage(msg["ResponseVote"]["CandidateId"].str.to!int,_msg);
					} else if(lastLogIndex > msg["ResponseVote"]["LastLogIndex"].str.to!int || lastLogIndex > 0 && log[lastLogIndex].term != msg["ResponseVote"]["LastLogTerm"].str.to!int) {
						writeln("changed to follower ");
						Message _msg = new Message("ResponseVote",new ResponseVote(currentTerm,"False"));
						sender.SendMessage(msg["ResponseVote"]["CandidateId"].str.to!int,_msg);
						state = "Follower";
						currentTerm = msg["ResponseVote"]["Term"].str.to!int;
						timeout = timeoutInterval + dur!"msecs"(uniform(0,150));
					} else {
						state = "Follower";
						currentTerm = msg["ResponseVote"]["Term"].str.to!int;
						votedFor = msg["ResponseVote"]["CandidateId"].str.to!int;
						timeout = timeoutInterval + dur!"msecs"(uniform(0,150));
						Message _msg = new Message("ResponseVote",new ResponseVote(currentTerm,"True"));
						sender.SendMessage(msg["ResponseVote"]["CandidateId"].str.to!int,_msg);
					}
				
				} else if (msg["Type"].str == "ResponseVote" && msg["Type"].str == "Candidate"){
					writeln("id Response");
					if(msg["ResponseVote"]["VoteGranted"].str == "True"){
						votes += 1;
					}else if (msg["ResponseVote"]["Term"].str.to!int > currentTerm){
						state = "Follower";
						currentTerm = msg["ResponseVote"]["Term"].str.to!int;
						votedFor = msg["ResponseVote"]["CandidateId"].str.to!int;
						timeout = timeoutInterval + dur!"msecs"(uniform(0,150));
					}
				} else if (msg["Type"].str == "AppendEntries") {
					writeln("id AppendEntries");
					if(msg["AppendEntries"]["Term"].str.to!int < currentTerm){
						Message _msg = new Message("EntryResult",new EntryResult(currentTerm,"False",myProperties.id,lastLogIndex));
						sender.SendMessage(msg["AppendEntries"]["LeaderId"].str.to!int,_msg);
					} else if(msg["AppendEntries"]["PrevLogIndex"].str.to!int != 0 && !(msg["AppendEntries"]["PrevLogIndex"].str.to!int in log)){
						Message _msg = new Message("EntryResult",new EntryResult(currentTerm,"False",myProperties.id,lastLogIndex));
						sender.SendMessage(msg["AppendEntries"]["LeaderId"].str.to!int,_msg);
						leaderId = msg["AppendEntries"]["LeaderId"].str.to!int;
					} else if (msg["AppendEntries"]["PrevLogIndex"].str.to!int != 0 && (msg["AppendEntries"]["PrevLogIndex"].str.to!int in log) && log[msg["AppendEntries"]["PrevLogIndex"].str.to!int].term != msg["AppendEntries"]["PrevLogTerm"].str.to!int) {
						Message _msg = new Message("EntryResult",new EntryResult(currentTerm,"False",myProperties.id,lastLogIndex));
						sender.SendMessage(msg["AppendEntries"]["LeaderId"].str.to!int,_msg);
						leaderId = msg["AppendEntries"]["LeaderId"].str.to!int;
					} else {
						leaderId = msg["AppendEntries"]["LeaderId"].str.to!int;
						if(msg["AppendEntries"]["Term"].str.to!int >= currentTerm){
							state = "Follower";
							currentTerm = msg["AppendEntries"]["Term"].str.to!int;
							votedFor = msg["AppendEntries"]["LeaderId"].str.to!int;
						}
						timeout = timeoutInterval + dur!"msecs"(uniform(0,150));
						bool contains = false;
						if(state != "Follower")
							writeln("TO DO : unknow");
						bool delentries = false;
						int j;
						for(int i = msg["AppendEntries"]["PrevLogIndex"].str.to!int + 1;;i++)
						{
							if(delentries)
							{
								if(i in log)
									log = unset!(Log[int],int)(log,i);
								else
									break;
							} else if(!(j.to!string in msg["AppendEntries"]["Entries"])) {
								delentries = true;
								lastLogIndex = i-1;
								if(i in log)
									log = unset!(Log[int],int)(log,i);
							} else {
								//to do log update
								log[i] = new Log(currentTerm,msg["AppendEntries"]["Entries"][j].str);
								j++;
							}
						}
						Message _msg = new Message("EntryResult",new EntryResult(currentTerm,"True",myProperties.id,lastLogIndex));
						sender.SendMessage(msg["AppendEntries"]["LeaderId"].str.to!int,_msg);
						if(j==0)writeLog();
						if(msg["AppendEntries"]["LeaderCommit"].str.to!int > commitIndex){
							if(lastLogIndex < msg["AppendEntries"]["LeaderCommit"].str.to!int)
								commitIndex = lastLogIndex;
							else 
								commitIndex = msg["AppendEntries"]["LeaderCommit"].str.to!int;
						}
					}
				
				} else if (msg["Type"].str == "EntryResult") {
					writeln("id EntryResult");
					if(msg["EntryResult"]["Term"].str.to!int>currentTerm){
						state = "Follower";
						currentTerm = msg["EntryResult"]["Term"].str.to!int;
						timeout = timeoutInterval + dur!"msecs"(uniform(0,150));
					}else if(msg["EntryResult"]["Success"].str == "False") {
						if(nextIndex[msg["EntryResult"]["id"].str.to!int]>0)
							nextIndex[msg["EntryResult"]["id"].str.to!int] -= 1;
					}else if (msg["EntryResult"]["Success"].str == "True"){
						nextIndex[msg["EntryResult"]["id"].str.to!int] = msg["EntryResult"]["index"].str.to!int;
						matchIndex[msg["EntryResult"]["id"].str.to!int] = msg["EntryResult"]["index"].str.to!int;
					}
				} 
				if(commitIndex>lastApplied){
					lastApplied++;
					if(state == "Leader")
						clientSocket.send(log[lastApplied].command);
					writeLog();
				}
				//if(state)
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
	private time_t currUnixStramp()
	{
		SysTime currentTime = cast(SysTime)Clock.currTime();
		time_t time = currentTime.toUnixTime;
		return time;	
	}
	private string getCurrUnixStramp()
	{
		return currUnixStramp.to!string;
	}
	private int getCurrUnixStrampInt()
	{
		return currUnixStramp.to!int;
	}
	private T unset(T,F)(T content, F key)
	{
		T ret;
		foreach(k,v;content){
			if(k != key)ret[k] = v;
		}
		return ret;
	}
}

