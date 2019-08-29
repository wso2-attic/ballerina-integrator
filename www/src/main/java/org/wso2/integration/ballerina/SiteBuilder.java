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

package org.wso2.integration.ballerina;

import org.apache.commons.io.FilenameUtils;
import org.apache.commons.io.IOUtils;
import org.wso2.integration.ballerina.utils.ServiceException;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.logging.Level;
import java.util.logging.Logger;

import static org.wso2.integration.ballerina.constants.Constants.CLOSE_CURLY_BRACKET;
import static org.wso2.integration.ballerina.constants.Constants.CODE_SEGMENT_BEGIN;
import static org.wso2.integration.ballerina.constants.Constants.CODE_SEGMENT_END;
import static org.wso2.integration.ballerina.constants.Constants.COMMA;
import static org.wso2.integration.ballerina.constants.Constants.COMMENT_END;
import static org.wso2.integration.ballerina.constants.Constants.COMMENT_START;
import static org.wso2.integration.ballerina.constants.Constants.EMPTY_STRING;
import static org.wso2.integration.ballerina.constants.Constants.GIT_PROPERTIES_FILE;
import static org.wso2.integration.ballerina.constants.Constants.HASH;
import static org.wso2.integration.ballerina.constants.Constants.INCLUDE_CODE_SEGMENT_TAG;
import static org.wso2.integration.ballerina.constants.Constants.INCLUDE_CODE_TAG;
import static org.wso2.integration.ballerina.constants.Constants.MARKDOWN_FILE_EXT;
import static org.wso2.integration.ballerina.constants.Constants.MKDOCS_CONTENT;
import static org.wso2.integration.ballerina.constants.Constants.OPEN_CURLY_BRACKET;
import static org.wso2.integration.ballerina.constants.Constants.README_MD;
import static org.wso2.integration.ballerina.constants.Constants.REPO_EXAMPLES_DIR;
import static org.wso2.integration.ballerina.constants.Constants.TEMP_DIR;
import static org.wso2.integration.ballerina.constants.Constants.TEMP_DIR_MD;
import static org.wso2.integration.ballerina.utils.Utils.copyDirectoryContent;
import static org.wso2.integration.ballerina.utils.Utils.createDirectory;
import static org.wso2.integration.ballerina.utils.Utils.deleteDirectory;
import static org.wso2.integration.ballerina.utils.Utils.getCodeFile;
import static org.wso2.integration.ballerina.utils.Utils.getCommitHash;
import static org.wso2.integration.ballerina.utils.Utils.getCurrentDirectoryName;
import static org.wso2.integration.ballerina.utils.Utils.getMarkdownCodeBlockWithCodeType;
import static org.wso2.integration.ballerina.utils.Utils.getPostFrontMatter;
import static org.wso2.integration.ballerina.utils.Utils.isDirEmpty;
import static org.wso2.integration.ballerina.utils.Utils.removeLicenceHeader;

/**
 * Main class of the site creator project.
 */
public class SiteBuilder {
    // Setup logger.
    private static final Logger logger = Logger.getLogger(SiteBuilder.class.getName());
    // Current commit hash.
    private static String commitHash = null;

    public static void main(String[] args) {
        try {
            SiteBuilder siteBuilder = new SiteBuilder();
            // Get current commit hash.
            commitHash = siteBuilder.getCommitHashByReadingGitProperties();
            // First delete already created mkdocs-content directory.
            deleteDirectory(MKDOCS_CONTENT);
            // Create needed directory structure.
            createDirectory(TEMP_DIR);
            createDirectory(MKDOCS_CONTENT);
            // Get a copy of examples directory.
            copyDirectoryContent(REPO_EXAMPLES_DIR, TEMP_DIR);
            // Process repository to generate guide templates.
            processDirectory(TEMP_DIR);
            // Delete non markdown files.
            deleteNonMdFiles(TEMP_DIR);
            // Delete empty directories.
            deleteEmptyDirs(TEMP_DIR);
            // Copy tempDirectory content to mkdocs content directory.
            copyDirectoryContent(TEMP_DIR, MKDOCS_CONTENT);
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
        try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
            String readMeFileContent = IOUtils
                    .toString(new FileInputStream(file), String.valueOf(StandardCharsets.UTF_8));

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
                } else if (lineNumber == 1 && line.contains(HASH)) {
                    // Adding front matter to posts.
                    readMeFileContent = readMeFileContent.replace(line, getPostFrontMatter(line, commitHash));
                }
            }
            IOUtils.write(readMeFileContent, new FileOutputStream(file), String.valueOf(StandardCharsets.UTF_8));
        } catch (IOException e) {
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
            String mdFileName = file.getParent() + File.separator + getCurrentDirectoryName(file.getParent()) + ".md";
            // If directory name is "tempDirectory", not renaming the file.
            if (!mdFileName.contains(TEMP_DIR_MD) && !file.renameTo(new File(mdFileName))) {
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
        String code = removeLicenceHeader(getCodeFile(includeCodeFile, readMeParentPath)).trim();
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
                .trim();

        String[] tempDataArr = includeLineData.replace(OPEN_CURLY_BRACKET, EMPTY_STRING)
                .replace(CLOSE_CURLY_BRACKET, EMPTY_STRING).split(COMMA);

        String fullPathOfIncludeCodeFile =
                readMeParentPath + File.separator + tempDataArr[0].replace("file:", EMPTY_STRING).trim();
        String segment = tempDataArr[1].replace("segment:", EMPTY_STRING).trim();

        File includeCodeFile = new File(fullPathOfIncludeCodeFile);
        String codeFileContent = removeLicenceHeader(getCodeFile(includeCodeFile, readMeParentPath));

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
     * Delete file other than .md files.
     *
     * @param directoryPath directory want to delete files
     */
    private static void deleteNonMdFiles(String directoryPath) {
        File folder = new File(directoryPath);
        File[] listOfFiles = folder.listFiles();

        if (listOfFiles != null) {
            for (File file : listOfFiles) {
                if (file.isFile()) {
                    // Delete not .md files.
                    if (!FilenameUtils.getExtension(file.getName()).equals(MARKDOWN_FILE_EXT) && !file.delete()) {
                        throw new ServiceException("Error occurred when deleting file. file:" + file.getPath());
                    }
                } else if (file.isDirectory()) {
                    deleteNonMdFiles(file.getPath());
                }
            }
        }
    }

    /**
     * Delete empty directories.
     *
     * @param directoryPath directory want to delete empty directories
     */
    private static void deleteEmptyDirs(String directoryPath) {
        File folder = new File(directoryPath);
        File[] listOfFiles = folder.listFiles();

        if (listOfFiles != null) {
            for (File file : listOfFiles) {
                if (file.isDirectory()) {
                    deleteEmptyDirsAndParentDirs(file);
                    deleteEmptyDirs(file.getPath());
                }
            }
        }
    }

    /**
     * Delete empty directories and check whether parent directory is empty. If it is empty delete parent directory and
     * continue recursively.
     *
     * @param file file should be deleted
     */
    private static void deleteEmptyDirsAndParentDirs(File file) {
        if (isDirEmpty(file)) {
            boolean isFileDeleted = file.delete();
            if (isFileDeleted) {
                File parent = file.getParentFile();
                deleteEmptyDirsAndParentDirs(parent);
            } else {
                throw new ServiceException("Error occurred when deleting directory. file:" + file.getPath());
            }
        }
    }

    /**
     * Get current commit hash by reading `git.properties` file.
     * `git.properties` file generated by `git-commit-id-plugin` maven plugin.
     *
     * @return current git commit hash
     */
    private String getCommitHashByReadingGitProperties() {
        ClassLoader classLoader = getClass().getClassLoader();
        InputStream inputStream = classLoader.getResourceAsStream(GIT_PROPERTIES_FILE);
        if (inputStream != null) {
            try {
                String gitCommitHash = getCommitHash(inputStream);
                if (gitCommitHash == null) {
                    throw new ServiceException("git commit id is null.");
                }
                return gitCommitHash;
            } catch (ServiceException e) {
                throw new ServiceException("Version information could not be retrieved", e);
            }
        } else {
            throw new ServiceException("Error when reading " + GIT_PROPERTIES_FILE);
        }
    }
}
