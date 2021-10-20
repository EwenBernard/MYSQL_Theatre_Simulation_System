
drop database database_project;
create database if not exists database_project;
use database_project;

DROP TABLE IF EXISTS Theatre;
CREATE TABLE Theatre(
        id_company   Int  Auto_increment,
        -- id_theatre     Int Auto,
        capacity     Int,
        budget     Float (25),
        city     Char (25),
        PRIMARY KEY (id_company)
        -- PRIMARY KEY (id_company,id_theatre)
)ENGINE=InnoDB;



DROP TABLE IF EXISTS Spectacle;
CREATE TABLE Spectacle(
        id_spectacle   int Auto_increment,
        name     Char (25),
        production_count     Float (25),
        distribution_count     Float (25),
        PRIMARY KEY (id_spectacle)
)ENGINE=InnoDB;



DROP TABLE IF EXISTS Ticket;
CREATE TABLE Ticket(
        id_ticket    int Auto_increment,
        reduction_rate     Int (25),
        normal_price     Bool,
        reduct_price     Bool,
        price     Float (25),
        date__Reserver     Date,
        id_spectacle_Spectacle   int,
        PRIMARY KEY (id_ticket)
)ENGINE=InnoDB;



DROP TABLE IF EXISTS Sponsor;
CREATE TABLE Sponsor(
        id_sponsor  int  Auto_increment,
        name     Char (25),
        price_Subventionner     Float (25),
        date_start_Subventionner     Date,
        date_end_Subventionner     Date,
        id_company_Theatre   int,
        -- id_theatre_Theatre     Int (25),
        PRIMARY KEY (id_sponsor)
)ENGINE=InnoDB;



DROP TABLE IF EXISTS Produire;
CREATE TABLE Produire(
        id_company_Theatre   int,
        -- id_theatre_Theatre     Int (25),
        id_spectacle_Spectacle    int,
        -- PRIMARY KEY (id_company_Theatre,id_theatre_Theatre,id_spectacle_Spectacle)
        PRIMARY KEY (id_company_Theatre, id_spectacle_Spectacle)
)ENGINE=InnoDB;



DROP TABLE IF EXISTS Accueillie;
CREATE TABLE Accueillie(
        global_fix_price     Float (25),
        date_start     Date,
        date_end     Date,
        frais_transport     Float (25),
        frais_mes     Float (25),
        id_company_Theatre    int,
        -- id_theatre_Theatre     Int (25),
        id_spectacle_Spectacle   int,
        PRIMARY KEY (id_company_Theatre, id_spectacle_Spectacle)
        -- PRIMARY KEY (id_company_Theatre,id_theatre_Theatre,id_spectacle_Spectacle)
)ENGINE=InnoDB;

CREATE TABLE Calendar (
  date DATE,
  PRIMARY KEY (date)
)ENGINE=InnoDB;

DELIMITER /
CREATE PROCEDURE init_date()
	BEGIN
    
	DECLARE basedate DATE;
	DECLARE offset INT;
	SET basedate = "2021-01-01";
	SET	offset = 1;

	WHILE (offset < 60) DO
        INSERT INTO Calendar VALUES (basedate);
        SET basedate = DATE_ADD(basedate, INTERVAL 1 DAY);
        SET offset = offset + 1;
	END WHILE;
END /

CREATE PROCEDURE main()
    BEGIN
        DECLARE current_day DATE;
        DECLARE day_show int;
        DECLARE offset int;
        SET offset = 0;
        WHILE (SELECT offset < (SELECT row_count() FROM Calendar)) DO
            SET current_day = SELECT 
            SET day_show = (SELECT * FROM Accueillie WHERE current_day >= Accueillie.date_start
                AND current_day <= Accueillie.date_end);
            IF
        end while;
    end /

DELIMITER ;

ALTER TABLE Ticket ADD CONSTRAINT FK_Ticket_id_spectacle_Spectacle FOREIGN KEY (id_spectacle_Spectacle) REFERENCES Spectacle(id_spectacle);
ALTER TABLE Sponsor ADD CONSTRAINT FK_Sponsor_id_company_Theatre FOREIGN KEY (id_company_Theatre) REFERENCES Theatre(id_company);
-- ALTER TABLE Sponsor ADD CONSTRAINT FK_Sponsor_id_theatre_Theatre FOREIGN KEY (id_theatre_Theatre) REFERENCES Theatre(id_theatre);
ALTER TABLE Produire ADD CONSTRAINT FK_Produire_id_company_Theatre FOREIGN KEY (id_company_Theatre) REFERENCES Theatre(id_company);
-- ALTER TABLE Produire ADD CONSTRAINT FK_Produire_id_theatre_Theatre FOREIGN KEY (id_theatre_Theatre) REFERENCES Theatre(id_theatre);
ALTER TABLE Produire ADD CONSTRAINT FK_Produire_id_spectacle_Spectacle FOREIGN KEY (id_spectacle_Spectacle) REFERENCES Spectacle(id_spectacle);
ALTER TABLE Accueillie ADD CONSTRAINT FK_Accueillie_id_company_Theatre FOREIGN KEY (id_company_Theatre) REFERENCES Theatre(id_company);
-- ALTER TABLE Accueillie ADD CONSTRAINT FK_Accueillie_id_theatre_Theatre FOREIGN KEY (id_theatre_Theatre) REFERENCES Theatre(id_theatre);
ALTER TABLE Accueillie ADD CONSTRAINT FK_Accueillie_id_spectacle_Spectacle FOREIGN KEY (id_spectacle_Spectacle) REFERENCES Spectacle(id_spectacle);



CALL init_date();

select row_count() from Calendar;



INSERT INTO Theatre (id_company, capacity, budget, city)
 VALUES
 ('1', '3000', '200000.0', 'Paris'),
 ('2', '1500', '400000.0', 'London'),
 ('3', '2000', '200000.0', 'Espagne'),
 ('4', '13000', '300000.0', 'Paris'),
 ('5', '1100', '454000.0', 'London'),
 ('6', '2000', '267000.0', 'New York'),
 ('7', '2000', '267000.0', 'Espagne'),
 ('8', '20000', '367000.0', 'Los Angeles'),
 ('9', '2200', '267000.0', 'Espagne'),
 ('10', '14000', '330000.0', 'Italie');
 
 INSERT INTO Spectacle (id_spectacle, name, production_count, distribution_count)
 VALUES
 ('1', 'Grease', '100000.0', '30000.0'),
 ('2', 'Roi Lion', '80000.0', '25000.0'),
 ('3', 'Roméo et Juliette', '120000.0', '40000.0'),
 ('4', 'Les Pas perdus', '90000.0', '50000.0'),
 ('5', 'Le tartuffe', '75000.0', '30000.0');
 
INSERT INTO Ticket (id_ticket, reduction_rate, normal_price, reduct_price, price, date__Reserver, id_spectacle_Spectacle)
 VALUES
 ('1', '', '', '','30','','1'),
 ('2', '', '', '','35','','2'),
 ('3', '', '', '','25','','3'),
 ('4', '', '', '','20','','4'),
 ('5', '', '', '','22','','5');
 
  
INSERT INTO Sponsor (id_sponsor, name, price_Subventionner, date_start_Subventionner, date_end_Subventionner, id_company_Theatre)
 VALUES
 ('1', 'Orange', '10000.0', '','','1'),
 ('2', 'Bnp Paribas','20000.0', '','','4'),
 ('3', 'Amrican Express','35000.0', '','','2'),
 ('4', 'British Land','40000.0', '','','5'),
 ('5', 'Chanel','30000.0', '','','3'),
 ('6', 'RedBull','25000.0', '','','8'), #What a shame ...
 ('7', 'My Big Paella','30000.0', '','','7'),
 ('8', 'Bank of America','50000.0', '','','8'),
 ('9', 'My Small Paella','15000.0', '','','9'),
 ('10', 'Tods','25000.0', '','','10');
 
 
 INSERT INTO Produire ( id_company_Theatre,id_spectacle_Spectacle)
  VALUES
 ('',''),
 ('',''),
 ('',''),
 ('',''),
 ('',''),
 ('',''),
 ('',''),
 ('','');
 
 
  INSERT INTO Accueillie (global_fix_price, date_start, date_end, frais_transport, frais_mes, id_company_Theatre, id_spectacle_Spectacle)
   VALUES
 ('1', 'Orange', '10000.0', '','','1'),
 ('2', 'Bnp Paribas','20000.0', '','','4'),
 ('3', 'Amrican Express','35000.0', '','','2'),
 ('4', 'British Land','40000.0', '','','5'),
 ('5', 'Chanel','30000.0', '','','3'),
 
 
 
 
 
 #select * from Theatre;