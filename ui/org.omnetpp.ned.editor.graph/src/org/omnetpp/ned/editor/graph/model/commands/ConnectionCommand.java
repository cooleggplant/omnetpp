package org.omnetpp.ned.editor.graph.model.commands;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.gef.commands.Command;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.omnetpp.ned.editor.graph.misc.BlockingMenu;
import org.omnetpp.ned.editor.graph.misc.ConnectionChooser;
import org.omnetpp.ned2.model.CompoundModuleNodeEx;
import org.omnetpp.ned2.model.ConnectionNodeEx;
import org.omnetpp.ned2.model.IConnectable;
import org.omnetpp.ned2.model.IConnectionContainer;
import org.omnetpp.ned2.model.IElement;
import org.omnetpp.ned2.model.INamedGraphNode;
import org.omnetpp.ned2.model.ModelUtil;
import org.omnetpp.ned2.model.SubmoduleNodeEx;
import org.omnetpp.ned2.model.pojo.ConnectionNode;
import org.omnetpp.ned2.model.pojo.GateNode;
import org.omnetpp.resources.INEDComponent;
import org.omnetpp.resources.NEDResourcesPlugin;

/**
 * (Re)assigns a Connection to srcModule/destModule sub/compound module gates and also adds it to the
 * model (to the compound module's connectios section) (or removes it if the new source or destination is NULL)
 * @author rhornig
 */
public class ConnectionCommand extends Command {

	protected IConnectable oldSrcModule;
	protected IConnectable oldDestModule;
	protected ConnectionNode oldConn = new ConnectionNode();
    
    protected IConnectable srcModule;
    protected IConnectable destModule;
	protected ConnectionNode newConn = new ConnectionNode();
	// connection model to be changed
    protected ConnectionNodeEx connNode;
    protected ConnectionNodeEx connNodeNextSibling = null;
    protected IConnectionContainer parent = null;

    @Override
    public String getLabel() {
        if (connNode != null && srcModule == null && destModule == null)
            return "Delete connection";
        
        if (connNode != null && srcModule != null && destModule != null)
            return "Create connection";

        return "Move connection";
    }

    public ConnectionCommand (ConnectionNodeEx conn) {
        connNode = conn;
        oldSrcModule = connNode.getSrcModuleRef();
        oldDestModule = connNode.getDestModuleRef();
        oldConn = (ConnectionNode)connNode.dup(null);
        newConn = (ConnectionNode)connNode.dup(null);

    }
    /**
     * Handles which module can be connected to which
     */
    @Override
    public boolean canExecute() {
    	// allow deletion (both module is null)
    	if(srcModule == null && destModule == null)
    		return true;
    	// we can connect two submodules module ONLY if they are siblings (ie they have the same parent)
    	IConnectable sMod = srcModule != null ? srcModule : connNode.getSrcModuleRef();
    	IConnectable dMod = destModule != null ? destModule : connNode.getDestModuleRef();

    	if(sMod instanceof SubmoduleNodeEx && dMod instanceof SubmoduleNodeEx &&
    			((IElement)sMod).getParent() == ((IElement)dMod).getParent()) 
    		return true;
    	
    	// if one module is bubmodule and the other is compound, the compound module MUST contain the submodule
    	if (sMod instanceof CompoundModuleNodeEx && dMod instanceof SubmoduleNodeEx &&
    			((SubmoduleNodeEx)dMod).getCompoundModule() == sMod)
    		return true;
    	
    	if (dMod instanceof CompoundModuleNodeEx && sMod instanceof SubmoduleNodeEx &&
    			((SubmoduleNodeEx)sMod).getCompoundModule() == dMod)
    		return true;
    	
    	// do not allow command in any other cases
        return false;
    }

    @Override
    public void execute() {
   		// do the changes
    	redo();

    	// after we connected the modules, let's ask the user which gates should be connected
    	if(srcModule != null || destModule != null) {
    		// ask the user for ser and dest gate names
    		ConnectionNode tempConn = ConnectionChooser.open(srcModule, destModule);
    		// if both gates are specified by the user do the model change
    		if (tempConn != null) {
    			copyConn(tempConn, newConn);
        		redo();
    		}
    		else //otherwise revert the connection change (user cancel)
    			undo();
    	}
    }

    @Override
    public void redo() {
        if (srcModule != null && oldSrcModule != srcModule) 
            connNode.setSrcModuleRef(srcModule);
        
        if (newConn.getSrcGate() != null && !newConn.getSrcGate().equals(oldConn.getSrcGate()))
            connNode.setSrcGate(newConn.getSrcGate());
        
        if (destModule != null && oldDestModule != destModule) 
            connNode.setDestModuleRef(destModule);
        
        if (newConn.getDestGate() != null &&  !newConn.getDestGate().equals(oldConn.getDestGate()))
            connNode.setDestGate(newConn.getDestGate());
        
        copyConn(newConn, connNode);
        
        // if both src and dest module should be detached then remove it 
        // from the model totally (ie delete it)
        if (srcModule == null && destModule == null) {
            // just store the NEXT sibling so we can put it back during undo to the right place
            connNodeNextSibling = (ConnectionNodeEx)connNode.getNextConnectionNodeSibling();
            // store the parent too so we now where to put it back during undo
            parent = (IConnectionContainer)connNode.getParent().getParent();
            // now detach from both src and dest modules
            connNode.setSrcModuleRef(null);
            connNode.setDestModuleRef(null);
            // and remove from the parent too
           	connNode.removeFromParent();
        }
    }

    @Override
    public void undo() {
        // if it was removed from the model, put it back
        if (connNode.getParent() == null && parent != null)
            parent.insertConnection(connNodeNextSibling, connNode);
        
        // attach to the original modules and gates
        connNode.setSrcModuleRef(oldSrcModule);
        connNode.setDestModuleRef(oldDestModule);

        copyConn(oldConn, connNode);
    }

	private void copyConn(ConnectionNode from, ConnectionNode to) {
		to.setSrcModuleIndex(from.getSrcModuleIndex());
        to.setSrcGate(from.getSrcGate());
        to.setSrcGateIndex(from.getSrcGateIndex());
        to.setSrcGatePlusplus(from.getSrcGatePlusplus());
        
        to.setDestModuleIndex(from.getDestModuleIndex());
        to.setDestGate(from.getDestGate());
        to.setDestGateIndex(from.getDestGateIndex());
        to.setDestGatePlusplus(from.getDestGatePlusplus());
        
        to.setArrowDirection(from.getArrowDirection());
	}

    public void setSrcModule(IConnectable newSrcModule) {
        srcModule = newSrcModule;
    }

    public void setSrcGate(String newSrcGate) {
        newConn.setSrcGate(newSrcGate);
    }

    public void setDestModule(IConnectable newDestModule) {
        destModule = newDestModule;
    }

    public void setDestGate(String newDestGate) {
        newConn.setDestGate(newDestGate);
    }
    
    

	
}
