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

package org.wso2.integration.ballerina;

import org.apache.commons.io.IOUtils;
import org.wso2.integration.ballerina.utils.ServiceException;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.nio.charset.StandardCharsets;
import java.util.logging.Level;
import java.util.logging.Logger;

import static org.wso2.integration.ballerina.constants.Constants.CLOSE_CURLY_BRACKET;
import static org.wso2.integration.ballerina.constants.Constants.CODE_SEGMENT_BEGIN;
import static org.wso2.integration.ballerina.constants.Constants.CODE_SEGMENT_END;
import static org.wso2.integration.ballerina.constants.Constants.COMMENT_END;
import static org.wso2.integration.ballerina.constants.Constants.COMMENT_START;
import static org.wso2.integration.ballerina.constants.Constants.CONTENT_INTRO_DIR;
import static org.wso2.integration.ballerina.constants.Constants.EMPTY_STRING;
import static org.wso2.integration.ballerina.constants.Constants.FRONT_MATTER_IMG_VAR;
import static org.wso2.integration.ballerina.constants.Constants.FRONT_MATTER_SIGN;
import static org.wso2.integration.ballerina.constants.Constants.GUIDES_DIR;
import static org.wso2.integration.ballerina.constants.Constants.GUIDE_URL;
import static org.wso2.integration.ballerina.constants.Constants.IMG_GUIDES;
import static org.wso2.integration.ballerina.constants.Constants.INCLUDE_CODE_SEGMENT_TAG;
import static org.wso2.integration.ballerina.constants.Constants.INCLUDE_CODE_TAG;
import static org.wso2.integration.ballerina.constants.Constants.INDEX_MD;
import static org.wso2.integration.ballerina.constants.Constants.INTEGRATION_TUTORIALS_DIR;
import static org.wso2.integration.ballerina.constants.Constants.INTRO_DIR;
import static org.wso2.integration.ballerina.constants.Constants.INTRO_FRONT_MATTER_LAYOUT;
import static org.wso2.integration.ballerina.constants.Constants.INTRO_FRONT_MATTER_TYPE;
import static org.wso2.integration.ballerina.constants.Constants.INTRO_MD;
import static org.wso2.integration.ballerina.constants.Constants.FRONT_MATTER_GUIDE_VAR;
import static org.wso2.integration.ballerina.constants.Constants.NEW_LINE;
import static org.wso2.integration.ballerina.constants.Constants.OPEN_CURLY_BRACKET;
import static org.wso2.integration.ballerina.constants.Constants.README_MD;
import static org.wso2.integration.ballerina.constants.Constants.REPO_EXAMPLES_DIR;
import static org.wso2.integration.ballerina.constants.Constants.TEMP_DIR;
import static org.wso2.integration.ballerina.constants.Constants.GUIDE_TEMPLATES_DIR;
import static org.wso2.integration.ballerina.utils.Utils.copyDirectoryContent;
import static org.wso2.integration.ballerina.utils.Utils.createDirectory;
import static org.wso2.integration.ballerina.utils.Utils.deleteDirectory;
import static org.wso2.integration.ballerina.utils.Utils.deleteNonIndexFiles;
import static org.wso2.integration.ballerina.utils.Utils.getCodeFile;
import static org.wso2.integration.ballerina.utils.Utils.getCurrentDirectoryName;
import static org.wso2.integration.ballerina.utils.Utils.getMarkdownCodeBlockWithCodeType;
import static org.wso2.integration.ballerina.utils.Utils.getPostFrontMatter;
import static org.wso2.integration.ballerina.utils.Utils.removeLicenceHeader;
import static org.wso2.integration.ballerina.utils.Utils.renameAndMoveFile;

/**
 * Main class of the site creator project.
 */
public class SiteBuilder {
    // Setup logger.
    private static final Logger logger = Logger.getLogger(SiteBuilder.class.getName());

    public static void main(String[] args) {
        try {
            // First delete already created posts.
            deleteDirectory(GUIDES_DIR);
            deleteDirectory(INTEGRATION_TUTORIALS_DIR);
            deleteNonIndexFiles(new File(INTRO_DIR));
            // Create needed directory structure.
            createDirectory(TEMP_DIR);
            createDirectory(GUIDE_TEMPLATES_DIR);
            // get a copy of examples directory.
            copyDirectoryContent(REPO_EXAMPLES_DIR, TEMP_DIR);
            // Process repository to generate guide templates.
            processDirectory(TEMP_DIR);
            // Copy tempDirectory content to hugo content directory.
            copyDirectoryContent(TEMP_DIR, GUIDE_TEMPLATES_DIR);
        } catch (ServiceException e) {
            logger.log(Level.SEVERE, e.getMessage(), e);
        } finally {
            deleteDirectory(TEMP_DIR);
        }
    }

    /**
     * Process files inside given directory.
     *
     * @param directoryPath path of the directory
     */
    private static void processDirectory(String directoryPath) {
        File folder = new File(directoryPath);
        File[] listOfFiles = folder.listFiles();

        if (listOfFiles != null) {
            for (File file : listOfFiles) {
                if (file.isFile() && (file.getName().equals(README_MD))) {
                    processReadmeFile(file);
                    renameReadmeFile(file);
                } else if (file.getName().equals(INDEX_MD)) {
                    processReadmeFile(file);
                } else if (file.getName().equals(INTRO_MD)) {
                    processReadmeFile(file);
                    renameAndMoveFile(file, CONTENT_INTRO_DIR, getCurrentDirectoryName(file.getParent()));
                } else if (file.isDirectory()) {
                    processDirectory(file.getPath());

                }
            }
        }
    }

    /**
     * Process a given README.md by reading through lines.
     *
     * @param file README.md file
     */
    private static void processReadmeFile(File file) {
        try {
            String readMeFileContent = IOUtils
                    .toString(new FileInputStream(file), String.valueOf(StandardCharsets.UTF_8));
            BufferedReader reader = new BufferedReader(new FileReader(file));
            String line;
            int lineNumber = 0;

            while ((line = reader.readLine()) != null) {
                lineNumber++;
                if (line.contains(INCLUDE_CODE_TAG)) {
                    // Replace INCLUDE_CODE line with include code file.
                    readMeFileContent = readMeFileContent.replace(line, getIncludeCodeFile(file.getParent(), line));
                } else if (line.contains(INCLUDE_CODE_SEGMENT_TAG)) {
                    // Replace INCLUDE_CODE_SEGMENT line with include code segment.
                    readMeFileContent = readMeFileContent.replace(line, getIncludeCodeSegment(file.getParent(), line));
                } else if (lineNumber == 1 && line.contains("#")) {
                    // Adding front matter to posts.
                    readMeFileContent = readMeFileContent.replace(line, getPostFrontMatter(line));
                }
            }

            // Edit front matter if _intro.md
            if (file.getName().equals(INTRO_MD)) {
                String frontMatterContent = readMeFileContent.split(FRONT_MATTER_SIGN)[1].split(FRONT_MATTER_SIGN)[0];

                // image variable
                String relativeImageUrl = frontMatterContent.split(FRONT_MATTER_IMG_VAR)[1].split("\"")[0];
                String parentGitImgUrl = IMG_GUIDES + file.getParent().split(TEMP_DIR)[1];
                // remove img variable already there.
                String newFrontMatterContent = frontMatterContent
                        .replace(relativeImageUrl, parentGitImgUrl + "/" + relativeImageUrl);

                // guide variable
                String guide = FRONT_MATTER_GUIDE_VAR.replace(GUIDE_URL, getGuideUrl(file));

                readMeFileContent = readMeFileContent.replace(frontMatterContent,
                        newFrontMatterContent + INTRO_FRONT_MATTER_TYPE + NEW_LINE
                                + INTRO_FRONT_MATTER_LAYOUT + NEW_LINE + guide + NEW_LINE);
            }

            IOUtils.write(readMeFileContent, new FileOutputStream(file), String.valueOf(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new ServiceException("Could not find the README.md file: " + file.getPath(), e);
        }

    }

    /**
     * Rename README.md file as parent_directory_name.md
     *
     * @param file README.md file
     */
    private static void renameReadmeFile(File file) {
        if (file.getName().equals(README_MD)) {
            String mdFileName = file.getParent() + "/" + getCurrentDirectoryName(file.getParent()) + ".md";
            if (!file.renameTo(new File(mdFileName))) {
                throw new ServiceException("Renaming README.md failed. file:" + file.getPath());
            }
        }
    }

    /**
     * Get code file content should be included in the README.md file.
     *
     * @param readMeParentPath parent path of the README.md file
     * @param line             line having INCLUDE_CODE_TAG
     * @return code content of the code file should be included
     */
    private static String getIncludeCodeFile(String readMeParentPath, String line) {
        String fullPathOfIncludeCodeFile = readMeParentPath + getIncludeFilePathFromIncludeCodeLine(line);
        File includeCodeFile = new File(fullPathOfIncludeCodeFile);
        String code = removeLicenceHeader(getCodeFile(includeCodeFile)).trim();
        return getMarkdownCodeBlockWithCodeType(fullPathOfIncludeCodeFile, code);
    }

    /**
     * Get code segment should be included in the README.md file.
     *
     * @param readMeParentPath parent path of the README.md file
     * @param line             line having INCLUDE_CODE_SEGMENT_TAG
     * @return code segment content should be included
     */
    private static String getIncludeCodeSegment(String readMeParentPath, String line) {
        String includeLineData = line.replace(COMMENT_START, EMPTY_STRING).replace(COMMENT_END, EMPTY_STRING)
                .replace(INCLUDE_CODE_SEGMENT_TAG, EMPTY_STRING)
                .trim(); // { file: guide/http_message_receiver.bal, segment: segment_1 }

        String[] tempDataArr = includeLineData.replace(OPEN_CURLY_BRACKET, EMPTY_STRING)
                .replace(CLOSE_CURLY_BRACKET, EMPTY_STRING).split(",");

        String fullPathOfIncludeCodeFile =
                readMeParentPath + "/" + tempDataArr[0].replace("file:", EMPTY_STRING).trim();
        String segment = tempDataArr[1].replace("segment:", EMPTY_STRING).trim();

        File includeCodeFile = new File(fullPathOfIncludeCodeFile);
        String codeFileContent = removeLicenceHeader(getCodeFile(includeCodeFile));

        String code = getCodeSegment(codeFileContent, segment).trim();
        return getMarkdownCodeBlockWithCodeType(fullPathOfIncludeCodeFile, code);
    }

    /**
     * Get code segment form code file content.
     *
     * @param codeFileContent code file content
     * @param segmentName     segment name used in the code file (eg: segment_1)
     * @return code segment as a string
     */
    private static String getCodeSegment(String codeFileContent, String segmentName) {
        try {
            return codeFileContent.split(CODE_SEGMENT_BEGIN + segmentName)[1].split(CODE_SEGMENT_END + segmentName)[0];
        } catch (ArrayIndexOutOfBoundsException e) {
            throw new ServiceException("Invalid code segment including. segmentName: " + segmentName);
        }
    }

    /**
     * get file path of the INCLUDE_CODE_TAG line.
     *
     * @param line line having INCLUDE_CODE_TAG
     * @return file path of the code file should be included
     */
    private static String getIncludeFilePathFromIncludeCodeLine(String line) {
        return "/" + line.replace(COMMENT_START, EMPTY_STRING).replace(COMMENT_END, EMPTY_STRING)
                .replace(INCLUDE_CODE_TAG, EMPTY_STRING).trim();
    }

    /**
     * Get guide url to include in the intro templates.
     *
     * @param file template markdown file
     * @return particular guide url of the intro template
     */
    private static String getGuideUrl(File file) {
        return "../../" + file.getParent().replace(TEMP_DIR, EMPTY_STRING);
    }
}
