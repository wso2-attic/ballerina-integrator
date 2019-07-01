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
 * Recursively copy folder from src to dest.
 * @param src Source folder.
 * @param dest Destination folder.
 */
export async function copyDir(src: string, dest: string) {

	// read contents of source directory
	const entries: string[] = fs.readdirSync(src);
	// synchronously create destination if it doesn't exist to ensure 
	// its existence before we copy individual items into it
	if (!fs.existsSync(dest)) {
		try {
			fs.mkdirSync(dest);
		} catch (err) {
			return Promise.reject(err);
		}
	} else if (!fs.lstatSync(dest).isDirectory()) {
		return Promise.reject(new Error("Unable to create directory '" + dest + "': already exists as file."));
	}

	let promises: Promise<boolean>[] = [];
	for (let entry of entries) {
		// full path of src/dest
		const srcPath = path.join(src, entry);
		const destPath = path.join(dest, entry);
		// if directory, recursively copy, otherwise copy file
		if (fs.lstatSync(srcPath).isDirectory()) {
			promises.push(copyDir(srcPath, destPath));
		} else {
			try {
				fs.copyFileSync(srcPath, destPath);
			} catch (err) {
				promises.push(Promise.reject(err));
			}
		}
	}

	await Promise.all(promises).then(
		(value: boolean[]) => {
			return value;
		},
		(reason: any) => {
			console.log(reason);
			return Promise.reject(reason);
		}
	);

	return Promise.resolve(true);
}

/**
 * Recursively make directories.
 * @param path Destination path.
 */
export function mkdirsSync(dest: string, mode: string | number | null | undefined = undefined): boolean {
	// check if exists
	if (fs.existsSync(dest)) {
		if (fs.lstatSync(dest).isDirectory()) {
			return true;
		} else {
			return false;
		}
	}
	// empty path, we failed
	if (!path) {
		return false;
	}
	// ensure existence of parent
	let parent = path.dirname(dest);
	if (!mkdirsSync(parent, mode)) {
		return false;
	}
	// make current directory
	fs.mkdirSync(dest, mode);
	return true;
}

/**
 * Converys a map into an object.
 * @param inputMap Input map that needs to be converted.
 */
export function mapToObj(inputMap) {
	let obj = {};
	inputMap.forEach(function (value, key) {
		obj[key] = value
	});
	return obj;
}
