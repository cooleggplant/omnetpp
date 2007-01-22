package org.omnetpp.ned.editor.graph.edit;

import java.util.Map;

import org.eclipse.draw2d.IFigure;
import org.eclipse.gef.EditPart;
import org.eclipse.gef.EditPolicy;
import org.eclipse.gef.Request;
import org.eclipse.gef.RequestConstants;
import org.eclipse.gef.editparts.AbstractConnectionEditPart;
import org.eclipse.ui.views.properties.IPropertySource;
import org.omnetpp.figures.ConnectionFigure;
import org.omnetpp.ned.editor.graph.edit.policies.NedConnectionEditPolicy;
import org.omnetpp.ned.editor.graph.edit.policies.NedConnectionEndpointEditPolicy;
import org.omnetpp.ned.editor.graph.properties.IPropertySourceSupport;
import org.omnetpp.ned.model.NEDElementUtil;
import org.omnetpp.ned.model.ex.ConnectionNodeEx;
import org.omnetpp.ned.model.notification.INEDChangeListener;
import org.omnetpp.ned.model.notification.NEDModelEvent;
// TODO handle isEditable correctly in installed editpolicies
/**
 * Implements a Connection Editpart to represnt a Wire like connection.
 * 
 */
public class ModuleConnectionEditPart extends AbstractConnectionEditPart 
                    implements INEDChangeListener, IReadOnlySupport, IPropertySourceSupport {

	private EditPart sourceEditPartEx; 
	private EditPart targetEditPartEx;
    private long lastEventSerial;
    private boolean editable = true;
    private IPropertySource propertySource;

	@Override
    public void activate() {
        if (isActive()) return;
        super.activate();
        // register as listener of the model object
        getConnectionModel().getListeners().add(this);
    }

    @Override
    public void deactivate() {
        if (!isActive()) return;
        // deregister as listener of the model object
        getConnectionModel().getListeners().remove(this);
        super.deactivate();
    }

    @Override
    public void activateFigure() {
    	// add the connection to the compound module's connection layer instead of the global one
    	((CompoundModuleEditPart)getParent()).getCompoundModuleFigure()
    			.addConnectionFigure(getConnectionFigure());
    }

    @Override
    public void deactivateFigure() {
    	// remove the connection figure from the parent
    	getFigure().getParent().remove(getFigure());
    	getConnectionFigure().setSourceAnchor(null);
    	getConnectionFigure().setTargetAnchor(null);
    }

    @Override
    public EditPart getSource() {
    	return sourceEditPartEx;
    }

    @Override
    public EditPart getTarget() {
    	return targetEditPartEx;
    }

    /**
     * Sets the source EditPart of this connection. Overrides the original implementation
     * to add the connection as the child of a compound module
     *
     * @param editPart  EditPart which is the source.
     */
    @Override
    public void setSource(EditPart editPart) {
    	if (sourceEditPartEx == editPart)
    		return;
    	
    	sourceEditPartEx = editPart;
    	if (sourceEditPartEx != null) {
    		// attach the connection edit part to the compound module as a parent
        	if (sourceEditPartEx instanceof CompoundModuleEditPart)
        		setParent(sourceEditPartEx);
        	else if (sourceEditPartEx instanceof SubmoduleEditPart)
        		setParent(sourceEditPartEx.getParent());
    	} else if (targetEditPartEx == null)
    		setParent(null);
    	if (sourceEditPartEx != null && targetEditPartEx != null)
    		refresh();
    }

    /**
     * Sets the target EditPart of this connection. Overrides the original implementation
     * to add the connection as the child of a compound module
     * @param editPart  EditPart which is the target.
     */
    @Override
    public void setTarget(EditPart editPart) {
    	if (targetEditPartEx == editPart)
    		return;
    	targetEditPartEx = editPart;
    	if (targetEditPartEx != null) {
    		// attach the connection edit part to the compound module as a parent
        	if (targetEditPartEx instanceof CompoundModuleEditPart)
        		setParent(targetEditPartEx);
        	else if (targetEditPartEx instanceof SubmoduleEditPart)
        		setParent(targetEditPartEx.getParent());
    	} else if (sourceEditPartEx == null)
    		setParent(null);
    	if (sourceEditPartEx != null && targetEditPartEx != null)
    		refresh();
    }

    /**
     * Adds extra EditPolicies as required.
     */
    @Override
    protected void createEditPolicies() {
        installEditPolicy(EditPolicy.CONNECTION_ENDPOINTS_ROLE, new NedConnectionEndpointEditPolicy());
        installEditPolicy(EditPolicy.CONNECTION_ROLE, new NedConnectionEditPolicy());
    }

    /**
     * Returns a newly created Figure to represent the connection.
     * 
     * @return The created Figure.
     */
    @Override
    protected IFigure createFigure() {
        ConnectionFigure conn = new ConnectionFigure();
        return conn;    
    }

    /**
     * Returns the model associated to this editpart as a ConnectionNodeEx
     * 
     * @return Model of this as <code>Wire</code>
     */
    protected ConnectionNodeEx getConnectionModel() {
        return (ConnectionNodeEx) getModel();
    }

    /**
     * Refreshes the visual aspects of this, based upon the model (Wire). It
     * changes the wire color depending on the state of Wire.
     * 
     */
    @Override
    protected void refreshVisuals() {
        ConnectionFigure cfig = (ConnectionFigure)getConnectionFigure();  
        cfig.setDisplayString(getConnectionModel().getEffectiveDisplayString());
        cfig.setArrowEnabled(getConnectionModel().getArrowDirection() != NEDElementUtil.NED_ARROWDIR_BIDIR);
    }

    public void modelChanged(NEDModelEvent event) {
        // skip the event processing if te last serial is greater or equal. only newer
        // events should be processed. this prevent the processing of the same event multiple times
        if (lastEventSerial >= event.getSerial())
            return;
        else // process the even and remeber this serial
            lastEventSerial = event.getSerial();

        System.out.println("NOTIFY ON: "+getModel().getClass().getSimpleName()+" "+event);
        // not needed because the containing compound module always refreshes all it's children and connections
        // refreshVisuals();
    }

    public void setEditable(boolean editable) {
        this.editable = editable;
    }
    
    public boolean isEditable() {
        boolean isEditable 
            = editable && (getParent().getModel() == ((ConnectionNodeEx)getModel()).getCompoundModule());
        if (!isEditable)
            return false;
        // otherwise check what about the parent. if parent is read only we should return its state 
        if (getParent() instanceof IReadOnlySupport)
            return ((IReadOnlySupport)getParent()).isEditable();
        return true;
    }
    
    @Override
    public void performRequest(Request req) {
        super.performRequest(req);
        // let's open or activate a new editor if somone has double clicked the component
        if (RequestConstants.REQ_OPEN.equals(req.getType())) {
            BaseEditPart.openEditor(getConnectionModel(), getConnectionModel().getEffectiveType());
        }
    }
    
    /**
     * @return The compound module part this connection part belongs to
     */
    public CompoundModuleEditPart getCompoundModulePart() {
        return (CompoundModuleEditPart)getParent();
    }
    
    /* (non-Javadoc)
     * @see org.eclipse.gef.editparts.AbstractEditPart#registerModel()
     * Override the default behavior because each compound module has it's own registry for connection model
     * connection part mapping (instead of the default impl. one map for the whole viewer)
     * The connection part creation is looking also in this registry
     * @see org.omnetpp.ned.editor.graph.edit.ModuleEditPart#createOrFindConnection(java.lang.Object) 
     */
    protected void registerModel() {
        getCompoundModulePart().getModelToConnectionPartsRegistry().put(getModel(), this);
    }

    /* (non-Javadoc)
     * @see org.eclipse.gef.editparts.AbstractEditPart#unregisterModel()
     * Override the default behavior because each compound module has it's own registry for connection model
     * connection part mapping (instead of the default impl. one map for the whole viewer)
     * The connection part creation is looking also in this registry
     * @see org.omnetpp.ned.editor.graph.edit.ModuleEditPart#createOrFindConnection(java.lang.Object) 
     */
    protected void unregisterModel() {
        Map registry = getCompoundModulePart().getModelToConnectionPartsRegistry();
        if (registry.get(getModel()) == this)
            registry.remove(getModel());
    }

    public IPropertySource getPropertySource() {
        return propertySource;
    }

    public void setPropertySource(IPropertySource propertySource) {
        this.propertySource = propertySource;
    }
}


