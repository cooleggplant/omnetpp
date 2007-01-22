package org.omnetpp.ned.editor.graph.wizards;

import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.wizard.Wizard;
import org.eclipse.ui.INewWizard;
import org.eclipse.ui.IWorkbench;

public class NewNEDFileWizard extends Wizard implements INewWizard {
    private NewNEDFileWizardPage1 page1 = null;

    private IStructuredSelection selection;

    private IWorkbench workbench;

    @Override
    public void addPages() {
        page1 = new NewNEDFileWizardPage1(workbench, selection);
        addPage(page1);
    }

    public void init(IWorkbench aWorkbench, IStructuredSelection currentSelection) {
        workbench = aWorkbench;
        selection = currentSelection;
    }

    @Override
    public boolean performFinish() {
        return page1.finish();
    }

}