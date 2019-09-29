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

import net.lingala.zip4j.ZipFile;
import net.lingala.zip4j.exception.ZipException;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.wso2.integration.ballerina.utils.ServiceException;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

import static org.wso2.integration.ballerina.constants.Constants.ASSETS_IMG_DIR;
import static org.wso2.integration.ballerina.constants.Constants.BALLERINA_TOML;
import static org.wso2.integration.ballerina.constants.Constants.CLOSE_CURLY_BRACKET;
import static org.wso2.integration.ballerina.constants.Constants.CODE_SEGMENT_BEGIN;
import static org.wso2.integration.ballerina.constants.Constants.CODE_SEGMENT_END;
import static org.wso2.integration.ballerina.constants.Constants.COMMA;
import static org.wso2.integration.ballerina.constants.Constants.COMMENT_END;
import static org.wso2.integration.ballerina.constants.Constants.COMMENT_START;
import static org.wso2.integration.ballerina.constants.Constants.DOCS_DIR;
import static org.wso2.integration.ballerina.constants.Constants.EMPTY_STRING;
import static org.wso2.integration.ballerina.constants.Constants.GIT_PROPERTIES_FILE;
import static org.wso2.integration.ballerina.constants.Constants.HASH;
import static org.wso2.integration.ballerina.constants.Constants.INCLUDE_CODE_SEGMENT_TAG;
import static org.wso2.integration.ballerina.constants.Constants.INCLUDE_CODE_TAG;
import static org.wso2.integration.ballerina.constants.Constants.MARKDOWN_FILE_EXT;
import static org.wso2.integration.ballerina.constants.Constants.MKDOCS_CONTENT;
import static org.wso2.integration.ballerina.constants.Constants.NEW_LINE;
import static org.wso2.integration.ballerina.constants.Constants.OPEN_CURLY_BRACKET;
import static org.wso2.integration.ballerina.constants.Constants.README_MD;
import static org.wso2.integration.ballerina.constants.Constants.TEMP_DIR;
import static org.wso2.integration.ballerina.constants.Constants.TEMP_DIR_MD;
import static org.wso2.integration.ballerina.utils.Utils.copyDirectoryContent;
import static org.wso2.integration.ballerina.utils.Utils.createDirectory;
import static org.wso2.integration.ballerina.utils.Utils.createFile;
import static org.wso2.integration.ballerina.utils.Utils.deleteDirectory;
import static org.wso2.integration.ballerina.utils.Utils.deleteFile;
import static org.wso2.integration.ballerina.utils.Utils.getCodeFile;
import static org.wso2.integration.ballerina.utils.Utils.getCommitHash;
import static org.wso2.integration.ballerina.utils.Utils.getCurrentDirectoryName;
import static org.wso2.integration.ballerina.utils.Utils.getLeadingWhitespaces;
import static org.wso2.integration.ballerina.utils.Utils.getMarkdownCodeBlockWithCodeType;
import static org.wso2.integration.ballerina.utils.Utils.getPostFrontMatter;
import static org.wso2.integration.ballerina.utils.Utils.getZipFileName;
import static org.wso2.integration.ballerina.utils.Utils.isDirEmpty;
import static org.wso2.integration.ballerina.utils.Utils.removeLicenceHeader;

/**
 * Main class of the site creator project.
 */
public class DocsGenerator {
    // Setup logger.
    private static final Logger logger = LoggerFactory.getLogger(DocsGenerator.class);

    // Current commit hash.
    private static String commitHash = null;

    public static void main(String[] args) {
        try {
            DocsGenerator docsGenerator = new DocsGenerator();
            // Get current commit hash.
            commitHash = docsGenerator.getCommitHashByReadingGitProperties();
            // First delete already created mkdocs-content directory.
            deleteDirectory(MKDOCS_CONTENT);
            // Create needed directory structure.
            createDirectory(TEMP_DIR);
            createFile(TEMP_DIR + File.separator + "temp.txt");
            createDirectory(MKDOCS_CONTENT);
            // Get a copy of examples directory.
            copyDirectoryContent(DOCS_DIR, TEMP_DIR);
            // Process repository to generate guide templates.
            processDirectory(TEMP_DIR);
            // Zip Ballerina projects.
            zipBallerinaProjects(TEMP_DIR);
            // Delete non markdown files.
            deleteUnwantedFiles(TEMP_DIR);
            // Delete empty directories.
            deleteEmptyDirs(TEMP_DIR);
            // Copy tempDirectory content to mkdocs content directory.
            copyDirectoryContent(TEMP_DIR, MKDOCS_CONTENT);
        } catch (ServiceException e) {
            logger.error(e.getMessage(), e);
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
        // Delete doc-generator directory.
        deleteDirectory(TEMP_DIR + File.separator + "doc-generator");

        File folder = new File(directoryPath);
        File[] listOfFiles = folder.listFiles();

        if (listOfFiles != null) {
            for (File file : listOfFiles) {
                String fileExtension = FilenameUtils.getExtension(file.getName());
                if (file.isFile()) {
                    if ((file.getName().equals(README_MD))) {
                        processReadmeFile(file);
                        renameReadmeFile(file);
                    } else if ((fileExtension.equals("bal") || fileExtension.equals("java"))
                            && !processCodeFile(file)) {
                        throw new ServiceException("Processing code file failed, file:" + file.getPath());
                    }
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
        return handleCodeAlignment(line, getMarkdownCodeBlockWithCodeType(fullPathOfIncludeCodeFile, code));
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
        return handleCodeAlignment(line, getMarkdownCodeBlockWithCodeType(fullPathOfIncludeCodeFile, code));
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
     * Handle alignment of the code inclusion. Leading whitespaces of the INCLUDE_CODE_TAG line should be added
     * to the beginning of each code line.
     * <WHITESPACES>INCLUDE_CODE_TAG => <WHITESPACES>{code}
     *
     * @param line INCLUDE_CODE_TAG line
     * @param code code content as a string
     * @return aligned code
     */
    private static String handleCodeAlignment(String line, String code) {
        String leadingSpaces = getLeadingWhitespaces(line);
        return leadingSpaces + code.replace(NEW_LINE, NEW_LINE + leadingSpaces);
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
     * Delete unwanted files other than `md` files & `zip` files. Also delete `Module.md` files.
     *
     * @param directoryPath directory want to delete files
     */
    private static void deleteUnwantedFiles(String directoryPath) {
        File folder = new File(directoryPath);
        File[] listOfFiles = folder.listFiles();

        if (listOfFiles != null) {
            for (File file : listOfFiles) {
                if (file.isFile()) {
                    if (isUnwanted(file)) {
                        deleteFile(file);
                    }
                } else if (file.isDirectory()) {
                    deleteUnwantedFiles(file.getPath());
                }
            }
        }
    }

    /**
     * Check whether should be included in `mkdocs-content` folder.
     * All md files other than Module.md files & all zip files are needed.
     *
     * @param file file
     * @return is a unwanted file
     */
    private static boolean isUnwanted(File file) {
        boolean mdFile = FilenameUtils.getExtension(file.getName()).equals(MARKDOWN_FILE_EXT);
        boolean moduleMdFile = file.getName().equals("Module.md");
        boolean zipFile = FilenameUtils.getExtension(file.getName()).equals("zip");
        boolean imgFile = new File(ASSETS_IMG_DIR, file.getName()).exists();

        return !((mdFile && !moduleMdFile) || zipFile || imgFile);
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
        if (file != null && isDirEmpty(file)) {
            try {
                Files.delete(Paths.get(file.getPath()));
                deleteEmptyDirsAndParentDirs(file.getParentFile());
            } catch (IOException e) {
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

    /**
     * Process files inside given directory.
     *
     * @param directoryPath path of the directory
     */
    private static void zipBallerinaProjects(String directoryPath) {
        File folder = new File(directoryPath);
        File[] listOfFiles = folder.listFiles();

        if (listOfFiles != null) {
            for (File file : listOfFiles) {
                if (file.isFile() && (file.getName().equals(BALLERINA_TOML))) {
                    // Zip parent folder since this is a Ballerina project.
                    try {
                        new ZipFile(getZipFileName(file)).addFolder(new File(file.getParentFile().getPath()));
                    } catch (ZipException e) {
                        throw new ServiceException("Error when zipping the directory: "
                                + file.getParentFile().getPath(), e);
                    }
                } else if (file.isDirectory()) {
                    zipBallerinaProjects(file.getPath());
                }
            }
        }
    }

    /**
     * Process a given code file by removing `CODE-SEGMENT` tags.
     *
     * @param file code file
     * @return processing result
     */
    private static boolean processCodeFile(File file) {
        File tempFile = new File(TEMP_DIR + File.separator + "temp.txt");

        try (BufferedWriter writer = new BufferedWriter(new FileWriter(tempFile))) {
            ignoreCodeSegmentLine(file, writer);
        } catch (IOException e) {
            throw new ServiceException("Could not find the writer temp file: " + tempFile.getPath(), e);
        }
        return tempFile.renameTo(file);
    }

    /**
     * Ignore code segment comment lines.
     *
     * @param file   code file
     * @param writer temp file to keep code content without CODE_SEGMENT comment line.
     */
    private static void ignoreCodeSegmentLine(File file, BufferedWriter writer) {
        try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
            String line;

            while ((line = reader.readLine()) != null) {
                if (line.contains(CODE_SEGMENT_BEGIN) || line.contains(CODE_SEGMENT_END)) {
                    // Ignore CODE_SEGMENT line.
                    continue;
                }
                writer.write(line + System.getProperty("line.separator"));
            }
        } catch (IOException e) {
            throw new ServiceException("Could not find the README.md file: " + file.getPath(), e);
        }
    }
}
