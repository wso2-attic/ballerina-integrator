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
    for (var templateCategory in data) {
        let startTags: string = `
            <div class="row">
                <div class="templates">
                    <h3>` + templateCategory + `</h3>`;

        htmlCode = htmlCode + startTags;
        data[templateCategory].forEach(element => {
            let templateId = element.id;
            let templateName = element.name;
            let templateDescription = element.description;
            let card: string = `
                    <div class="col-md-3 col-xs-4 col-lg-3">
                        <div class="box">
                            <h4>` + templateName + `</h4>
                            <p class="description" align="center">` + templateDescription + `</p>
                            <a href="" style="none" onclick="pickTemplate('${templateId}')">
                                <p class="create-button">
                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 52 52">
                                        <path d="M26,0A26,26,0,1,0,52,26,26,26,0,0,0,26,0ZM38.5,28H28V39a2,2,0,0,1-4,0V28H13.5a2,
                                        2,0,0,1,0-4H24V14a2,2,0,0,1,4,0V24H38.5a2,2,0,0,1,0,4Z" />
                                    </svg>
                                    Create
                                </p>
                            </a>
                        </div>
                    </div>`;
            htmlCode = htmlCode + card;
        });
        let endTags: string = `
                </div>
            </div>`;
        htmlCode = htmlCode + endTags;
    }

    let scriptHandling = `
            <script>
                function pickTemplate(template) {
                    const vscode = acquireVsCodeApi();
                    vscode.postMessage({
                        command: template
                    })
                }
                function searchFunction() {
                    var categoryPicker = document.getElementById("templateCategory");
                    var category = categoryPicker.options[categoryPicker.selectedIndex].text;
                    var input, filter;
                    input = document.getElementById("searchTemplate");
                    filter = input.value.toUpperCase();
                    var templateCategories = document.getElementsByClassName("templates");
                    for (var i = 0; i < templateCategories.length; i++) {
                        var name = templateCategories[i].getElementsByTagName("h3");
                        if (category == "Search Category") {
                            var count = 0;
                            templateCategories[i].style.display = "";
                            var boxes = templateCategories[i].getElementsByClassName("col-md-3 col-xs-4 col-lg-3");
                            for (var j = 0; j < boxes.length; j++) {
                                var heading = boxes[j].getElementsByTagName("h4");
                                var txtValue = heading[0].textContent || heading[0].innerText;
                                if (txtValue.toUpperCase().indexOf(filter) > -1) {
                                    boxes[j].style.display = "";
                                    count = count + 1;
                                } else {
                                    boxes[j].style.display = "none";
                                }
                            }
                            if (count == 0) {
                                name[0].style.display = "none";
                            } else {
                                name[0].style.display = "";
                            }
                        } else if (name[0].textContent.localeCompare(category) == 0) {
                            templateCategories[i].style.display = "";
                            var boxes = templateCategories[i].getElementsByClassName("col-md-3 col-xs-4 col-lg-3");
                            for (var j = 0; j < boxes.length; j++) {
                                var heading = boxes[j].getElementsByTagName("h4");
                                var txtValue = heading[0].textContent || heading[0].innerText;
                                if (txtValue.toUpperCase().indexOf(filter) > -1) {
                                    boxes[j].style.display = "";
                                } else {
                                    boxes[j].style.display = "none";
                                }
                            }
                        } else {
                            templateCategories[i].style.display = "none";
                        }
                    }
                }
            </script>`;

    htmlCode = htmlCode + scriptHandling + end;
    return htmlCode;
}
