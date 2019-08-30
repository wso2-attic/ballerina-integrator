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

export let homeStyles: string = `
            <style>
                * {
                    box-sizing: border-box;
                }

                body.vscode-light {
                    color: black;
                }
                
                body.vscode-dark {
                    color: white;
                }
                
                body.vscode-high-contrast {
                    color: red;
                }

                body {
                    font-family: Arial, Helvetica, sans-serif;
                }

                a {
                    text-decoration: none;
                    color: #c2c3cb;
                }

                a:hover { 
                    color: #20B2AA; 
                }

                .card {
                    box-shadow: 4px 4px 4px 4px rgba(0,0,0,0.2);
                    transition: 0.3s;
                    width: 100%;
                    border-radius: 15px;
                    padding: 20px;
                    text-align: center;
                }
                
                /* Float four columns side by side */
                .column {
                    float: left;
                    width: 33.33%;
                    padding: 16px;
                    display: table-cell;
                }
                
                /* Remove extra left and right margins, due to padding */
                .row {
                    margin: 0 -5px;
                    display: table;
                    width: 100%;
                }
                
                /* Clear floats after the columns */
                .row:after {
                    content: "";
                    display: table;
                    clear: both; 
                }
                
                /* Responsive columns */
                @media screen and (max-width: 600px) {
                    .column {
                        width: 100%;
                        display: table-cell;
                    }
                }
                
                .card:hover {
                    box-shadow: 0 16px 16px 0 rgba(0,0,0,0.2);
                }
            </style>`;

export let formStyles: string = `
            <style>
                body {
                    font-family: Arial, Helvetica, sans-serif;
                }

                * {
                    box-sizing: border-box;
                }

                body.vscode-light {
                    color: black;
                }
                
                body.vscode-dark {
                    color: white;
                }
                
                body.vscode-high-contrast {
                    color: red;
                }
                
                input[type=text], select, textarea {
                    width: 100%;
                    padding: 12px;
                    border: 1px solid #ccc;
                    border-radius: 4px;
                    box-sizing: border-box;
                    margin-top: 6px;
                    margin-bottom: 16px;
                    resize: vertical;
                }
                
                input[type=submit], button {
                    background-color: #5F9EA0;
                    color: white;
                    padding: 12px 20px;
                    border: none;
                    border-radius: 4px;
                    cursor: pointer;
                }
                
                input[type=submit]:hover, button:hover {
                    background-color: #20B2AA;
                }
                
                .container {
                    border-radius: 5px;
                    padding: 20px;
                    width: 50%
                }
            </style>`;
