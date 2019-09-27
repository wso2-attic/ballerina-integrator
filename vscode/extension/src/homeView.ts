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
import data from './templateDetails.json';

export function getHomeView(): string {
    let htmlCode = begin;
    for (var i=0; i<data.length; i++) {
        let templateId = data[i].id;
        let templateName = data[i].name;
        let templateDescription = data[i].description;
        let tags = data[i].tags;
        let markElements: string = "";
        tags.forEach(element => {
            markElements += `
                            <mark class="tag-mark">` + element + `</mark>`;
        });
        let card: string = `
                <div class="col-md-3 col-xs-4 col-lg-3">
                    <div class="box">
                        <h4>` + templateName + `</h4>
                        <p class="description" align="center">` + templateDescription + `</p>
                        <p class="tag">` + markElements + `
                        </p>
                        <a href="" style="none" onclick="pickTemplate('${templateId}')">
                            <p class="create-button">
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 52 52">
                                    <path d="M26,0A26,26,0,1,0,52,26,26,26,0,0,0,26,0ZM38.5,28H28V39a2,2,0,0,1-4,
                                    0V28H13.5a2,2,0,0,1,0-4H24V14a2,2,0,0,1,4,0V24H38.5a2,2,0,0,1,0,4Z" />
                                </svg>
                                Create
                            </p>
                        </a>
                    </div>
                </div>`;
        htmlCode = htmlCode + card;
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
                    // Retrieve the selected category
                    var categoryPicker = document.getElementById("templateCategory");
                    var category = categoryPicker.options[categoryPicker.selectedIndex].value;

                    // Retrieve the search input values
                    var input, filter;
                    input = document.getElementById("searchTemplate");
                    filter = input.value.toUpperCase();

                    // Retrieve all the box elements
                    var boxes = document.getElementsByClassName("col-md-3 col-xs-4 col-lg-3");

                    for (var i = 0; i < boxes.length; i++) {
                        var tags = boxes[i].getElementsByClassName("tag-mark");
                        for (var j = 0; j < tags.length; j++) {
                            var txtValue = tags[0].textContent || tags[0].innerText;
                            if (category == "#all") {
                                // Processing for 'all' category
                                boxes[i].hidden = false;
                                var heading = boxes[i].getElementsByTagName("h4");
                                var headingValue = heading[0].textContent || heading[0].innerText;
                                if (headingValue.toUpperCase().indexOf(filter) > -1) {
                                    boxes[i].hidden = false;
                                } else {
                                    boxes[i].hidden = true;
                                }
                            } else if (txtValue.toUpperCase().indexOf(category.toUpperCase()) > -1) {
                                // Processing for other specific categories
                                boxes[i].hidden = false;
                                var heading = boxes[i].getElementsByTagName("h4");
                                var headingValue = heading[0].textContent || heading[0].innerText;
                                if (headingValue.toUpperCase().indexOf(filter) > -1) {
                                    boxes[i].hidden = false;
                                } else {
                                    boxes[i].hidden = true;
                                }
                            } else {
                                // Hiding unselected categories
                                boxes[i].hidden = true;
                            }
                        }
                    }
                }
            </script>`;

    htmlCode = htmlCode + scriptHandling + end;
    return htmlCode;
}
