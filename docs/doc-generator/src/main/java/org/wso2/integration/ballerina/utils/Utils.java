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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Objects;

import static org.wso2.integration.ballerina.Constants.BALLERINA_CODE_MD_SYNTAX;
import static org.wso2.integration.ballerina.Constants.CODE;
import static org.wso2.integration.ballerina.Constants.CODE_MD_SYNTAX;
import static org.wso2.integration.ballerina.Constants.COMMIT_HASH;
import static org.wso2.integration.ballerina.Constants.EMPTY_STRING;
import static org.wso2.integration.ballerina.Constants.EQUAL;
import static org.wso2.integration.ballerina.Constants.FORWARD_SLASH;
import static org.wso2.integration.ballerina.Constants.FRONT_MATTER_SIGN;
import static org.wso2.integration.ballerina.Constants.GIT_COMMIT_ID;
import static org.wso2.integration.ballerina.Constants.HASH;
import static org.wso2.integration.ballerina.Constants.JAVA_CODE_MD_SYNTAX;
import static org.wso2.integration.ballerina.Constants.LICENCE_LAST_LINE;
import static org.wso2.integration.ballerina.Constants.NEW_LINE;
import static org.wso2.integration.ballerina.Constants.NOTE;
import static org.wso2.integration.ballerina.Constants.README_MD;
import static org.wso2.integration.ballerina.Constants.TITLE;

/**
 * Util functions used for site builder.
 */
public class Utils {
    private static final Logger logger = LoggerFactory.getLogger(Utils.class);
    private Utils() {}

    /**
     * Create a directory.
     *
     * @param directoryPath path of the directory
     */
    public static void createDirectory(String directoryPath) {
        File file = new File(directoryPath);
        if (!file.exists()) {
            if (!file.mkdir()) {
                throw new ServiceException("Error occurred when creating directory: " + directoryPath);
            }
        } else {
            if (logger.isInfoEnabled()) {
                logger.info("Directory already exists: {}", directoryPath);
            }
        }
    }

    /**
     * Create a file.
     *
     * @param filePath path of the file
     */
    public static void createFile(String filePath) {
        File file = new File(filePath);
        if (!file.exists()) {
            try {
                if (!file.createNewFile()) {
                    throw new ServiceException("Could not create the file: " + filePath);
                }
            } catch (IOException e) {
                throw new ServiceException("Error when creating the file: " + filePath, e);
            }
        } else {
            if (logger.isInfoEnabled()) {
                logger.info("File already exists: {}", filePath);
            }
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
     * Delete a file.
     *
     * @param file file should be deleted
     */
    public static void deleteFile(File file) {
        try {
            Files.delete(Paths.get(file.getPath()));
        } catch (IOException e) {
            throw new ServiceException("Error occurred when deleting file. file:" + file.getPath(), e);
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
     * Get file content as a string.
     *
     * @param file file which want to content as string
     * @return file content as a string
     */
    public static String getCodeFile(File file, String readMeParentPath, String tempDir) {
        try {
            if (file.exists()) {
                return IOUtils.toString(new FileInputStream(file), String.valueOf(StandardCharsets.UTF_8));
            } else {
                throw new ServiceException("Invalid file path in INCLUDE_CODE tag. Mentioned file does not exists in "
                        + "the project. Please mention the correct file path and try again.\n\tInclude file path\t:"
                        + file.getPath() + "\n\tREADME file path\t:" + readMeParentPath + FORWARD_SLASH + README_MD);
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
     * @param file code file
     * @return code without licence header
     */
    public static String removeLicenceHeader(String code, String file) {
        if (code.contains(LICENCE_LAST_LINE)) {
            String[] temp = code.split(LICENCE_LAST_LINE);
            return temp[1].trim();
        } else {
            throw new ServiceException("Licence header is not in the correct format.\nGuide\t: " + file + "\nCode\t:\n"
                    + code);
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

    /**
     * Remove leading whitespaces of a given string.
     *
     * @param param string want to remove leading whitespaces
     * @return string without leading whitespaces
     */
    private static String removeLeadingSpaces(String param) {
        return param.replaceAll("^\\s+", EMPTY_STRING);
    }

    /**
     * Get leading whitespaces of a given string.
     *
     * @param param string want to get leading whitespaces
     * @return leading whitespaces of the string
     */
    public static String getLeadingWhitespaces(String param) {
        return param.replace(removeLeadingSpaces(param), EMPTY_STRING);
    }

    /**
     * Get zip file name using the toml file path.
     *
     * @param tomlFile toml file
     * @return zip file name
     */
    public static String getZipFileName(String tempDir, File tomlFile) {
        return Paths.get(tempDir, "assets", "zip", tomlFile.getParentFile().getName()) + ".zip";
    }

    /**
     * Check whether given string has a image attachment syntax.
     *
     * @param line line
     * @return is image attachment line
     */
    public static boolean isImageAttachmentLine(String line) {
        try {
            return line.trim().substring(0, 2).equals("![") && line.contains("assets/img");
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Get string between two strings of a given string.
     *
     * @param original original string
     * @param subStr1  substring one
     * @param subStr2  substring two
     * @return string between substring one and substring two of string original
     */
    public static String getStringBetweenTwoStrings(String original, String subStr1, String subStr2) {
        original = original.substring(original.indexOf(subStr1) + subStr1.length());
        original = original.substring(0, original.indexOf(subStr2));
        return original;
    }

    /**
     * Add previous directory syntax `../` for a given string.
     *
     * @param path        directory path
     * @param occurrences no of occurrences want to add `../`
     * @return directory path after adding `../` occurrences.
     */
    public static String addPrevDirectorySyntax(String path, int occurrences) {
        StringBuilder pathBuilder = new StringBuilder(path);
        for (int i = 0; i < occurrences; i++) {
            pathBuilder.insert(0, "../");
        }
        return pathBuilder.toString();
    }
}
