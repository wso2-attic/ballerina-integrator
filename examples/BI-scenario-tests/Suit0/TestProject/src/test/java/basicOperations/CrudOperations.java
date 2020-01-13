package basicOperations;

import org.testng.annotations.Test;
import org.testng.Assert;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import static io.restassured.RestAssured.given;
import io.restassured.path.json.JsonPath;

public class CrudOperations {
	
	String url = "http://localhost:9090/company/";
	JsonPath jsonPathEvaluator;
	Response response = null;
	
	@Test(priority = 0, description="TC001")
	public void testWriteJsonFile()
	{
		String jsonRequest = "{\n" + 
				"    \"name\": \"John Doe\",\n" + 
				"    \"dob\": \"1940-03-19\",\n" + 
				"    \"ssn\": \"234-23-525\",\n" + 
				"    \"address\": \"California\",\n" + 
				"    \"phone\": \"8770586755\",\n" + 
				"    \"email\": \"johndoe@gmail.com\",\n" + 
				"    \"doctor\": \"thomas collins\",\n" + 
				"    \"hospital\": \"grand oak community hospital\",\n" + 
				"    \"cardNo\": \"7844481124110331\",\n" + 
				"    \"appointment_date\": \"2025-04-02\"\n" + 
				"}";
		
		response = given()
					.contentType(ContentType.JSON)
					.accept(ContentType.JSON)
					.body(jsonRequest)
					.when()
					.post(url+"addJsonFile");
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");
		
		Assert.assertEquals(message, "Employee records uploaded successfully.");
		Assert.assertEquals(response.getStatusCode(), 200);
	}
	
	@Test(priority = 1, description="TC002")
	public void testReadJsonFile()
	{
		String fileName = "account.json";
		response = given().when().get(url+"readFile/"+fileName);
		
		String expected = "{\"name\":\"John Doe\", \"dob\":\"1940-03-19\", \"ssn\":\"234-23-525\", \"address\":\"California\", "
				+ "\"phone\":\"8770586755\", \"email\":\"johndoe@gmail.com\", \"doctor\":\"thomas collins\", \""
				+ "hospital\":\"grand oak community hospital\", \"cardNo\":\"7844481124110331\", \"appointment_date\":\"2025-04-02\"}";

		Assert.assertEquals(response.asString(), expected);
		Assert.assertEquals(response.getStatusCode(), 200);
	}
	
	@Test(priority = 2, description="TC003")
	public void testWriteXMLFile()
	{		
		String requestBody = "<client>\r\n" +
	            "    <clientNo>100</clientNo>\r\n" +
	            "    <name>Tom Cruise</name>\r\n" +
	            "    <ssn>124-542-5555</ssn>\r\n" +
	            "</client>";
		
		response = 	given()
					.contentType(ContentType.XML)
				 	.accept(ContentType.XML)
				 	.body(requestBody)
				 	.when()
				 	.post(url+"addXMLFile");
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");
		
		Assert.assertEquals(message, "Employee records uploaded successfully.");
		Assert.assertEquals(response.getStatusCode(), 200);
	}
	
	@Test(priority = 3, description="TC004")
	public void testReadXMLFile()
	{
		String fileName = "client.xml";
		response = given().when().get(url+"readFile/"+fileName);
		
		String expected = "<client>\n" + 
				"    <clientNo>100</clientNo>\n" + 
				"    <name>Tom Cruise</name>\n" + 
				"    <ssn>124-542-5555</ssn>\n" + 
				"</client>";
		
		Assert.assertEquals(response.asString(), expected);
		Assert.assertEquals(response.getStatusCode(), 200);
	}
	
	@Test(priority = 4, description="TC005")
	public void testRenameFile()
	{
		String newFileName = "RenamedFile.json";
		String existingFileName = "account.json";
		response = given().when().get(url+"renameFile/"+existingFileName+"/"+newFileName);
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");

		Assert.assertEquals(message, "The file is renamed successfully.");
		Assert.assertEquals(response.getStatusCode(), 200);
	}
	
	@Test(priority = 5, description="TC006")
	public void testDeleteFile()
	{
		String fileName = "RenamedFile.json";
		response = given().when().delete(url+"deleteFile/"+fileName);
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");

		Assert.assertEquals(message, "Employee records deleted successfully.");
		Assert.assertEquals(response.getStatusCode(), 200);
	}

	@Test(priority = 6, description="TC007")
	public void testCreateFolder()
	{
		String folderName = "DMajor";
		response = given().when().get(url+"createFolder/"+folderName);
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");

		Assert.assertEquals(message, "The folder is created successfully.");
		Assert.assertEquals(response.getStatusCode(), 200);
	}
	
	@Test(priority = 7, description="TC008", dependsOnMethods="testCreateFolder")
	public void testRemoveFolder()
	{
		String folderName = "DMajor";
		response = given().when().get(url+"removeFolder/"+folderName);
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");

		Assert.assertEquals(message, "The folder is deleted successfully.");
		Assert.assertEquals(response.getStatusCode(), 200);
	}
	
	@Test(priority = 8, description="TC009")
	public void testDeleteNonExistingFile()
	{
		String fileName = "Saxaphone.txt";
		response = given().when().delete(url+"deleteFile/"+fileName);

		Assert.assertTrue(response.asString().contains(fileName+" not found"));

	}
	
	@Test(priority = 9, description="TC010")
	public void testCreateExistingFolder()
	{
		String folderName = "DMajor";
		response = given().when().get(url+"createFolder/"+folderName);
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");
		String reason = jsonPathEvaluator.get("Resason");

		Assert.assertEquals(message, "Error occurred creating folder.");
		Assert.assertTrue(reason.contains("Directory exists"));
	}
	
	@Test(priority = 10, description="TC011")
	public void testRemoveNonExistingFolder()
	{
		String folderName = "DMajor-non-exists";
		response = given().when().get(url+"removeFolder/"+folderName);
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");
		String reason = jsonPathEvaluator.get("Reason");

		Assert.assertEquals(message, "Error occurred deleting the folder.");
		Assert.assertTrue(reason.contains("Failed to delete directory") && reason.contains(folderName+ " not found"));
	}
	
	@Test(priority = 11, description="TC012")
	public void testRenameNonExistingFile()
	{
		String existingFileName = "NonExistingFile.json";
		String newFileName = "newFile.json";
		response = given().when().get(url+"renameFile/"+existingFileName+"/"+newFileName);
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");
		String reason = jsonPathEvaluator.get("Reason");

		Assert.assertEquals(message, "Error occurred renaming the file.");
		Assert.assertTrue(reason.contains("Failed to rename file") && reason.contains(existingFileName+ " not found"));
	}
	
	@Test(priority = 12, description="TC013")
	public void testRetriveFileSize()
	{
		String fileContent= "This file needs to retrive its file size.";
		response = given().contentType(ContentType.TEXT).body(fileContent).when().post(url+"addTextFile");
		Response responseRetriveFile = given().when().get(url + "retreiveFileSize"+"/student.txt");
		
		jsonPathEvaluator = responseRetriveFile.jsonPath();
		int fileSize = jsonPathEvaluator.get("FileSize");

		boolean canRetriveFileSize = false;
		if(fileSize > 0)
		{
			canRetriveFileSize = true;
		}
			
		Assert.assertEquals(canRetriveFileSize, true);
		Assert.assertEquals(responseRetriveFile.statusCode(), 200);
	}
	
	// disabled until https://github.com/wso2/ballerina-integrator/issues/752 get resolved. 
	@Test(priority = 13, description="TC014", enabled = false)
	public void testListFiles()
	{
		String fileContent= "This file needs to retrive its file size.";
		given().contentType(ContentType.TEXT).body(fileContent).when().post(url+ "addFiles" + "/" + "%2Fhome%2Fftp-user%2Fin%2Fdmajor1.txt");
		given().contentType(ContentType.TEXT).body(fileContent).when().post(url+ "addFiles" + "/" +  "%2Fhome%2Fftp-user%2Fin%2Fdmajor2.txt");
		given().contentType(ContentType.TEXT).body(fileContent).when().post(url+ "addFiles" + "/" +  "%2Fhome%2Fftp-user%2Fin%2Fdmajor3.txt");
		
		response = given().when().get(url +"listFiles" + "/" +"%2Fhome%2Fftp-user%2Fin%2F");
		
	}
	
	@Test(priority = 14, description="TC015")
	public void testVerifyFolder()
	{
		response = given().when().get(url + "verifyDirectory" +"/"+ "%2Fhome%2Fftp-user%2Fin%2F");
		
		jsonPathEvaluator = response.jsonPath();
		boolean status = jsonPathEvaluator.get("Message");

		Assert.assertEquals(status, true);
	}
	
	@Test(priority = 15, description="TC016")
	public void testVerifyFolder_N()
	{
		response = given().when().get(url + "verifyDirectory" +"/"+ "%2Fhome%2Fftp-user%2Fin%2Fdmajor1.txt");
		
		jsonPathEvaluator = response.jsonPath();
		boolean status = jsonPathEvaluator.get("Message");

		Assert.assertEquals(status, false);
	}
	
	@Test(priority=16, description = "TC017")
	public void testAddFile_N() {
		String fileContent= "This is a Negative test case";
		response = given().contentType(ContentType.TEXT).body(fileContent).when().post(url+ "addFiles" + "/" + "%2Fftp-user%2Fin%2Fincorrectpath.txt");
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");
		String reason = jsonPathEvaluator.get("Resason");
		
		Assert.assertEquals(message, "Error occurred uploading file to FTP.");
		Assert.assertTrue(reason.contains("Could not create file"));
			
	}
	
	@Test(priority=17, description = "TC018")
	public void testAppendFile() {
		//writing a new file to ftp-server
		String fileContent= "The saxophone (referred to colloquially as the sax) is a woodwind instrument usually made of brass.";
		given().contentType(ContentType.TEXT).body(fileContent).when().post(url+ "addFiles" + "/" + "%2Fhome%2Fftp-user%2Fin%2Fsaxophone.txt");
		
		//appending another file to the existing file
		String fileContentAppend= "There are many talented saxophone players in Sri Lanka.";
		response = given().contentType(ContentType.TEXT).body(fileContentAppend).when().post(url+ "appendFile" +"/"+ "%2Fhome%2Fftp-user%2Fin%2Fsaxophone.txt");
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");
		
		//read the content of the appended file
		String expectedReadresponse = "The saxophone (referred to colloquially as the sax) is a woodwind instrument usually made of brass.There are many talented saxophone players in Sri Lanka.";
		Response readResponse = response = given().when().get(url+"readFile/"+"saxophone.txt");
		
		Assert.assertEquals(message, "File appended successfully");
		Assert.assertEquals(readResponse.asString(), expectedReadresponse);
		
		//delete the file in the server
		given().when().delete(url+"deleteFile/"+"saxophone.txt");
	}
	
	@Test(priority=18, description = "TC019")
	public void testAppendFile_N() {
		//appending to a non-existing file
		String fileContentAppend= "There are many talented saxophone players in Sri Lanka.";
		response = given().contentType(ContentType.TEXT).body(fileContentAppend).when().post(url+ "appendFile" +"/"+ "%2Fftp-user%2Fin%2Fsaxophone1.txt");
		
		jsonPathEvaluator = response.jsonPath();
		String message = jsonPathEvaluator.get("Message");
		
		Assert.assertEquals(message, "Error occurred while appending the file.");

	}
	
	
	
}
