CREATE DATABASE Employee;

USE Employee;

CREATE TABLE IF NOT EXISTS Employee(
	id INTEGER PRIMARY KEY,
      firstName VARCHAR(50),
	lastName VARCHAR(50),
	age INTEGER,
      email VARCHAR(50)
);

INSERT INTO Employee VALUES ('0001', 'thomas', 'collins',32,'thomasc@enp.com'),
                            ('0002', 'henry', 'parker', 22,'henryp@enp.com'),
                            ('0003', 'abner', 'collins', 40,'abner@enp.com'),
                            ('0004', 'anne', 'clements', 38,'annec@enp.com'),
                            ('0005', 'thomas','kirk', 25,'thomask@enp.com'),
                            ('0006','emeline','foultaon', 31,'emelinef@enp.com'),
                            ('0007', 'jared', 'morris', 32,'jaredm@enp.com'),
                            ('0008', 'henry', 'fosterr', 37,'henryf@enp.com'),
                            ('0009', 'jones', 'kirk', 32, 'jonesk@enp.com'),
                            ('0010', 'hanny', 'white', 33,'hannyw@enp.com');
