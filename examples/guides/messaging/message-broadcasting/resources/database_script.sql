CREATE DATABASE IF NOT EXISTS healthcare;
USE healthcare;
CREATE TABLE IF NOT EXISTS APPOINTMENTS (
    AppointmentNumber INT,
    AppointmentDate VARCHAR(200),
    Fee INT,
    Doctor VARCHAR(200),
    Hospital  VARCHAR(200),
    Patient VARCHAR(200),
    Phone VARCHAR(200)
);

CREATE USER wso2@'%' IDENTIFIED BY 'wso2'; 
GRANT ALL PRIVILEGES ON *.* TO 'wso2'@'%';
FLUSH PRIVILEGES;




