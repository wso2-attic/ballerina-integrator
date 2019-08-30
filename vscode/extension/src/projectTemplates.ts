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

'use strict';

import { WorkspaceConfiguration } from 'vscode';
import vscode, { workspace, window } from 'vscode';
import fs = require('fs');
import path = require('path');
import utils = require("./utils");
import data from './templateDetails.json';

export default class ProjectTemplates {
    /**
     * Local copy of workspace configuration is used to maintain consistency between calls.
     */
    config: WorkspaceConfiguration;
    context: vscode.ExtensionContext;

    constructor(context: vscode.ExtensionContext, config: WorkspaceConfiguration) {
        this.config = config;
        this.context = context;
    }

    /**
     * Updates the current configuration settings.
     * @param config Workspace configuration.
     */
    public updateConfiguration(config: WorkspaceConfiguration) {
        this.config = config;
    }

    /**
     * Selects a workspace folder. For single root workspaces the root directory 
     * will be selected, or for multi-root a chooser will be presented to select a workspace.
     * @returns The workspace selected.
     */
    public static async selectWorkspace(): Promise<string> {

        let workspaceSelected: string = "";
        if (workspace.workspaceFolders) {
            // checks if single or multi-root
            if (workspace.workspaceFolders.length === 1) {
                workspaceSelected = workspace.workspaceFolders[0].uri.fsPath;
            } else if (workspace.workspaceFolders.length > 1) {
                // choose workspace
                let ws = await window.showWorkspaceFolderPick();
                if (ws) {
                    window.showInformationMessage(ws.name);
                    workspaceSelected = ws.uri.fsPath;
                }
            }
        }
        return workspaceSelected;
    }

    /**
     * Returns the templates directory location.
     * It will look for the path defined in the extension configuration.
     * @return The templates directory will be returned.
     */
    public async getTemplatesDir(): Promise<string> {

        let dir = this.config.get('templatesDirectory').toString();
        dir = path.join(this.context.extensionPath, dir);
        console.log(dir);
        return Promise.resolve(dir);
    }

    /**
     * Replaces any placeholders found within the input data.  Will use a 
     * dictionary of values from the user's workspace settings, or will prompt
     * if value is not known.
     * @param data Input data.
     * @param placeholderRegExp Regular expression used for detecting 
     *                          placeholders. The first capture group is used
     *                          as the key.
     * @param placeholders Dictionary of placeholder key-value pairs.
     * @returns Ppotentially modified data, with the same type as the input data.
     */
    private async resolvePlaceholders(data: string | Buffer, placeholderRegExp: string,
        placeholders: { [placeholder: string]: string | undefined }): Promise<string | Buffer> {

        // resolve each placeholder
        let regex = RegExp(placeholderRegExp, 'g');
        // collect set of expressions and their replacements
        let match;
        let nmatches = 0;
        let str: string;
        let encoding: string = "utf8";
        if (Buffer.isBuffer(data)) {
            // get default encoding
            let fconfig = workspace.getConfiguration('files');
            encoding = fconfig.get("files.encoding", "utf8");
            try {
                str = data.toString(encoding);
            } catch (Err) {
                // cannot decipher text from encoding, assume raw data
                return data;
            }
        } else {
            str = data;
        }
        while (match = regex.exec(str)) {
            let key = match[1];
            let val: string | undefined = placeholders[key];
            if (!val) {
                let variableInput = <vscode.InputBoxOptions>{
                    prompt: `Please enter a value for: ` + match[0]
                };
                val = await window.showInputBox(variableInput).then(
                    value => {
                        if (value) {
                            // update map
                            placeholders[key] = value;
                        }
                        return value;
                    }
                );
            }
            ++nmatches;
        }
        // reset regex
        regex.lastIndex = 0;
        // compute output
        let out: string | Buffer = data;
        if (nmatches > 0) {
            // replace placeholders in string
            str = str.replace(regex,
                (match, key) => {
                    let val = placeholders[key];
                    if (!val) {
                        val = match;
                    }
                    return val;
                }
            );
            // if input was a buffer, re-encode to buffer
            if (Buffer.isBuffer(data)) {
                out = Buffer.from(str, encoding);
            } else {
                out = str;
            }
        }
        return out;
    }

    /**
     * Populates a workspace folder with the contents of a template.
     * @param workspace Current workspace folder to populate.
     * @param template Relative path to the template folder.
     * @param placeholderValues Placeholder key-value pairs.
     */
    public async createFromTemplate(workspace: string, template: string, placeholderValues: any) {

        // get template folder
        let templateRoot = await this.getTemplatesDir();
        let templateDir = path.join(templateRoot, template);
        if (!fs.existsSync(templateDir) || !fs.lstatSync(templateDir).isDirectory()) {
            window.showErrorMessage("Template '" + data.find(x => x.id === template).name + "' does not exist.");
            return undefined;
        }
        // update placeholder configuration
        let usePlaceholders = this.config.get("usePlaceholders", false);
        let placeholderRegExp = this.config.get("placeholderRegExp", "\\${(\\w+)?}");
        // let placeholders: { [placeholder: string]: string | undefined } = this.config.get("placeholders", {});
        let placeholders = placeholderValues;
        // re-read configuration, merge with current list of placeholders
        let newPlaceholders: { [placeholder: string]: string } = this.config.get("placeholders", {});
        for (let key in newPlaceholders) {
            placeholders[key] = newPlaceholders[key];
        }
        // recursively copy files, replacing placeholders as necessary
        let copyFunc = async (src: string, dest: string) => {
            // maybe replace placeholders in filename
            if (usePlaceholders) {
                dest = await this.resolvePlaceholders(dest, placeholderRegExp, placeholders) as string;
            }
            if (fs.lstatSync(src).isDirectory()) {
                // create directory if doesn't exist
                if (!fs.existsSync(dest)) {
                    fs.mkdirSync(dest);
                } else if (!fs.lstatSync(dest).isDirectory()) {
                    // fail if file exists
                    throw new Error("Failed to create directory '" + dest + "': file with same name exists.");
                }
            } else {
                // ask before overwriting existing file
                while (fs.existsSync(dest)) {
                    // if it is not a file, cannot overwrite
                    if (!fs.lstatSync(dest).isFile()) {
                        let reldest = path.relative(workspace, dest);
                        let variableInput = <vscode.InputBoxOptions>{
                            prompt: `Cannot overwrite "${reldest}".  Please enter a new filename"`,
                            value: reldest
                        };
                        // get user's input
                        dest = await window.showInputBox(variableInput).then(
                            value => {
                                if (!value) {
                                    return dest;
                                }
                                return value;
                            }
                        );
                        // if not absolute path, make workspace-relative
                        if (!path.isAbsolute(dest)) {
                            dest = path.join(workspace, dest);
                        }
                    } else {
                        // ask if user wants to replace, otherwise prompt for new filename
                        let reldest = path.relative(workspace, dest);
                        let choice = await window.showQuickPick(["Overwrite", "Rename", "Skip", "Abort"], {
                            placeHolder: `Destination file "${reldest}" already exists.  What would you like to do?`
                        });
                        if (choice === "Overwrite") {
                            // delete existing file
                            fs.unlinkSync(dest);
                        } else if (choice === "Rename") {
                            // prompt user for new filename
                            let variableInput = <vscode.InputBoxOptions>{
                                prompt: "Please enter a new filename",
                                value: reldest
                            };
                            // get user's input
                            dest = await window.showInputBox(variableInput).then(
                                value => {
                                    if (!value) {
                                        return dest;
                                    }
                                    return value;
                                }
                            );
                            // if not absolute path, make workspace-relative
                            if (!path.isAbsolute(dest)) {
                                dest = path.join(workspace, dest);
                            }
                        } else if (choice === "Skip") {
                            // skip
                            return true;
                        } else {
                            // abort
                            return Promise.reject("false");
                        }
                    }
                }
                // get src file contents
                let fileContents: Buffer = fs.readFileSync(src);
                if (usePlaceholders) {
                    fileContents = await this.resolvePlaceholders(fileContents, placeholderRegExp, 
                        placeholders) as Buffer;
                }
                // ensure directories exist
                let parent = path.dirname(dest);
                utils.mkdirsSync(parent);
                // write file contents to destination
                fs.writeFileSync(dest, fileContents);
            }
            return true;
        };
        // actually copy the file recursively
        await this.recursiveApplyInDir(templateDir, workspace, copyFunc);
        return template;
    }

    /**
    * Recursively apply a function on a pair of files or directories from source to dest.
    * @param src Source file or folder.
    * @param dest Destination file or folder.
    * @param func Function to apply between src and dest.
    * @return If recursion should continue.
    */
    private async recursiveApplyInDir(src: string, dest: string,
        func: (src: string, dest: string) => Promise<boolean>): Promise<boolean> {

        // apply function between src/dest
        let success = await func(src, dest);
        if (!success) {
            return false;
        }
        if (fs.lstatSync(src).isDirectory()) {
            // read contents of source directory and iterate
            const entries: string[] = fs.readdirSync(src);
            for (let entry of entries) {
                // full path of src/dest
                const srcPath = path.join(src, entry);
                const destPath = path.join(dest, entry);
                // if directory, recursively copy, otherwise copy file
                success = await this.recursiveApplyInDir(srcPath, destPath, func);
                if (!success) {
                    return false;
                }
            }
        }
        return true;
    }
}
