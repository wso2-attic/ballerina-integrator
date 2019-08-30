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

package org.wso2.integration.ballerina.utils;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Objects;
import java.util.logging.Logger;

import static org.wso2.integration.ballerina.constants.Constants.BALLERINA_CODE_MD_SYNTAX;
import static org.wso2.integration.ballerina.constants.Constants.CODE;
import static org.wso2.integration.ballerina.constants.Constants.CODE_MD_SYNTAX;
import static org.wso2.integration.ballerina.constants.Constants.COMMIT_HASH;
import static org.wso2.integration.ballerina.constants.Constants.EMPTY_STRING;
import static org.wso2.integration.ballerina.constants.Constants.EQUAL;
import static org.wso2.integration.ballerina.constants.Constants.FORWARD_SLASH;
import static org.wso2.integration.ballerina.constants.Constants.FRONT_MATTER_SIGN;
import static org.wso2.integration.ballerina.constants.Constants.GIT_COMMIT_ID;
import static org.wso2.integration.ballerina.constants.Constants.HASH;
import static org.wso2.integration.ballerina.constants.Constants.JAVA_CODE_MD_SYNTAX;
import static org.wso2.integration.ballerina.constants.Constants.LICENCE_LAST_LINE;
import static org.wso2.integration.ballerina.constants.Constants.NEW_LINE;
import static org.wso2.integration.ballerina.constants.Constants.NOTE;
import static org.wso2.integration.ballerina.constants.Constants.README_MD;
import static org.wso2.integration.ballerina.constants.Constants.TEMP_DIR;
import static org.wso2.integration.ballerina.constants.Constants.TITLE;

/**
 * Util functions used for site builder.
 */
public class Utils {
    private static final Logger logger = Logger.getLogger(Utils.class.getName());

    private Utils() {}

    /**
     * Create a directory.
     *
     * @param directoryPath path of the directory
     */
    public static void createDirectory(String directoryPath) {
        if (!new File(directoryPath).exists()) {
            if (!new File(directoryPath).mkdir()) {
                throw new ServiceException("Error occurred when creating directory: " + directoryPath);
            }
        } else {
            logger.info("Directory already exists: " + directoryPath);
        }
    }

    /**
     * Delete a directory.
     *
     * @param directory path of the directory
     */
    public static void deleteDirectory(String directory) {
        try {
            FileUtils.deleteDirectory(new File(directory));
        } catch (IOException e) {
            throw new ServiceException("Error occurred while deleting temporary directory " + directory, e);
        }
    }

    /**
     * Copy directory content to another directory.
     *
     * @param src  path of the source directory
     * @param dest path of the destination directory
     */
    public static void copyDirectoryContent(String src, String dest) {
        try {
            FileUtils.copyDirectory(new File(src), new File(dest));
        } catch (IOException e) {
            throw new ServiceException("Error when copying directory content. src: " + src + ", dest: " + dest, e);
        }
    }

    /**
     * Get current directory name of a file.
     *
     * @param path file path
     * @return path of the current directory
     */
    public static String getCurrentDirectoryName(String path) {
        return path.substring(path.lastIndexOf(File.separator) + 1);
    }

    /**
     * Get file content as a string.
     *
     * @param file file which want to content as string
     * @return file content as a string
     */
    public static String getCodeFile(File file, String readMeParentPath) {
        try {
            if (file.exists()) {
                return IOUtils.toString(new FileInputStream(file), String.valueOf(StandardCharsets.UTF_8));
            } else {
                throw new ServiceException("Invalid file path in INCLUDE_CODE tag. Mentioned file does not exists in "
                        + "the project. Please mention the correct file path and try again.\n\tInclude file path\t:"
                        + file.getPath().replace(TEMP_DIR, "docs/") + "\n\tREADME file path\t:"
                        + readMeParentPath.replace(TEMP_DIR, "docs/") + FORWARD_SLASH + README_MD);
            }
        } catch (IOException e) {
            throw new ServiceException("Error occurred when converting file content to string. file: " + file.getPath(),
                    e);
        }
    }

    /**
     * Remove licence header of the code.
     *
     * @param code code file content
     * @return code without licence header
     */
    public static String removeLicenceHeader(String code) {
        if (code.contains(LICENCE_LAST_LINE)) {
            String[] temp = code.split(LICENCE_LAST_LINE);
            return temp[1].trim();
        } else {
            throw new ServiceException("Licence header is not in the correct format. code: " + code);
        }
    }

    /**
     * Get markdown code block with associated type of the code file.
     *
     * @param fullPathOfIncludeCodeFile code file path of the particular code block
     * @param code                      code content
     * @return code block in markdown format
     */
    public static String getMarkdownCodeBlockWithCodeType(String fullPathOfIncludeCodeFile, String code) {
        String type = fullPathOfIncludeCodeFile.substring(fullPathOfIncludeCodeFile.lastIndexOf('.') + 1);

        switch (type) {
        case "bal":
            return BALLERINA_CODE_MD_SYNTAX.replace(CODE, code);
        case "java":
            return JAVA_CODE_MD_SYNTAX.replace(CODE, code);
        default:
            return CODE_MD_SYNTAX.replace(CODE, code);
        }
    }

    /**
     * Add default front matter for posts.
     *
     * @param line heading line of the md file.
     * @return default front matter for posts
     */
    public static String getPostFrontMatter(String line, String versionID) {
        line = line.replace(HASH, EMPTY_STRING).trim();
        return FRONT_MATTER_SIGN + NEW_LINE
                + TITLE + line + NEW_LINE
                + COMMIT_HASH + versionID + NEW_LINE
                + NOTE + NEW_LINE
                + FRONT_MATTER_SIGN;
    }

    /**
     * Checks given directory is empty or not.
     *
     * @param directory directory want to check
     * @return is empty
     */
    public static boolean isDirEmpty(File directory) {
        return directory.isDirectory() && Objects.requireNonNull(directory.list()).length == 0;
    }

    /**
     * Get commit hash from `git.properties` file input stream.
     *
     * @param inputStream `git.properties` file input stream
     * @return commit hash
     */
    public static String getCommitHash(InputStream inputStream) {
        String commitHash = null;
        try (BufferedReader br = new BufferedReader(new InputStreamReader(inputStream))) {
            String line;
            while ((line = br.readLine()) != null) {
                if (line.contains(GIT_COMMIT_ID + EQUAL)) {
                    commitHash = line.replace(GIT_COMMIT_ID + EQUAL, EMPTY_STRING);
                }
            }
            return commitHash;
        } catch (IOException e) {
            throw new ServiceException("Error occurred when reading input stream.", e);
        }
    }
}
