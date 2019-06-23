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

package org.wso2.integration.ballerina.constants;

import java.io.File;

/**
 * Constants used in site builder.
 */
public final class Constants {

    // Directory paths
    public static final String REPO_EXAMPLES_DIR = ".." + File.separator + "examples";
    public static final String TEMP_DIR = "tempDirectory/";
    public static final String GUIDE_TEMPLATES_DIR = "hugo-www/content/";
    public static final String GUIDES_DIR = GUIDE_TEMPLATES_DIR + "guides";
    public static final String INTEGRATION_TUTORIALS_DIR = GUIDE_TEMPLATES_DIR + "integration-tutorials";
    public static final String INTRO_DIR = GUIDE_TEMPLATES_DIR + "intro";
    public static final String CONTENT_INTRO_DIR = "hugo-www/content/intro/";

    // Files
    public static final String README_MD = "README.md";
    public static final String INDEX_MD = "_index.md";
    public static final String INTRO_MD = "_intro.md";

    // Special syntax
    public static final String INCLUDE_CODE_TAG = "INCLUDE_CODE:";
    public static final String INCLUDE_CODE_SEGMENT_TAG = "INCLUDE_CODE_SEGMENT:";
    public static final String EMPTY_STRING = "";
    public static final String COMMENT_START = "<!--";
    public static final String COMMENT_END = "-->";
    public static final String CODE = "{CODE}";
    public static final String NEW_LINE = "\n";
    private static final String THREE_BACK_TICKS = "```";
    public static final String LICENCE_LAST_LINE = "// under the License.";
    public static final String OPEN_CURLY_BRACKET = "{";
    public static final String CLOSE_CURLY_BRACKET = "}";
    public static final String CODE_SEGMENT_BEGIN = "// CODE-SEGMENT-BEGIN: ";
    public static final String CODE_SEGMENT_END = "// CODE-SEGMENT-END: ";
    public static final String FRONT_MATTER_SIGN = "---";
    public static final String FRONT_MATTER_GUIDE_VAR = "guide: \"{GUIDE_URL}\"";
    public static final String GUIDE_URL = "{GUIDE_URL}";
    public static final String FRONT_MATTER_IMG_VAR = "image: \"";
    public static final String INTRO_FRONT_MATTER_TYPE = "type: \"page\"";
    public static final String INTRO_FRONT_MATTER_LAYOUT = "layout: \"template-static\"";
    public static final String CODE_MD_SYNTAX = THREE_BACK_TICKS + NEW_LINE + CODE + NEW_LINE + THREE_BACK_TICKS;
    public static final String BALLERINA_CODE_MD_SYNTAX =
            THREE_BACK_TICKS + "ballerina" + NEW_LINE + CODE + NEW_LINE + THREE_BACK_TICKS;
    public static final String JAVA_CODE_MD_SYNTAX =
            THREE_BACK_TICKS + "java" + NEW_LINE + CODE + NEW_LINE + THREE_BACK_TICKS;

    // Git image path
    private static final String ORG_NAME = "wso2";
    private static final String REPO_NAME = "ballerina-integrator";
    private static final String BRANCH_NAME = "master";
    public static final String IMG_GUIDES =
            "https://raw.githubusercontent.com/" + ORG_NAME + "/" + REPO_NAME + "/" + BRANCH_NAME + "/examples/";

    private Constants() {}
}
