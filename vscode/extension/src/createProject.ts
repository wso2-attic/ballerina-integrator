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

import vscode, { OpenDialogOptions, Uri, window } from 'vscode';
import { getHomeView } from './homeView';

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
    // generate the home page to display templates
    currentPanel.webview.html = getHomeView();
    let moduleName = undefined;
    let projectName = undefined;
    let folderPath = undefined;
    let projectPath = undefined;
    currentPanel.webview.onDidReceiveMessage(
        async homePageMessage => {
            templateSelected = homePageMessage.command;
            if (templateSelected === "new_project") {
                projectName = await window.showInputBox({
                    value: "new_project",
                    prompt: "Enter value for project name",
                    placeHolder: "new_project"
                }).then(text => text);
                if (projectName != undefined) {
                    projectPath = await openDialogForFolder();
                    let projectUri = vscode.Uri.parse(projectPath);
                    if (projectPath != undefined) {
                        const cp = require('child_process');
                        await cp.exec('cd ' + projectUri.path + ' && ballerina new ' + projectName, (err, stdout, stderr) => {
                            const message = "Created new ballerina project";
                            if (stderr.search(message) !== -1 || stdout.search(message)) {
                                vscode.commands.executeCommand('vscode.openFolder', projectUri);
                                window.showInformationMessage("Successfully created a new Ballerina project at " + projectUri.path);
                            } else {
                                window.showErrorMessage(stderr);
                            }
                        });
                    }
                }
                currentPanel.dispose();
                vscode.commands.executeCommand("ballerinaIntegrator.projectTemplates");
            } else {
                moduleName = await window.showInputBox({
                    value: templateSelected,
                    prompt: "Enter value for module name",
                    placeHolder: templateSelected
                }).then(text => text);
                if (moduleName != undefined) {
                    folderPath = await openDialogForFolder();
                    let uri = vscode.Uri.parse(folderPath);
                    if (folderPath != undefined) {
                        const cp = require('child_process');
                        const addCommand = 'cd ' + uri.path + ' && ballerina add ' + moduleName + ' -t wso2/' + templateSelected;
                        await cp.exec(addCommand, (err, stdout, stderr) => {
                            if (err) {
                                window.showErrorMessage("Error: " + err);
                            } else if (stderr) {
                                const message = "not a ballerina project";
                                const successMessage = "Added new ballerina module";
                                if (stderr.search(successMessage) !== -1) {
                                    window.showInformationMessage(stderr);
                                    vscode.commands.executeCommand('vscode.openFolder', uri);
                                }
                                else if (stderr.search(message) !== -1) {
                                    window.showErrorMessage("Please select a Ballerina project!");
                                } else {
                                    window.showErrorMessage(stderr);
                                }
                            }
                        });
                    }
                }
                currentPanel.dispose();
                vscode.commands.executeCommand("ballerinaIntegrator.projectTemplates");
            }
        },
        undefined,
        context.subscriptions
    );
    return;
}

async function openDialogForFolder(): Promise<Uri | null> {
    const options: OpenDialogOptions = {
        canSelectFiles: false,
        canSelectFolders: true,
        canSelectMany: false
    };
    const result: Uri[] | undefined = await window.showOpenDialog(Object.assign(options));
    if (result && result.length > 0) {
        return Promise.resolve(result[0]);
    } else {
        return Promise.resolve(null);
    }
}
