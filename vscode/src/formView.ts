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

import { begin, end } from './html';
import { formStyles } from './styles';
import data from './templateDetails.json';

export function getFormView(templateSelected: string): string {

    let templateObject = data.find(x => x.id === templateSelected);
    let templateName = templateObject.name;
    let templatePlaceholders = templateObject.placeholders;

    let beginForm: string = `
            <h2 style="margin-left:20px;">${templateName}</h2>
            <div class="container">
                <form action="" id="placeholderForm" onsubmit="sendPlaceholders()">`;

    let i = 0;
    let elements: string = "";
    templatePlaceholders.forEach(element => {
        elements += `
        ${element.id}: elements[${i}].value,`;
        i++;
    });

    let scriptHandling = `
            <script>
                function sendPlaceholders() {
                    var elements = document.getElementById("placeholderForm").elements;
                    const vscode = acquireVsCodeApi();
                    vscode.postMessage({
                        ` + elements + `
                        command: ''
                    })
                }
                function goBack() {
                    const vscode = acquireVsCodeApi();
                    vscode.postMessage({
                        command: 'back'
                    })
                }
            </script>`;

    let htmlCode = begin + formStyles + scriptHandling + beginForm;
    let allFormElements: string = "";
    templatePlaceholders.forEach(element => {
        let formElement: string = "";
        let values = element.value;
        if (element.type !== "select") {
            formElement = `
                    <label for="${element.id}">${element.label}</label>
                    <input type="${element.type}" id="${element.id}" value="${element.value}">`;
        } else {
            formElement = `
                    <label for="${element.id}">${element.label}</label>
                    <select id="${element.id}">`;
            values.forEach(element => {
                formElement += `
                        <option value="${element}">${element}</option>`;
            });
            formElement += `
                    </select>`;
        }
        allFormElements += formElement;
    });

    let formEnd: string = `
                    <br/><br/>
                    <input type="submit" value="Create Project">
                    <br/><br/>
                    <button onclick="goBack()">Back to Templates</button>
                </form>
            </div>`;

    htmlCode = htmlCode + allFormElements + formEnd + end;
    return htmlCode;
}
