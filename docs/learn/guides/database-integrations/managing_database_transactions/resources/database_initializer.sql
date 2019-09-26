-- Create database `bankDB` if not exist
CREATE DATABASE IF NOT EXISTS bankDB;

-- Select the `bankDB` database
USE bankDB;

-- Drop table `ACCOUNT` if already exist
DROP TABLE IF EXISTS ACCOUNT;

-- Create table `Account`
CREATE TABLE ACCOUNT(ID INT AUTO_INCREMENT, USERNAME VARCHAR(20) NOT NULL, BALANCE INT UNSIGNED NOT NULL, PRIMARY KEY(ID));






