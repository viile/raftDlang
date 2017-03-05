import std.stdio;

import std.process;

import raft;
import connections;

void main()
{
	NodeProperties[int] ps;
	int num = 10;
	int i;
	while(i<num){
		ps[i] = new NodeProperties(i,"127.0.0.1",cast(ushort)(i+10010));
		i++;
	}
	writeln(ps);
	i = 0;
	while(i<num){
		Pid pid = spawnProcess("./");
		scope(exit) wait(pid);
		writeln(pid);
		if(!pid) {
			NodeList list = new NodeList();
			foreach(k,v;ps){
				if(k!=i)list.addNode(v);
			}
			Node n = new Node(ps[i],list);
			n.NodeStart();
		}
		i++;
	}

}
