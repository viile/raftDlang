module raft.nodeProperties;

import raft;

class NodeProperties
{
	int id;
	string addr;
	ushort port;

	this(int id,string addr,ushort port)
	{
		this.id = id;
		this.addr = addr;
		this.port = port;
	}
}
