module raft.nodeList;

import raft;

class NodeList
{
	public Node[] list;
	public void addNode(Node node)
	{
		this.list ~= node;
	}
	public int len()
	{
		return list.length.to!int;
	}
}
