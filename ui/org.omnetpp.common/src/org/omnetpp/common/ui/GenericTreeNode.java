package org.omnetpp.common.ui;

import org.eclipse.core.runtime.Assert;

/**
 * Node for a generic tree where every node contains a payload object.
 * We use this with GenericTreeContentProvider to display an abitrary 
 * object tree in a TreeViewer.
 * 
 * @author andras
 */
public class GenericTreeNode {
	private static final GenericTreeNode[] EMPTY_ARRAY = new GenericTreeNode[0];

	private GenericTreeNode parent;
	private GenericTreeNode[] children;
	private Object payload;

	/**
	 * Constructs a new tree node with the given payload.
	 * @param payload may NOT be null
	 */
	public GenericTreeNode(Object payload) {
		Assert.isTrue(payload!=null);
		this.payload = payload;
		this.children = EMPTY_ARRAY;
	}

	/**
	 * Add a child node to this node.
	 * @param child may NOT be null
	 */
	public void addChild(GenericTreeNode child) {
		if (child.parent!=null)
			throw new RuntimeException("child node already has a parent");
		child.parent = this;
		GenericTreeNode[] childrenNew = new GenericTreeNode[children.length + 1];
		System.arraycopy(children, 0, childrenNew, 0, children.length);  //XXX potential bottleneck -- use ArrayList? (Andras)
		children = childrenNew;
		children[children.length - 1] = child;
	}

	/**
	 * Returns the payload object, which cannot be null.
	 */
	public Object getPayload() {
		return payload;
	}

	/**
	 * Sets the payload object. null is not accepted.
	 */
	public void setPayload(Object payload) {
		Assert.isTrue(payload!=null);
		this.payload = payload;
	}

	/**
	 * Returns the children. The result is never null. 
	 */
	public GenericTreeNode[] getChildren() {
		return children;
	}

	/**
	 * Returns the parent node.
	 */
	public GenericTreeNode getParent() {
		return parent;
	}

	/**
	 * Returns the index of this node within irs parent. 
	 * Returns -1 if this is the root node. 
	 */
	public int indexInParent() {
		if (parent == null)
			return -1;
		GenericTreeNode[] siblings = parent.children;
		for (int i = 0; i < siblings.length; ++i)
			if (siblings[i] == this)
				return i;
		throw new RuntimeException("tree inconsistency");
	}
	
	/**
	 * Adds a child node with the given payload if it not already exists.
	 */
	public GenericTreeNode getOrCreateChild(Object payload) {
		if (children != null) {
			for (int i = 0; i < children.length; ++i) {
				GenericTreeNode child = children[i];
				if (child.payload.equals(payload))
					return child;
			}
		}
		
		GenericTreeNode child = new GenericTreeNode(payload);
		addChild(child);
		
		return child;
	}
	
	/**
	 * Delegates to payload's toString().
	 */
	@Override
	public String toString() {
		return payload.toString();
	}
	
	/**
	 * Compares payloads only (of two GenericTreeNodes) 
	 */
	@Override
	public boolean equals(Object obj) {
		if (obj==null || getClass()!=obj.getClass())
			return false;
		if (this==obj)
			return true;
		GenericTreeNode node = (GenericTreeNode)obj;
		return node.payload==payload || node.payload.equals(payload);
	}
}
