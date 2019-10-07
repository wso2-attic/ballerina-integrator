# Integration Use Cases

The Ballerina Integrator is the first code-centric approach to programming integrations directly into applications and microservices. It can be used to easily implement the use cases listed in this page and this is demonstrated using tutorials. Tutorials showcase how to build different types of integrations using a complete development lifecycle including IDE configuration, modules, dependencies, coding, and unit testing. Furthermore, each of these tutorials can be deployed as a project of its own via Docker and Kubernetes and setup for easy observability.

### SaaS Integration

SaaS offering is a common software distribution model followed by many vendors today. When building an application, connecting those systems would be one of the main requirements in your organization. The Ballerina Integrator offers a rich set of SaaS connectors such as Salesforce, SAP, Gmail, Google Spreadsheet, Amazon S3, Amazon SQS, etc. You can securely connect to any of those systems easily and build your integration seamlessly.

<table>
  <tr>
    <td><b><a href="../tutorials/saas-integrations/amazons3/working-with-amazons3-client/working-with-amazons3-client/">Working with Amazon S3 Client</a></b></br>
    Interact with the Amazon S3 API to integrate with other services</td>
    <td><b><a href="../tutorials/saas-integrations/amazonsqs/notifying-fire-alarm-using-sqs/notifying-fire-alarm-using-sqs/">Notifying Fire Alarm Using SQS/</a></b></br>
    Use Amazon SQS Connector to notify alerts</td>
    <td><b><a href="../tutorials/saas-integrations/gmail/using-the-gmail-connector/using-the-gmail-connector/">Using the Gmail Connector</a></b></br>
    Use the Gmail Connector to interact with the Gmail REST API</td>
  </tr>
  
  <tr>
    <td><b><a href="../tutorials/saas-integrations/sap/interacting-with-sap/interacting-with-sap/">Interacting with SAP</a></b></br>
    Interact with a SAP R/3 backend using BAPI requests and IDoc messages</td>
    <td><b><a href="../tutorials/saas-integrations/sfdc46/working-with-salesforce-client/working-with-salesforce-client/">Working with Salesforce Client</a></b></br>
    Use Salesforce client to performa a variety of CRUD operations</td>
    <td><b><a href="../tutorials/saas-integrations/sfdc46/salesforce-to-mysql-db/salesforce-to-mysql-db/">Salesforce to MySQL Database</a></b></br>
    Use batch processing to synchronize Salesforce data with a MySQL database</td>
  </tr>
  
  <tr>
    <td><b><a href="../tutorials/saas-integrations/sfdc46/import-contacts-into-salesforce-using-ftp/import-contacts-into-salesforce-using-ftp/">Import Contacts into Salesforce Using FTP</a></b></br>
    Import contacts from a CSV file into Salesforce using FTP</td>
    <td></td>
    <td></td>
  </tr>
</table>

### Messaging Integration

The messaging system supports loosely coupled asynchronous data to move from one application to another. There are popular messaging standard protocols and vendors. The JMS connector can be used to connect to any JMS-based message broker. Ballerina language has standard libraries for connecting with RabbitMQ, Kafka, and NATS. You can write the integration for guaranteed delivery with popular store forward enterprise integration pattern using the store forward connector.

<table>
<tr>
    <td><b><a href="../tutorials/messaging-integrations/sending-json-data-to-a-jms-queue/sending-json-data-to-a-jms-queue/">Sending JSON to a JMS Queue</a></b></br>
    Send JSON Data to a JMS Queue</td>
    <td><b><a href="../tutorials/messaging-integrations/messaging-with-kafka/messaging-with-kafka/">Messaging with Kafka</a></b></br>
    Publish messages to Apache Kafka</td>
    <td><b><a href="../tutorials/messaging-integrations/reliable-delivery/reliable-delivery	/">Reliable Delivery</a></b></br>
    Send messages in a reliable way</td>
</tr>

</table>

### Database Integration

Data storing in the database is a common approach in many application designs. It is not easy when you want to integrate your data store with other systems securely. The Ballerina integrator offers connectors to connect to your DBMS system whether it is a SQL such as MySQL or NoSQL such as MongoDB. You can perform all DB related operation with minimal lines of code and use them for building your integration.

<table>
  <tr>
    <td><b><a href="../tutorials/database-integrations/data-backed-service/data-backed-service/">Data-backed Service</a></b></br>
    Build a database-backed RESTful service</td>
    <td><b><a href="../tutorials/database-integrations/managing-database-transactions/managing-database-transactions/">Managing Database Transactions</a></b></br>
    Manage database transactions using Ballerina</td>
    <td><b><a href="../tutorials/database-integrations/mongo-db-transactions/insert-mongodb/insert-mongodb/">Integration with MongoDB</a></b></br>
    Integrate with MongoDB</td>
  </tr>
  
  <tr>
    <td><b><a href="../tutorials/database-integrations/querying-mysql-database/querying-mysql-database/">Querying MySQL Database</a></b></br>
    Expose MySQL database as a service and do a select query</td>
    <td></td>
    <td></td>
  </tr>
</table>

### File-based Integration

Most of the legacy systems use the file as a data transfer mechanism. It is a tedious task connecting to a file server and read files or upload files. There are different types of file formats and extensions that you have to consider reading or writing data. The Ballerina integrator supports connecting your file server with different protocols such as FTP, SFTP, SMB. The file connector act as a listener trigger an event of WatchEvent type, when new files are added to or deleted from the directory. The file connector act as the client supports the generic FTP operations; get, delete, put, append, mkdir, rmdir, isDirectory, rename, size, and list.

<table>
  <tr>
    <td><b><a href="../tutorials/file-based-integrations/file-integration-using-ftp/file-integration-using-ftp/">File Integration Using FTP</a></b></br>
    Use the FTP Connector to create an FTP listener service</td>
    <td><b><a href="../tutorials/file-based-integrations/file-integration-using-smb/file-integration-using-smb/">File Integration Using Samba</a></b></br>
    Use the SMB Connector to create a Samba listener service</td>
    <td></td>
  </tr>
</table>

### Integration Patterns and SOA

Service-oriented architecture (SOA) patterns provide structure and clarity, enabling architects to establish their SOA efforts across the enterprise. Moreover, these SOA patterns also help to link SOA and business requirements in an effective and efficient way. SOA solves the challenge of Enterprise Application Integration (EAI) by reducing the complexity of making enterprise applications work together and helping them evolve faster. It covers common integration patterns like Content-Based Routing, Scatter and Gather Messaging, Service Orchestration, Pass-through Messaging, etc. This section includes only a limited set of patterns, which provides a base, while Ballerina Integrator is capable of implementing almost all integration patterns of this nature.

<table>
  <tr>
    <td><b><a href="../tutorials/integration-patterns-and-soa/content-based-routing/content-based-routing/">Content-based Routing</a></b></br>
    Implement content-based routing</td>
    <td><b><a href="../tutorials/integration-patterns-and-soa/pass-through-messaging/pass-through-messaging/">Pass-through Messaging</a></b></br>
    Implement pass-through messaging</td>
    <td><b><a href="../tutorials/integration-patterns-and-soa/integration-patterns-and-soa/scatter-gather-flow/scatter-gather-flow/">Scatter-Gather Flow Control</a></b></br>
    Implement scatter-gather flow where two files are read simultaneously and aggregated</td>
  </tr>
  
  <tr>
    <td><b><a href="../tutorials/integration-patterns-and-soa/service-composition/service-composition/">Service Composition</a></b></br>
    Implement a service composition</td>
    <td><b><a href="../tutorials/integration-patterns-and-soa/service-orchestration/service-orchestration/">Service Orchestration</a></b></br>
    A service invokes two other services to do some functions</td>
    <td><b><a href="../tutorials/integration-patterns-and-soa/converting-json-to-xml-and-upload-to-ftp/converting-json-to-xml-and-upload-to-ftp/">Converting JSON to XML and Upload to FTP</a></b></br>
    Convert a JSON message to XML and upload it to FTP</td>
  </tr>

  <tr>
    <td><b><a href="../tutorials/integration-patterns-and-soa/exposing-soap-service/exposing-soap-service/">REST to SOAP</a></b></br>
    Accept a REST request and convert it to a SOAP request</td>
    <td><b><a href="../tutorials/integration-patterns-and-soa/backend-for-frontend/backend-for-frontend/">Backend for Frontend</a></b></br>
    Apply the BFF design pattern</td>
    <td></td>
  </tr>
</table>

