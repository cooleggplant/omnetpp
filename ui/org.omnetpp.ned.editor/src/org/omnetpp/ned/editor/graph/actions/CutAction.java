package org.omnetpp.ned.editor.graph.actions;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.gef.ui.actions.Clipboard;
import org.eclipse.gef.ui.actions.SelectionAction;
import org.eclipse.ui.ISharedImages;
import org.eclipse.ui.IWorkbenchPart;
import org.eclipse.ui.PlatformUI;
import org.eclipse.ui.actions.ActionFactory;
import org.omnetpp.ned.model.INEDElement;
import org.omnetpp.ned.model.interfaces.IModelProvider;


/**
 * Implements "Cut to clipboard".
 * 
 * @author Andras
 */
//FIXME as retargetAction!
public class CutAction extends SelectionAction {
    public static final String ID = ActionFactory.CUT.getId();
    public static final String MENUNAME = "Cut";
    public static final String TOOLTIP = "Cut to clipboard";

    public CutAction(IWorkbenchPart part) {
        super(part);
        setText(MENUNAME);
        setId(ID);
        setToolTipText(TOOLTIP);
        ISharedImages sharedImages = PlatformUI.getWorkbench().getSharedImages();
    	setImageDescriptor(sharedImages.getImageDescriptor(ISharedImages.IMG_TOOL_CUT));
    	setDisabledImageDescriptor(sharedImages.getImageDescriptor(ISharedImages.IMG_TOOL_CUT_DISABLED));
    }

    @Override
    protected boolean calculateEnabled() {
        return getSelectedObjects().size() > 0;
    }

	@Override @SuppressWarnings("unchecked")
    public void run() {
		//FIXME remove selected objects from the model
		// note: getSelectedObjects() seems to return the editparts not the model objects
		List<INEDElement> selectedModelObjects = new ArrayList<INEDElement>();
        for (Object o : getSelectedObjects())
        	if (o instanceof IModelProvider)
        		selectedModelObjects.add(((IModelProvider)o).getNEDModel().deepDup());
        if (selectedModelObjects.size() > 0)
        	Clipboard.getDefault().setContents(selectedModelObjects.toArray(new INEDElement[]{}));
    }

}
