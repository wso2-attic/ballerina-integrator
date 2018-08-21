// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

/* 
 * MySQL Script - initializeDataBase.sql.
 * Create testDB database, student table and StudentDetails table.
 */
 
-- Create StudentDetailsDB database
CREATE DATABASE IF NOT EXISTS StudentDetailsDB;

-- Switch to StudentDetailsDB database
USE StudentDetailsDB;

-- create StudentDetails table and StudentResults table in the database
CREATE TABLE IF NOT EXISTS StudentDetails (id INT, name VARCHAR(255), city VARCHAR(255), gender VARCHAR(255), PRIMARY KEY (id));

-- Create testDB database
CREATE DATABASE IF NOT EXISTS StudentResultsDB;

-- Switch to StudentResultsDB database
USE StudentResultsDB;

-- create student table and StudentResults table in the database
CREATE TABLE IF NOT EXISTS StudentResults (ID INTEGER, Com_Maths VARCHAR(1), Physics VARCHAR(1), Chemistry VARCHAR(1), PRIMARY KEY (ID));

-- add values to table StudentDetails
INSERT INTO StudentResults(ID, Com_Maths, Physics, Chemistry) values (100, 'A', 'A', 'A');
INSERT INTO StudentResults(ID, Com_Maths, Physics, Chemistry) values (101, 'A', 'A', 'B');
INSERT INTO StudentResults(ID, Com_Maths, Physics, Chemistry) values (102, 'A', 'A', 'C');
INSERT INTO StudentResults(ID, Com_Maths, Physics, Chemistry) values (103, 'A', 'B', 'A');
INSERT INTO StudentResults(ID, Com_Maths, Physics, Chemistry) values (104, 'A', 'B', 'B');
INSERT INTO StudentResults(ID, Com_Maths, Physics, Chemistry) values (105, 'A', 'B', 'C');
INSERT INTO StudentResults(ID, Com_Maths, Physics, Chemistry) values (106, 'A', 'C', 'A');
INSERT INTO StudentResults(ID, Com_Maths, Physics, Chemistry) values (107, 'A', 'C', 'B');
INSERT INTO StudentResults(ID, Com_Maths, Physics, Chemistry) values (108, 'A', 'C', 'C');
INSERT INTO StudentResults(ID, Com_Maths, Physics, Chemistry) values (109, 'B', 'C', 'B');
INSERT INTO StudentResults(ID, Com_Maths, Physics, Chemistry) values (110, 'C', 'C', 'C');
