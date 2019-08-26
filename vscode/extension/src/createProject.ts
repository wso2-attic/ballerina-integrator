// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import vscode, { workspace, window } from 'vscode';
import data from './templateDetails.json';
import ProjectTemplates from './projectTemplates';
import { getHomeView } from './homeView';
import { getFormView } from './formView';
import { mapToObj } from './utils';

/**
 * Displays the set of templates available and once a template is selected, 
 * the required parameters will be obtained to create a new project from the 
 * template after replacing the placeholder values. If a workspace is not 
 * open the user will be informed to open a folder first. If multiple workspaces 
 * are open, the user will be prompted to select the desired workspace. 
 * @param currentPanel WebView panel that is opened through the extension.
 * @param context ExtensionContext of the extension. 
 */
export async function createTemplateProject(currentPanel: vscode.WebviewPanel, context: vscode.ExtensionContext) {
    let templateSelected = undefined;
    let projectTemplates = new ProjectTemplates(context, workspace.getConfiguration('projectTemplates'));
    // get workspace folder
    let workspaceSelected = await ProjectTemplates.selectWorkspace();
    // generate the home page to display templates
    currentPanel.webview.html = getHomeView();
    currentPanel.webview.onDidReceiveMessage(
        homePageMessage => {
            if (!workspaceSelected) {
                window.showErrorMessage("No Workspace Selected!");
                return;
            }
            templateSelected = homePageMessage.command;
            // generate the placeholder form for a specific template
            currentPanel.webview.html = getFormView(templateSelected);
            currentPanel.webview.onDidReceiveMessage(
                async formPageMessage => {
                    if (formPageMessage.command === "back") {
                        currentPanel.dispose();
                        vscode.commands.executeCommand("ballerinaIntegrator.projectTemplates");
                        return;
                    } else {
                        projectTemplates.updateConfiguration(workspace.getConfiguration('projectTemplates'));
                        let templateObject = data.find(x => x.id === homePageMessage.command);
                        let templatePlaceholders = templateObject.placeholders;
                        let placeholderMap = new Map();
                        templatePlaceholders.forEach(element => {
                            placeholderMap.set(element.name, formPageMessage[element.id]);
                        });
                        let placeholders = mapToObj(placeholderMap);
                        currentPanel.dispose();
                        projectTemplates.createFromTemplate(workspaceSelected, homePageMessage.command, placeholders).then(
                            (template: string | undefined) => {
                                if (template) {
                                    window.showInformationMessage("New template project created for '" +
                                        templateObject.name + "'!");

                                }
                            },
                            (reason: any) => {
                                if (reason === "false") {
                                    window.showInformationMessage("Project creation aborted!");
                                } else {
                                    window.showErrorMessage("Failed to create project from template: " + reason);
                                }
                            }
                        );
                    }
                },
                undefined,
                context.subscriptions
            );
        },
        undefined,
        context.subscriptions
    );
    return templateSelected;
}
