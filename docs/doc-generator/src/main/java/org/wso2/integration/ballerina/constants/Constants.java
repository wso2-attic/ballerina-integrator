/*
 *  Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.wso2.integration.ballerina.constants;

import java.io.File;
import java.nio.file.Paths;

/**
 * Constants used in site builder.
 */
public final class Constants {

    // Directory paths
    private static final String DOC_GEN_DIR_PATH = Paths.get("docs", "doc-generator").toString();
    public static final String DOCS_DIR = Paths.get(DOC_GEN_DIR_PATH, "..", "content","src").toString();
    private static final String TARGET_DIR = Paths.get(DOC_GEN_DIR_PATH,"target").toString();
    public static final String TEMP_DIR = TARGET_DIR + File.separator + "tempDirectory";
    public static final String MKDOCS_CONTENT = TARGET_DIR + File.separator + "mkdocs-content";
    private static final String ASSETS_DIR = DOCS_DIR + File.separator + "assets";
    public static final String ASSETS_IMG_DIR = ASSETS_DIR + File.separator + "img";
    public static final String SOURCE_WWW_DIR_PATH = Paths.get(DOC_GEN_DIR_PATH, "www").toString();
    public static final String WEBSITE_DIR = TARGET_DIR + File.separator + "www";
    public static final String TEMP_ASSETS_ZIP_DIR = TEMP_DIR + File.separator + "assets" + File.separator + "zip";

    // Files
    public static final String README_MD = "README.md";
    public static final String TEMP_DIR_MD = "tempDirectory.md";
    public static final String GIT_PROPERTIES_FILE = "git.properties";
    public static final String BALLERINA_TOML = "Ballerina.toml";

    // Special syntax
    public static final String INCLUDE_CODE_TAG = "INCLUDE_CODE:";
    public static final String INCLUDE_CODE_SEGMENT_TAG = "INCLUDE_CODE_SEGMENT:";
    public static final String INCLUDE_MD_TAG = "INCLUDE_MD:";
    public static final String EMPTY_STRING = "";
    public static final String COMMENT_START = "<!--";
    public static final String COMMENT_END = "-->";
    public static final String CODE = "{CODE}";
    public static final String NEW_LINE = "\n";
    private static final String THREE_BACK_TICKS = "```";
    public static final String FRONT_MATTER_SIGN = "---";
    public static final String LICENCE_LAST_LINE = "// under the License.";
    public static final String OPEN_CURLY_BRACKET = "{";
    public static final String CLOSE_CURLY_BRACKET = "}";
    public static final String CODE_SEGMENT_BEGIN = "// CODE-SEGMENT-BEGIN: ";
    public static final String CODE_SEGMENT_END = "// CODE-SEGMENT-END: ";
    public static final String CODE_MD_SYNTAX = THREE_BACK_TICKS + NEW_LINE + CODE + NEW_LINE + THREE_BACK_TICKS;
    public static final String FORWARD_SLASH = "/";
    public static final String COMMA = ",";
    public static final String HASH = "#";
    public static final String EQUAL = "=";
    public static final String MARKDOWN_FILE_EXT = "md";
    public static final String GIT_COMMIT_ID = "git.commit.id";
    public static final String COMMIT_HASH = "commitHash: ";
    public static final String TITLE = "title: ";
    public static final String NOTE = "note: This is an auto-generated file do not edit this, You can edit content in "
            + "\"ballerina-integrator\" repo";
    public static final String BALLERINA_CODE_MD_SYNTAX =
            THREE_BACK_TICKS + "ballerina" + NEW_LINE + CODE + NEW_LINE + THREE_BACK_TICKS;
    public static final String JAVA_CODE_MD_SYNTAX =
            THREE_BACK_TICKS + "java" + NEW_LINE + CODE + NEW_LINE + THREE_BACK_TICKS;

    private Constants() {}
}
