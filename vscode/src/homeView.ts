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
import { homeStyles } from './styles';
import data from './templateDetails.json';

export function getHomeView(): string {

    let htmlCode = begin + homeStyles;
    let rowHandleStart = `
            <div class="row">`;
    let rowHandleEnd = `
            </div>
            <br/>`;
    let numberOfColumns = 0;
    data.forEach(element => {
        let templateId = element.id;
        let templateName = element.name;
        let templateDescription = element.description;
        let card: string = `
                <div class="column">
                    <a href="#" style="none" onclick="pickTemplate('${templateId}')">
                        <div class="card">
                            <h2>` + templateName + `</h2><br/>
                            <p>` + templateDescription + `</p>
                        </div>
                    </a>  
                </div>`;
        if (numberOfColumns % 3 === 0) {
            htmlCode = htmlCode + rowHandleStart + card;
        }
        else if (numberOfColumns % 3 === 2) {
            htmlCode = htmlCode + card + rowHandleEnd;
        }
        else {
            htmlCode = htmlCode + card;
        }
        numberOfColumns++;
    });

    let scriptHandling = `
            <script>
                function pickTemplate(template) {
                    const vscode = acquireVsCodeApi();
                    vscode.postMessage({
                        command: template
                    })
                }
            </script>`;

    htmlCode = htmlCode + scriptHandling + end;
    return htmlCode;
}
