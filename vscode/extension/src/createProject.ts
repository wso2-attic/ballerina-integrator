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
import { extractErrorMessage } from './utils';

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
    let uri = undefined;
    let projectUri = undefined;
    currentPanel.webview.onDidReceiveMessage(
        async homePageMessage => {
            const childProcess = require('child_process');
            templateSelected = homePageMessage.command;
            // Creating a new Ballerina project.
            if (templateSelected === "new_project") {
                // Project name.
                projectName = await window.showInputBox({
                    value: "new_project",
                    prompt: "Enter project name",
                    placeHolder: "new_project"
                }).then(text => text);
                if (projectName != undefined) {
                    // Module name.
                    moduleName = await window.showInputBox({
                        value: "new_module",
                        prompt: "Enter module name",
                        placeHolder: "new_module"
                    }).then(text => text);
                }
                if (projectName != undefined && moduleName != undefined) {
                    // Get path to create the Ballerina project in.
                    projectPath = await openDialogForFolder("Create");
                    let projectUri = vscode.Uri.parse(projectPath);
                    if (projectPath != undefined) {
                        const newCommand = 'cd ' + projectUri.fsPath + ' && ballerina new ' + projectName;
                        // Execute the Ballerina new command to create a project.
                        await new Promise((resolve, reject) => {
                            childProcess.exec(newCommand, newProjectCommand(reject, projectUri, resolve, currentPanel));
                        });
                        let projectFolder = appendPath(projectUri.fsPath, projectName);
                        const addCommandWithoutTemplate = 'cd ' + projectFolder.fsPath + ' && ballerina add ' + moduleName;
                        // Execute the Ballerina add command to create a module inside the project created.
                        await new Promise((resolve, reject) => {
                            childProcess.exec(addCommandWithoutTemplate, async (err, stderr, stdout) => {
                                if (err) {
                                    window.showErrorMessage(err);
                                    reject();
                                } else {
                                    const successMessage = "Added new ballerina module";
                                    if (stdout.search(successMessage) !== -1) {
                                        window.showInformationMessage(stdout);
                                        // Open in New Window or Existing Window
                                        const newWindowOption = await vscode.window.showQuickPick(
                                            ['New Window', 'Existing Window'], 
                                            { placeHolder: "Open project in a new window or in existing window"});
                                        if (newWindowOption != undefined) {
                                            if (newWindowOption == "New Window") {
                                                vscode.commands.executeCommand('vscode.openFolder', projectFolder, true);
                                            } else if (newWindowOption == "Existing Window"){
                                                vscode.commands.executeCommand('vscode.openFolder', projectFolder);
                                            }
                                        }
                                    } else {
                                        window.showErrorMessage(stdout + " " + stderr);
                                        reject();
                                    }
                                }
                            });
                            resolve();
                        });
                    }
                }
                currentPanel.dispose();
                vscode.commands.executeCommand("ballerina.integrator.activate");
            } else {
                const addListCommand = 'ballerina add --list';
                const pullCommand = 'ballerina pull wso2/' + templateSelected;
                let pull = false;
                let projectFolder = null;
                // Performs a Ballerina add list command to check if the required module template is available,
                // else pull variable is set to true.
                await new Promise((resolve, reject) => {
                    childProcess.exec(addListCommand, async (err, stderr, stdout) => {
                        if (stdout.search(templateSelected) == -1 || err) {
                            pull = true;
                        }
                        resolve();
                    });
                });
                // Get the module name for the template.
                moduleName = await window.showInputBox({
                    value: templateSelected,
                    prompt: "Enter module name",
                    placeHolder: templateSelected
                }).then(text => text);
                if (moduleName != undefined) {
                    // Get input on where the new module should be created.
                    const projectOption = await vscode.window.showQuickPick(['New Project', 'Existing Project'],
                        { placeHolder: 'Creating a new project or adding the module to an existing project?' });
                    if (projectOption != undefined) {
                        // If the module is to be created inside a new project.
                        if (projectOption == "New Project") {
                            // Get project name from the user.
                            projectName = await window.showInputBox({
                                prompt: "Enter project name"
                            }).then(text => text);
                            if (projectName != undefined) {
                                // Open path to create the new project.
                                folderPath = await openDialogForFolder("Create");
                                let projectUri = vscode.Uri.parse(folderPath);
                                if (folderPath != undefined) {
                                    const newCommand = 'cd ' + projectUri.fsPath + ' && ballerina new ' + projectName;
                                    await new Promise((resolve, reject) => {
                                        childProcess.exec(newCommand, newProjectCommand(reject, projectUri, resolve, currentPanel));
                                    });
                                    uri = appendPath(projectUri.fsPath, projectName).fsPath;
                                    projectFolder = appendPath(projectUri.fsPath, projectName);
                                }
                            }
                        // If the module is to be created inside an existing project.
                        } else if (projectOption == "Existing Project") {
                            // Select the existing Ballerina project.
                            folderPath = await openDialogForFolder("Select Ballerina Project");
                            projectUri = vscode.Uri.parse(folderPath);
                            uri = projectUri.fsPath;
                        }
                        if (folderPath != undefined) {
                            const addCommand = 'cd ' + uri + ' && ballerina add ' + moduleName + ' -t wso2/'
                                + templateSelected;
                            // Pulls the template module from Ballerina Central if pull value is true.
                            if (pull) {
                                await new Promise((resolve, reject) => {
                                    window.showInformationMessage("Pulling the module template from Ballerina Central!");
                                    childProcess.exec(pullCommand, (err, stderr, stdout) => {
                                        if (err) {
                                            window.showErrorMessage("Error occured while pulling the module template!");
                                        }
                                        resolve();
                                    });
                                });
                            }
                            // Adds the new module to the project selected or created.
                            await new Promise((resolve, reject) => {
                                childProcess.exec(addCommand, async (err, stderr, stdout) => {
                                    if (err) {
                                        window.showErrorMessage(err);
                                        reject();
                                    } else {
                                        const message = "not a ballerina project";
                                        const successMessage = "Added new ballerina module";
                                        if (stdout.search(successMessage) !== -1) {
                                            if (projectOption == "New Project") {
                                                // Open in New Window or Existing Window
                                                const newWindowOption = await vscode.window.showQuickPick(
                                                    ['New Window', 'Existing Window'], 
                                                    { placeHolder: "Open project in a new window or in existing window"});
                                                if (newWindowOption != undefined) {
                                                    if (newWindowOption == "New Window") {
                                                        vscode.commands.executeCommand('vscode.openFolder', projectFolder, true);
                                                    } else if (newWindowOption == "Existing Window"){
                                                        vscode.commands.executeCommand('vscode.openFolder', projectFolder);
                                                    }
                                                }
                                            } else {
                                                vscode.commands.executeCommand('vscode.openFolder', projectFolder, true);
                                            }
                                            window.showInformationMessage(stdout);
                                        } else if (stdout.search(message) !== -1) {
                                            window.showErrorMessage("Please select a Ballerina project!");
                                        } else {
                                            window.showErrorMessage(extractErrorMessage(stdout));
                                        }
                                        resolve();
                                    }
                                });
                            });
                        }
                    }
                }
                currentPanel.dispose();
                vscode.commands.executeCommand("ballerina.integrator.activate");
            }
        },
        undefined,
        context.subscriptions
    );
    return;
}

function appendPath (path: string, appendString: string): Uri {
    let completePath = path + "/" + appendString;
    return vscode.Uri.file(completePath);
}

// Handles the new project creation command result.
function newProjectCommand(reject: (reason?: any) => void, projectUri: vscode.Uri, resolve: (value?: unknown) => void, currentPanel:vscode.WebviewPanel): any {
    return (err, stderr, stdout) => {
        const message = "Created new Ballerina project";
        if (err) {
            window.showErrorMessage(err);
            reject();
        }
        else if (stdout.search(message) !== -1) {
            window.showInformationMessage("Successfully created a new Ballerina project at "
                + projectUri.fsPath);
            resolve();
        }
        else {
            window.showErrorMessage(extractErrorMessage(stdout));
            currentPanel.dispose();
            vscode.commands.executeCommand("ballerina.integrator.activate");
            reject();
        }
    };
}

// Handles the folder pick input.
async function openDialogForFolder(buttonText: string): Promise<Uri | null> {
    const options: OpenDialogOptions = {
        openLabel: buttonText,
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
