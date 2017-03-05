module raft.nodeList;

import std.conv;

import raft;

class NodeList
{
	public NodeProperties[] list;
	public void addNode(NodeProperties node)
	{
		this.list ~= node;
	}
	public int len()
	{
		return list.length.to!int;
	}
}
