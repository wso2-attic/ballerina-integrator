# Ballerina Integrator Site Creator

This guide helps to generate Ballerina Integrator site using markdown files in the git repository. 

## Instructions to create README.md files

### 1. Include README.md heading

Include heading for the README.md file with `#`. You can have only one main heading with `#`. 
Check following example on how to add the main heading. This should be the very first line and should not use
multiple lines for the main heading.
```
# Asynchronous messaging
```

### 2. Add sub section

If you wants to create a sub section using a folder, you should add a markdown file with the name "**_index.md**".

### 3. Include code

#### Include a code file

Use below syntax to add code files. So when pre-processing markdown files this tag will be replaced with the 
actual code file in the git.
```
<!-- INCLUDE_CODE: guide/http_message_receiver.bal -->
```
When you are mentioning the code file please mention the valid path to the file you want to include.

#### Include a code segment

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

### 4. Include resources

If you want to add resources like images please create a directory with the name **"resources"** and add all your 
resource files to that directory. 
In the markdown file mention full qualified path of the resource as mentioned below.
```
![alt text](https://raw.githubusercontent.com/pramodya1994/ballerina-integrator/hugo-site/examples/guides/messaging/asynchronous-messaging/resources/Asynchronous_service_invocation.png)
``` 
When you are mentioning the resource file please mention the valid path to the file you want to add.

### 5. Add intro template files.

Use below front matter to add template files.
```
title: "Messaging"
description: "Everything about ballerina integrator messaging."
image: "resources/Asynchronous_service_invocation.png"
```

<!--### Add Jekyll front matter

You need to add front matter which provides meta information to build files using Jekyll. You can use following example 
to add front matter at the beginning of the markdown file. Please note that you have to add ```---``` (3 dashes) before 
and after adding meta data.
```
layout: post
title:  "Asynchronous messaging"
categories: messaging
```-->

## Build web site

First you should install hugo. Please refer [this document](https://gohugo.io/getting-started/installing) on how to install hugo.

Run below command in your terminal

```
./init.sh 
```
