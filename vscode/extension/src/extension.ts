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

// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import vscode, { commands, window, ViewColumn } from 'vscode';
import { createTemplateProject } from './createProject';

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {

	// Use the console to output diagnostic information (console.log) and errors (console.error)
	// This line of code will only be executed once when your extension is activated
	console.log('Extension "ballerina-integrator" is now active!');
	let currentPanel: vscode.WebviewPanel | undefined;
	// The command has been defined in the package.json file
	// Now provide the implementation of the command with registerCommand
	// The commandId parameter must match the command field in package.json
	let disposable = commands.registerCommand('ballerinaIntegrator.projectTemplates', () => {
		// The code you place here will be executed every time your command is executed
		const columnToShowIn = window.activeTextEditor
			? window.activeTextEditor.viewColumn
			: undefined;
		if (currentPanel) {
			// If we already have a panel, show it in the target column
			currentPanel.reveal(columnToShowIn);
		} else {
			currentPanel = window.createWebviewPanel(
				'ballerinaIntegrator', // Identifies the type of the webview. Used internally
				'Ballerina Integrator Templates', // Title of the panel displayed to the user
				ViewColumn.One, // Editor column to show the new webview panel in.
				{
					enableScripts: true
				} // Webview options. More on these later.
			);
			currentPanel.onDidDispose(
				() => {
					// When the panel is closed, cancel any future updates to the webview content
					currentPanel = undefined;
				},
				null,
				context.subscriptions
			);
			createTemplateProject(currentPanel, context);
		}
	});
	context.subscriptions.push(disposable);
}

// this method is called when your extension is deactivated
export function deactivate() { }
