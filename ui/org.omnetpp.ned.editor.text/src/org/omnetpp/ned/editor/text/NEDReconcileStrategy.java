package org.omnetpp.ned.editor.text;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.runtime.Assert;
import org.eclipse.jface.text.IDocument;
import org.eclipse.jface.text.IRegion;
import org.eclipse.jface.text.reconciler.DirtyRegion;
import org.eclipse.jface.text.reconciler.IReconcilingStrategy;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.IFileEditorInput;
import org.omnetpp.ned.resources.NEDResourcesPlugin;

/**
 * This class has one instance per NED editor, and performs 
 * background NED parsing.
 */
public class NEDReconcileStrategy implements IReconcilingStrategy {

	private IEditorPart editor= null; // because NEDResourcesPlugin needs IFile!
	private IDocument document = null;
	
	public NEDReconcileStrategy(IEditorPart editor) {
		this.editor = editor;
	}

	public void setDocument(IDocument document) {
		this.document = document;
	}

	public void reconcile(DirtyRegion dirtyRegion, IRegion subRegion) {
		// XXX this does not seem to get called, at least in our setup...
		System.out.println("reconcile(DirtyRegion,IRegion) called");
	}

	public void reconcile(IRegion partition) {
		System.out.println("reconcile(IRegion) called");
		Assert.isTrue(editor.getEditorInput() instanceof IFileEditorInput); // NEDEditor only accepts file input
		IFile file = ((IFileEditorInput)editor.getEditorInput()).getFile();
		String nedtext = document.get();

		// perform parsing (of full text, we ignore the changed region)
		NEDResourcesPlugin.getNEDResources().setNEDFileContents(file, nedtext);
	}

}
