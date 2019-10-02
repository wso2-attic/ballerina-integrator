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

import { homeStyles } from './styles';

export let begin: string = `<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="description" content="">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link href="https://fonts.googleapis.com/css?family=Roboto:300,400,500&display=swap" rel="stylesheet">
        <title>Ballerina Integrator 1.0.0</title>
        ` + homeStyles + `
    </head>
    <body>
        <div class="container-fluid">
            <div class="row">
                <div class="col-md-12">
                    <h1 class="heading-page">Ballerina Integrator 1.0.0</h1>
                </div>
            </div>
            <div class="row">
                <div class="col-md-4 button-section">
                    <a href="" onclick="pickTemplate('new_project')">
                        <div class="create">
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 57 60">
                                <defs></defs>
                                <path d="M12.5,24h25a1,1,0,0,0,0-2h-25a1,1,0,0,0,0,2Zm0-8h10a1,1,0,0,0,
                                0-2h-10a1,1,0,0,0,0,2Zm0,16h25a1,1,0,0,0,0-2h-25a1,1,0,0,0,0,2Zm17,6h-17a1,1,0,0,0,0,
                                2h17a1,1,0,0,0,0-2Zm-3,8h-14a1,1,0,0,0,0,2h14a1,1,0,0,0,0-2Zm22-11.64V14.59L33.91,
                                0H1.5V60h44a13,13,0,0,0,3-25.64ZM34.5,3.41,45.09,14H34.5ZM38.58,
                                58H3.5V2h29V16h14V34c-.34,0-.67,0-1,0a13,13,0,0,0-13,13c0,.4,0,.79.06,1.18l0,.27c0,
                                .39.1.76.17,1.14l0,.13c.07.34.16.67.26,1,0,.08.05.16.07.24.11.35.24.7.38,
                                1l.09.19c.12.29.26.58.41.87,
                                0,.06.07.13.11.2.18.32.36.63.56.93l.15.2c.18.26.37.52.57.77l.11.14c.24.28.48.55.73.8l.19.19c.25.24.5.47.76.69l.07.06c.28.23.58.45.88.66l.22.15Zm6.92,
                                0a11,11,0,0,1,0-22c.31,0,.62,0,.93,0s.59.06.9.12l.45.07A11,11,0,0,1,45.5,
                                58Zm6-12h-5V41a1,1,0,0,0-2,0v5h-5a1,1,0,0,0,0,2h5v5a1,1,0,0,0,2,0V48h5a1,1,0,0,0,0-2Z"
                                    transform="translate(-1.5)" />
                            </svg>
                            Create New Project
                        </div>
                    </a>
                </div>
                <div class="col-md-4 button-section">
                    <a href="https://ei.docs.wso2.com/en/next/ballerina-integrator/getting-started/quick-start-guide/">
                        <div class="create">
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
                                <path d="M268.66,243.35a10,10,0,1,0,0,14.14A10,10,0,0,0,268.66,243.35ZM395.93,116.07a50,
                                50,0,1,0,0,70.71A50,50,0,0,0,395.93,116.07Zm-14.14,56.57a30,30,0,1,1,0-42.43A30.05,
                                30.05,0,0,1,381.79,172.64ZM509.07,2.93A9.94,9.94,0,0,0,501.64,0c-2.26.08-56.1,
                                2.24-120.09,24.86-51.28,18.11-94,44-127,77.05-7.4,7.4-14.6,15.25-21.49,
                                23.4-32.65-19.22-58.81-13.2-75.35-4.34C119.59,141.36,96,196.69,96,236.27a10,10,0,0,0,
                                17.07,7.07C133.18,223.26,158,224.51,166,225.58l3.5,3.5A353.16,353.16,0,0,0,153,277.65,
                                28.27,28.27,0,0,0,154.24,295a94.74,94.74,0,0,0-27,19c-25.74,25.74-31,88.48-31.18,
                                91.13A10,10,0,0,0,106,416l.79,0c2.66-.21,65.39-5.44,91.13-31.18a94.56,94.56,0,0,0,
                                19-27A28.23,28.23,0,0,0,234.36,359a350.82,350.82,0,0,0,48.56-16.52l3.5,3.5c1.07,8.1,
                                2.32,32.87-17.76,53A10,10,0,0,0,275.73,416c39.58,0,94.92-23.57,115.3-61.65,8.85-16.54,
                                14.87-42.7-4.35-75.35,8.15-6.89,16-14.09,23.4-21.49,33-33,58.94-75.76,77.05-127,
                                22.62-64,24.78-117.83,24.86-120.09A10,10,0,0,0,509.07,2.93ZM118.38,214.76c6.21-30.06,
                                24.25-63,48.73-76.15,16.36-8.76,34.24-7.9,53.25,2.51a404.05,404.05,0,0,0-42,68.49,10.46,
                                10.46,0,0,0-5.3-3.11A85.41,85.41,0,0,0,118.38,214.76ZM183.8,370.63c-13.75,13.75-46,
                                21-66.39,24,3-20.38,10.21-52.64,24-66.39A72,72,0,0,1,167,311.38L200.63,345A72.13,72.13,
                                0,0,1,183.8,370.63Zm45.59-31a9.38,9.38,0,0,1-8.74-2.83l-19.58-19.59-25.83-25.82a9.4,9.4,
                                0,0,1-2.84-8.74,325.11,325.11,0,0,1,12.48-38.2l82.7,82.7A325.58,325.58,0,0,1,229.39,
                                339.6Zm144,5.29c-13.1,24.48-46.09,42.52-76.15,48.73,9.59-18,11.7-41,8.2-54.92a10.42,
                                10.42,0,0,0-3-5.05,403.72,403.72,0,0,0,68.48-42C381.29,310.65,382.15,328.54,373.39,
                                344.89Zm22.55-101.54a360.71,360.71,0,0,1-28.84,25.87,384.18,384.18,0,0,1-79.72,
                                49.42l-94-94a384.44,384.44,0,0,1,49.42-79.72,364.61,364.61,0,0,1,
                                25.87-28.84c29.63-29.62,67.86-53.2,113.67-70.17l83.8,83.79C449.15,175.49,425.57,213.72,
                                395.94,243.35Zm77.37-134.76-69.89-69.9a449.19,449.19,0,0,1,87.74-17.85A449.26,449.26,0,
                                0,1,473.31,108.59ZM240.37,413.05a10,10,0,0,0-14.14,0L198,441.34a10,10,0,0,0,14.14,
                                14.14l28.28-28.29A10,10,0,0,0,240.37,413.05ZM99,271.63a10,10,0,0,0-14.14,0L56.52,
                                299.91a10,10,0,0,0,14.14,14.14L99,285.77A10,10,0,0,0,99,271.63ZM169.66,427.2a10,10,0,0,
                                0-14.14,0L87.78,494.93a10,10,0,1,0,14.14,14.14l67.74-67.73A10,10,0,0,0,169.66,
                                427.2Zm-80,0a10,10,0,0,0-14.14,0L7.78,494.93a10,10,0,0,0,14.14,14.14l67.74-67.73A10,10,
                                0,0,0,89.66,427.2ZM84.8,342.34a10,10,0,0,0-14.14,0L2.93,410.08a10,10,0,0,0,14.14,
                                14.14L84.8,356.48A10,10,0,0,0,84.8,342.34ZM311.08,200.92a10,10,0,0,0-14.14,0L282.8,
                                215.06a10,10,0,0,0,14.14,14.14l14.14-14.14A10,10,0,0,0,311.08,200.92Z"
                                    transform="translate(0 0)" /></svg>
                            Quick Start Guide
                        </div>
                    </a>
                </div>
                <div class="col-md-4 button-section">
                    <a href="https://ei.docs.wso2.com/en/next/ballerina-integrator/learn/about-learn/">
                        <div class="create">
                            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 612 612">
                                <path class="cls-1" d="M230.72,181.21l-5.12,5.51ZM337,200.88q11.94,14.69,11.91,
                                34.63A51.92,51.92,0,0,1,340.72,263a67.24,67.24,0,0,1-11.8,14.47l-16.3,16.1q-23.44,
                                23-30.35,40.87t-6.93,47h36.28q0-25.65,5.81-38.8t25.37-32.1q26.91-26.08,
                                35.75-39.53t8.87-35.06q0-35.62-24.14-58.58T299,154.42q-43.4,0-68.27,26.79T205.85,
                                252h36.28c.66-17.66,3.48-31.18,8.34-40.55q13-25.24,47.07-25.26Q325,186.19,337,
                                200.88ZM612,306C612,137,475,0,306,0S0,137,0,306,137,612,306,612,612,475,612,306ZM27.82,
                                306C27.82,152.36,152.36,27.82,306,27.82S584.18,152.36,584.18,306,459.64,584.18,306,
                                584.18,27.82,459.64,27.82,306ZM274.51,415.21h40.56v42.37H274.51Z" /></svg>
                            Tutorials
                        </div>
                    </a>
                </div>
            </div>
            <div class="row">
                <div class="col-md-6">
                    <h2 class="heading-page-two">Start using a template</h2>
                </div>
            </div>
            <div class="row">
                <div class="col-md-4 search">
                    <input class="u-full-width" type="input" placeholder="Search template" id="searchTemplate"
                        onKeyup="searchFunction()">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 450.9 451">
                        <path d="M447.05,428,337.45,318.4a191.52,191.52,0,0,0,47.2-126.1C384.65,86.2,298.35,0,
                        192.35,0S.05,86.3.05,192.3s86.3,192.3,192.3,192.3a191.52,191.52,0,0,0,126.1-47.2L428.05,
                        447a13.59,13.59,0,0,0,9.5,4,13.17,13.17,0,0,0,9.5-4A13.52,13.52,0,0,0,447.05,428ZM27,192.3C27,
                        101.1,101.15,27,192.25,27s165.3,74.2,165.3,165.3-74.1,165.4-165.3,165.4S27,283.5,27,192.3Z"
                            transform="translate(-0.05)" />
                    </svg>
                </div>
                <div class="col-md-4 custom-select">
                    <select id="templateCategory" onchange="searchFunction()">
                        <option value="#all">Search Category</option>
                        <option value="#connector">Connectors</option>
                        <option value="#eip">EI Patterns</option>
                        <option value="#messaging">Messaging</option>
                        <option value="#service">Services</option>
                    </select>
                </div>
            </div>
            <br />
            <div class="templates">`;

export let end: string = `
        </div>
    </body>
</html>`;
