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

import fs = require("fs");
import path = require("path");

/**
 * Recursively make directories.
 * @param dest Destination path.
 * @returns A Boolean value to represent the status.
 */
export function mkdirsSync(dest: string): boolean {
	// check if exists
	if (fs.existsSync(dest)) {
		return fs.lstatSync(dest).isDirectory();
	}
	// empty path, we failed
	if (!path) {
		return false;
	}
	// ensure existence of parent
	let parent = path.dirname(dest);
	if (!mkdirsSync(parent)) {
		return false;
	}
	// make current directory
	fs.mkdirSync(dest);
	return true;
}

/**
 * Converys a map into an object.
 * @param inputMap Input map that needs to be converted.
 */
export function mapToObj(inputMap) {
	let obj = {};
	inputMap.forEach(function (value, key) {
		obj[key] = value;
	});
	return obj;
}
