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
import org.apache.log4j.BasicConfigurator;
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

import static org.wso2.integration.ballerina.Constants.BALLERINA_TOML;
import static org.wso2.integration.ballerina.Constants.CLOSE_CURLY_BRACKET;
import static org.wso2.integration.ballerina.Constants.CODE_SEGMENT_BEGIN;
import static org.wso2.integration.ballerina.Constants.CODE_SEGMENT_END;
import static org.wso2.integration.ballerina.Constants.COMMA;
import static org.wso2.integration.ballerina.Constants.COMMENT_END;
import static org.wso2.integration.ballerina.Constants.COMMENT_START;
import static org.wso2.integration.ballerina.Constants.EMPTY_STRING;
import static org.wso2.integration.ballerina.Constants.GIT_PROPERTIES_FILE;
import static org.wso2.integration.ballerina.Constants.HASH;
import static org.wso2.integration.ballerina.Constants.INCLUDE_CODE_SEGMENT_TAG;
import static org.wso2.integration.ballerina.Constants.INCLUDE_CODE_TAG;
import static org.wso2.integration.ballerina.Constants.INCLUDE_MD_TAG;
import static org.wso2.integration.ballerina.Constants.MARKDOWN_FILE_EXT;
import static org.wso2.integration.ballerina.Constants.NEW_LINE;
import static org.wso2.integration.ballerina.Constants.OPEN_CURLY_BRACKET;
import static org.wso2.integration.ballerina.Constants.README_MD;
import static org.wso2.integration.ballerina.Constants.TEMP_DIR_MD;
import static org.wso2.integration.ballerina.utils.Utils.addPrevDirectorySyntax;
import static org.wso2.integration.ballerina.utils.Utils.copyDirectoryContent;
import static org.wso2.integration.ballerina.utils.Utils.createDirectory;
import static org.wso2.integration.ballerina.utils.Utils.createFile;
import static org.wso2.integration.ballerina.utils.Utils.deleteDirectory;
import static org.wso2.integration.ballerina.utils.Utils.deleteFile;
import static org.wso2.integration.ballerina.utils.Utils.getCodeFile;
import static org.wso2.integration.ballerina.utils.Utils.getCommitHash;
import static org.wso2.integration.ballerina.utils.Utils.getLeadingWhitespaces;
import static org.wso2.integration.ballerina.utils.Utils.getMarkdownCodeBlockWithCodeType;
import static org.wso2.integration.ballerina.utils.Utils.getPostFrontMatter;
import static org.wso2.integration.ballerina.utils.Utils.getStringBetweenTwoStrings;
import static org.wso2.integration.ballerina.utils.Utils.getZipFileName;
import static org.wso2.integration.ballerina.utils.Utils.isDirEmpty;
import static org.wso2.integration.ballerina.utils.Utils.isImageAttachmentLine;
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
        // Directory paths
        final String DOCS_DIR = Paths.get(args[0], "..", "content", "src").toString();
        final String TARGET_DIR = Paths.get(args[0], "target").toString();

        final String TEMP_DIR = Paths.get(TARGET_DIR, "tempDirectory").toString();
        final String MKDOCS_CONTENT = Paths.get(TARGET_DIR, "mkdocs-content").toString();

        BasicConfigurator.configure();
        logger.info("Docs generating process started...");
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
        zipBallerinaProjects(TEMP_DIR, TEMP_DIR);
        // Delete non markdown files.
        deleteUnwantedFiles(TEMP_DIR, DOCS_DIR);
        // Delete empty directories.
        deleteEmptyDirs(TEMP_DIR);
        // Copy tempDirectory content to mkdocs content directory.
        copyDirectoryContent(TEMP_DIR, MKDOCS_CONTENT);
        // Create `target/www` website directory.
        createWebsiteDirectory(Paths.get(TARGET_DIR, "..", "www").toString(), Paths.get(TARGET_DIR, "www").toString(),
                MKDOCS_CONTENT);
        logger.info("Docs generating process finished...");
    }

    /**
     * Process files inside given directory.
     *
     * @param directoryPath path of the directory
     */
    private static void processDirectory(String directoryPath) {
        // Delete doc-generator directory.
        deleteDirectory(directoryPath + File.separator + "doc-generator");

        File folder = new File(directoryPath);
        File[] listOfFiles = folder.listFiles();

        if (listOfFiles != null) {
            for (File file : listOfFiles) {
                String fileExtension = FilenameUtils.getExtension(file.getName());
                if (file.isFile()) {
                    if ((file.getName().equals(README_MD))) {
                        processReadmeFile(file, directoryPath);
                        renameReadmeFile(file);
                    } else if ((fileExtension.equals("bal") || fileExtension.equals("java"))
                            && !processCodeFile(file, directoryPath)) {
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
    private static void processReadmeFile(File file, String tempDir) {
        try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
            String readMeFileContent = IOUtils
                    .toString(new FileInputStream(file), String.valueOf(StandardCharsets.UTF_8));

            String line;
            int lineNumber = 0;

            while ((line = reader.readLine()) != null) {
                lineNumber++;
                if (line.contains(INCLUDE_CODE_TAG)) {
                    // Replace INCLUDE_CODE line with include code file.
                    readMeFileContent = readMeFileContent
                            .replace(line, getIncludeCodeFile(file.getParent(), line, tempDir));
                } else if (line.contains(INCLUDE_CODE_SEGMENT_TAG)) {
                    // Replace INCLUDE_CODE_SEGMENT line with include code segment.
                    readMeFileContent = readMeFileContent
                            .replace(line, getIncludeCodeSegment(file.getParent(), line, tempDir));
                } else if (lineNumber == 1 && line.contains(HASH)) {
                    // Adding front matter to posts.
                    readMeFileContent = readMeFileContent.replace(line, getPostFrontMatter(line, commitHash));
                } else if (isImageAttachmentLine(line)) {
                    readMeFileContent = readMeFileContent.replace(line, getWebsiteImageAttachment(line));
                } else if (line.contains(INCLUDE_MD_TAG)) {
                    readMeFileContent = readMeFileContent
                            .replace(line, getIncludeMarkdownFile(file.getParent(), line, tempDir));
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
            String mdFileName = file.getParent() + File.separator + "1.md";
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
    private static String getIncludeCodeFile(String readMeParentPath, String line, String tempDir) {
        String fullPathOfIncludeCodeFile = readMeParentPath + getIncludeFilePathFromIncludeCodeLine(line, INCLUDE_CODE_TAG);
        File includeCodeFile = new File(fullPathOfIncludeCodeFile);
        String code = removeLicenceHeader(getCodeFile(includeCodeFile, readMeParentPath, tempDir), readMeParentPath).trim();
        return handleCodeAlignment(line, getMarkdownCodeBlockWithCodeType(fullPathOfIncludeCodeFile, code));
    }

    /**
     * Get code segment should be included in the README.md file.
     *
     * @param readMeParentPath parent path of the README.md file
     * @param line             line having INCLUDE_CODE_SEGMENT_TAG
     * @return code segment content should be included
     */
    private static String getIncludeCodeSegment(String readMeParentPath, String line, String tempDir) {
        String includeLineData = line.replace(COMMENT_START, EMPTY_STRING).replace(COMMENT_END, EMPTY_STRING)
                .replace(INCLUDE_CODE_SEGMENT_TAG, EMPTY_STRING)
                .trim();

        String[] tempDataArr = includeLineData.replace(OPEN_CURLY_BRACKET, EMPTY_STRING)
                .replace(CLOSE_CURLY_BRACKET, EMPTY_STRING).split(COMMA);

        String fullPathOfIncludeCodeFile =
                readMeParentPath + File.separator + tempDataArr[0].replace("file:", EMPTY_STRING).trim();
        String segment = tempDataArr[1].replace("segment:", EMPTY_STRING).trim();

        File includeCodeFile = new File(fullPathOfIncludeCodeFile);
        String codeFileContent = removeLicenceHeader(getCodeFile(includeCodeFile, readMeParentPath, tempDir),
                readMeParentPath);

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
     * get file path of the INCLUDE_TAG line.
     *
     * @param line line having INCLUDE_TAG
     * @return file path of the file should be included
     */
    private static String getIncludeFilePathFromIncludeCodeLine(String line, String includeTag) {
        return "/" + line.replace(COMMENT_START, EMPTY_STRING).replace(COMMENT_END, EMPTY_STRING)
                .replace(includeTag, EMPTY_STRING).trim();
    }

    /**
     * Delete unwanted files other than `md` files & `zip` files. Also delete `Module.md` files.
     *
     * @param directoryPath directory want to delete files
     */
    private static void deleteUnwantedFiles(String directoryPath, String docsDir) {
        File folder = new File(directoryPath);
        File[] listOfFiles = folder.listFiles();

        if (listOfFiles != null) {
            for (File file : listOfFiles) {
                if (file.isFile()) {
                    if (isUnwanted(file, docsDir)) {
                        deleteFile(file);
                    }
                } else if (file.isDirectory()) {
                    deleteUnwantedFiles(file.getPath(), docsDir);
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
    private static boolean isUnwanted(File file, String docsDir) {
        boolean mdFile = FilenameUtils.getExtension(file.getName()).equals(MARKDOWN_FILE_EXT);
        boolean moduleMdFile = file.getName().equals("Module.md");
        boolean zipFile = FilenameUtils.getExtension(file.getName()).equals("zip");
        boolean imgFile = new File(Paths.get(docsDir, "assets", "img").toString(), file.getName()).exists();

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
    private static void zipBallerinaProjects(String directoryPath, String tempDir) {
        File folder = new File(directoryPath);
        File[] listOfFiles = folder.listFiles();

        if (listOfFiles != null) {
            for (File file : listOfFiles) {
                if (file.isFile() && (file.getName().equals(BALLERINA_TOML))) {
                    // Zip parent folder since this is a Ballerina project.
                    try {
                        new ZipFile(getZipFileName(tempDir, file))
                                .addFolder(new File(file.getParentFile().getPath()));
                    } catch (ZipException e) {
                        throw new ServiceException("Error when zipping the directory: "
                                + file.getParentFile().getPath(), e);
                    }
                } else if (file.isDirectory()) {
                    zipBallerinaProjects(file.getPath(), tempDir);
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
    private static boolean processCodeFile(File file, String tempDir) {
        File tempFile = new File(tempDir + File.separator + "temp.txt");

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

    /**
     * Create `target/www` website directory.
     */
    private static void createWebsiteDirectory(String srcWwwDirPath, String websiteDir, String mkdocsContent) {
        // Copy `www` directory inside `target` directory.
        copyDirectoryContent(srcWwwDirPath, websiteDir);
        // Copy `target/mkdocs-content` directory content to `target/www/docs`.
        copyDirectoryContent(mkdocsContent, websiteDir + File.separator + "docs");
    }

    /**
     * Since GitHub repo Image attachment Url is not working in the website, `../` should be added to the image Url.
     *
     * @param line image attachment line
     * @return image attachment line for website
     */
    private static String getWebsiteImageAttachment(String line) {
        String imageUrl = line.trim().split("]\\(")[1].replace(")", EMPTY_STRING);
        return line.replace(imageUrl, "../" + imageUrl);
    }

    /**
     * Get markdown file content should be included in the README.md file.
     *
     * @param readMeParentPath parent path of the README.md file
     * @param line             line having INCLUDE_MD_TAG
     * @return content of the markdown file should be included
     */
    private static String getIncludeMarkdownFile(String readMeParentPath, String line, String tempDir) {
        String fullPathOfIncludeMdFile = readMeParentPath + getIncludeFilePathFromIncludeCodeLine(line, INCLUDE_MD_TAG);
        File includeMdFile = new File(fullPathOfIncludeMdFile);
        String includeMdContent = getCodeFile(includeMdFile, readMeParentPath, tempDir).trim();
        // Check fullPathOfIncludeMdFile is `get-the-code.md`.
        if (fullPathOfIncludeMdFile.contains("tutorial-get-the-code.md")) {
            String markdownWithZipName = setZipFileName(includeMdContent, readMeParentPath);
            return setModuleName(setGetTheCodeMdPaths(fullPathOfIncludeMdFile, markdownWithZipName), readMeParentPath);
        } else {
            return includeMdContent;
        }
    }

    /**
     * Set zip file name by replacing `<<<MD_FILE_NAME>>>` with zip file name.
     *
     * @param includeMdContent include markdown file content
     * @param readMeParentPath README.md parent path
     * @return include markdown file content after replacing `<<<MD_FILE_NAME>>>`
     */
    private static String setZipFileName(String includeMdContent, String readMeParentPath) {
        String zipName = readMeParentPath.substring(readMeParentPath.lastIndexOf('/') + 1).trim();
        return includeMdContent.replace("<<<MD_FILE_NAME>>>", zipName);
    }

    /**
     * Set paths in `tutorial-get-the-code.md` for non default cases.
     *
     * @param fullPathOfIncludeMdFile full path of include md file
     * @param includeMdContent        include md file content
     * @return `tutorial-get-the-code.md` content after changing `download-zip` path.
     */
    private static String setGetTheCodeMdPaths(String fullPathOfIncludeMdFile, String includeMdContent) {
        // Get the no of occurrences of `../`
        int occurrences = fullPathOfIncludeMdFile.split("\\../", -1).length - 1;
        if (occurrences == 4) { // Default case: `tutorial-get-the-code.md` has 4 `../`s.
            return includeMdContent;
        } else { // Need to set the `download-zip` path.
            // Set the `download-zip` image path.
            String mdImgPath = getStringBetweenTwoStrings(includeMdContent, "<img src=\"",
                    "\" width=\"200\" alt=\"Download ZIP\">");
            String correctImgPath = addPrevDirectorySyntax(mdImgPath, occurrences + 1 - 5);
            String replacedImgContent = includeMdContent.replace(mdImgPath, correctImgPath);
            // Set the `download-zip` anchor path.
            String zipAnchorPath = getStringBetweenTwoStrings(replacedImgContent, "<a href=\"",
                    "\">\n" + "    <img src=\"");
            String correctZipAnchorPath = addPrevDirectorySyntax(zipAnchorPath, occurrences + 1 - 5);
            return replacedImgContent.replace(zipAnchorPath, correctZipAnchorPath);
        }
    }

    /**
     * Set module name by replacing `<<<MODULE_NAME>>>` by module name of the project.
     *
     * @param includeMdContent include markdown file content
     * @param readMeParentPath README.md parent path
     * @return include markdown file content after replacing `<<<MODULE_NAME>>>`
     */
    private static String setModuleName(String includeMdContent, String readMeParentPath) {
        String moduleName = findModuleName(readMeParentPath);
        if (moduleName.isEmpty()) {
            throw new ServiceException("Module name not found. projectPath: " + readMeParentPath);
        } else {
            return includeMdContent.replace("<<<MODULE_NAME>>>", moduleName);
        }
    }

    /**
     * Find module name to set module name.
     *
     * @param readMeParentPath README.md parent path
     * @return module name
     */
    private static String findModuleName(String readMeParentPath) {
        boolean moduleFound = false;
        String moduleName = "";
        File moduleParent = new File(readMeParentPath + File.separator + "src");
        File[] listOfFiles = moduleParent.listFiles();

        if (listOfFiles == null) {
            throw new ServiceException("Cannot find module name. projectPath: " + moduleParent.getPath());
        } else {
            for (File child : listOfFiles) {
                if (child.isDirectory()) {
                    if (!moduleFound) {
                        moduleName = child.getName();
                        moduleFound = true;
                    } else {
                        throw new ServiceException(
                                "Module name already found, Please confirm this project contains only "
                                        + "one module. projectPath: " + moduleParent.getPath());
                    }
                }
            }
        }
        return moduleName;
    }
}
