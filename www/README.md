# Ballerina Integrator Markdown files generator

This guide helps to generate markdown files which needs to generate ballerina integrator website using **wso2/docs-ei** 
github repository.

## Instructions to create README.md files

### 1. Include README.md heading

Include heading for the README.md file with `#`. You can have only one main heading with `#`. 
Check following example on how to add the main heading. This should be the very first line and should not use
multiple lines for the main heading.
```
# Asynchronous messaging
```

### 2. Include code

#### (a) Include a code file

Use below syntax to add code files. So when pre-processing markdown files this tag will be replaced with the 
actual code file in the git.
```
<!-- INCLUDE_CODE: guide/http_message_receiver.bal -->
```
When you are mentioning the code file please mention the valid path to the file you want to include.

#### (b) Include a code segment

*README.md file*

```
<!-- INCLUDE_CODE_SEGMENT: { file: guide/http_message_receiver.bal, segment: segment_1 } -->
```

*Code file*

```
// CODE-SEGMENT-BEGIN: segment_1
{code}
// CODE-SEGMENT-END: segment_1
```
***Please note that these syntax are very strict.*

### 3. Include resources

If you want to add resources like images please create a directory with the name **"resources"** and add all your 
resource files to that directory. 
In the markdown file mention full qualified path of the resource as mentioned below.
```
![alt text](https://raw.githubusercontent.com/pramodya1994/ballerina-integrator/hugo-site/examples/guides/messaging/asynchronous-messaging/resources/Asynchronous_service_invocation.png)
``` 
When you are mentioning the resource file please mention the valid path to the file you want to add.

## Build markdown files to include in mkdocs site

Run below command in your terminal

```
./init.sh 
```
Get markdown files from **mkdocs-content** directory.
