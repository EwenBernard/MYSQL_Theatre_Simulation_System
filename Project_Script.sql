SET GLOBAL log_bin_trust_function_creators = 1;
drop database database_project;
create database if not exists database_project;
use database_project;
SET SQL_SAFE_UPDATES = 0;


DROP TABLE IF EXISTS Theatre;
CREATE TABLE Theatre(
        -- id_company   Int  Auto_increment,
        id_theatre     Int Auto_Increment,
        capacity     Int,
        budget     Float (25),
        city     Char (25),
        -- PRIMARY KEY (id_company)
        PRIMARY KEY (id_theatre)
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
        price     Float (25),
        reduc_price int,
        date_Ticket     Date,
        id_spectacle_Spectacle   int,
        nb_ticket_sold int,
        nb_ticket_sold_today int,
        PRIMARY KEY (date_ticket, id_spectacle_Spectacle)
)ENGINE=InnoDB;


DROP TABLE IF EXISTS Sponsor;
CREATE TABLE Sponsor(
        id_sponsor  int  Auto_increment,
        name     Char (25),
        price_Subventionner     Float (25),
        date_start_Subventionner     Date,
        date_end_Subventionner     Date,
        id_company_Theatre   int,
        id_theatre_Theatre     Int (25),
        PRIMARY KEY (id_sponsor)
)ENGINE=InnoDB;



DROP TABLE IF EXISTS Produire;
CREATE TABLE Produire(
        id_company_Theatre   int,
        id_theatre_Theatre     Int (25),
        id_spectacle_Spectacle    int,
        PRIMARY KEY (id_company_Theatre,id_theatre_Theatre,id_spectacle_Spectacle)
        -- PRIMARY KEY (id_company_Theatre, id_spectacle_Spectacle)
)ENGINE=InnoDB;

CREATE TABLE Transaction_History(
	id_transaction int Auto_increment,
    transaction_date date,
    id_theatre_payer int,
    id_theatre_receiver int,
    id_theatre_account_balance int,
    amount int,
    label char,
    PRIMARY KEY(id_transaction)
)ENGINE=InnoDB;

DROP TABLE IF EXISTS Accueillie;
CREATE TABLE Accueillie(
        global_fix_price     Float (25),
        date_start     Date,
        date_end     Date,
        travel_costs   Float (25),
        staging_costs     Float (25),
        comedians_fees Float (25),
        id_company_Theatre    int,
        id_theatre_Theatre     Int (25),
        id_spectacle_Spectacle   int,
        -- PRIMARY KEY (id_company_Theatre, id_spectacle_Spectacle)
        PRIMARY KEY (id_company_Theatre,id_theatre_Theatre,id_spectacle_Spectacle)
)ENGINE=InnoDB;

CREATE TABLE Calendar (
  index_date int,
  date DATE,
  PRIMARY KEY (index_date)
)ENGINE=InnoDB;

DROP TABLE IF EXISTS day_show;
CREATE TABLE day_show(
        global_fix_price     Float (25),
        date_start     Date,
        date_end     Date,
        travel_costs   Float (25),
        staging_costs     Float (25),
        comedians_fees Float (25),
        id_foreign_theatre    int,
        id_theatre_Theatre     Int (25),
        id_spectacle_Spectacle   int,
        PRIMARY KEY (id_foreign_theatre, id_spectacle_Spectacle)
)ENGINE=InnoDB;

DELIMITER /

CREATE TRIGGER before_update_Ticket BEFORE UPDATE
ON Ticket FOR EACH ROW
BEGIN 
	DECLARE date_diff INT;
    DECLARE capacity INT;
    SET date_diff = DATEDIFF(OLD.date_Ticket, (SELECT date FROM Calendar));
    SET capacity = (SELECT Theatre.capacity FROM
				   Ticket INNER JOIN day_show ON Ticket.id_spectacle_Spectacle = day_show.id_spectacle_Spectacle 
				   INNER JOIN Theatre ON day_show.id_spectacle_Spectacle = Theatre.id_theatre
                   WHERE Ticket.id_spectacle_Spectacle = NEW.id_spectacle_Spectacle AND date_Ticket = OLD.date_Ticket);
    SET NEW.nb_ticket_sold = NEW.nb_ticket_sold + NEW.nb_ticket_sold_today;               
    CASE
		WHEN date_diff = 0 AND (0.3 * capacity) > NEW.nb_ticket_sold THEN SET NEW.reduc_price = NEW.price DIV 2;
        WHEN date_diff = 0 AND (0.5 * capacity) > NEW.nb_ticket_sold THEN SET NEW.reduc_price = NEW.price - (0.3 * NEW.price);
        WHEN date_diff < 15 THEN SET NEW.reduc_price = NEW.price - (0.2 * NEW.price);
        ELSE SET NEW.reduc_price = NEW.price;
    END CASE;
 END/   


CREATE PROCEDURE main()
    BEGIN
        DECLARE current_day DATE;
        DECLARE offset int;
        DECLARE nb_days int;
        SET offset = 0;
        SET nb_days = 20;
        
        WHILE (SELECT offset < nb_days) DO
            INSERT INTO day_show(global_fix_price, date_start, date_end, travel_costs, staging_costs, comedians_fees, id_company_Theatre, id_theatre_Theatre,
                                 id_spectacle_Spectacle) SELECT * FROM Accueillie
                                                         WHERE current_day >= Accueillie.date_start
                                                         AND current_day <= Accueillie.date_end;
            IF (SELECT COUNT(*) FROM day_show) > 0 THEN
            
                -- pay travel cost if show is played in another theatre
                UPDATE Theatre 
				INNER JOIN day_show ON id_theatre_Theatre = Theatre.id_Theatre
				SET Theatre.budget = budget - day_show.travel_costs 
				WHERE day_show.id_foreign_theatre != id_theatre_Theatre;
                
                -- pay stagings cost the first day for all the representations
                UPDATE Theatre 
				INNER JOIN day_show ON day_show.id_foreign_theatre = Theatre.id_Theatre
				SET Theatre.budget = Theatre.budget - (day_show.staging_costs * (DATEDIFF(day_show.date_end, day_show.date_start) + 1));

				UPDATE Theatre 
				INNER JOIN day_show ON day_show.id_theatre_Theatre = Theatre.id_Theatre
				SET Theatre.budget = Theatre.budget + (day_show.staging_costs * (DATEDIFF(day_show.date_end, day_show.date_start) + 1))
				WHERE Theatre.id_theatre != day_show.id_foreign_theatre;
                
                -- pay comedians fee
                UPDATE Theatre 
				INNER JOIN day_show ON id_theatre_Theatre = Theatre.id_Theatre
				SET Theatre.budget = Theatre.budget - day_show.comedians_fees
				WHERE (SELECT date FROM Calendar) BETWEEN day_show.date_start AND day_show.date_end;

                -- simulate ticket sell
                UPDATE Ticket 
                INNER JOIN day_show ON Ticket.id_spectacle_Spectacle = day_show.id_spectacle_Spectacle 
                INNER JOIN Theatre ON day_show.id_spectacle_Spectacle = Theatre.id_theatre 
                SET nb_ticket_sold_today = ROUND(RAND() * Theatre.capacity DIV 15);
                
            end if;
		UPDATE Calendar 
        SET index_date = index_date + 1, date = DATE_ADD(date, INTERVAL 1 DAY);
        end while;
    end /

DELIMITER ;

ALTER TABLE Ticket ADD CONSTRAINT FK_Ticket_id_spectacle_Spectacle FOREIGN KEY (id_spectacle_Spectacle) REFERENCES Spectacle(id_spectacle);
ALTER TABLE Sponsor ADD CONSTRAINT FK_Sponsor_id_theatre_Theatre FOREIGN KEY (id_theatre_Theatre) REFERENCES Theatre(id_theatre);
ALTER TABLE Produire ADD CONSTRAINT FK_Produire_id_theatre_Theatre FOREIGN KEY (id_theatre_Theatre) REFERENCES Theatre(id_theatre);
ALTER TABLE Produire ADD CONSTRAINT FK_Produire_id_spectacle_Spectacle FOREIGN KEY (id_spectacle_Spectacle) REFERENCES Spectacle(id_spectacle);
ALTER TABLE Accueillie ADD CONSTRAINT FK_Accueillie_id_theatre_Theatre FOREIGN KEY (id_theatre_Theatre) REFERENCES Theatre(id_theatre);
ALTER TABLE Accueillie ADD CONSTRAINT FK_Accueillie_id_spectacle_Spectacle FOREIGN KEY (id_spectacle_Spectacle) REFERENCES Spectacle(id_spectacle);

INSERT INTO Theatre (capacity, budget, city)
 VALUES
 ('3000', '200000.0', 'Paris'),
 ('1500', '400000.0', 'London'),
 ('2000', '200000.0', 'Espagne'),
 ('13000', '300000.0', 'Paris'),
 ('1100', '454000.0', 'London'),
 ('2000', '267000.0', 'New York'),
 ('2000', '267000.0', 'Espagne'),
 ('20000', '367000.0', 'Los Angeles'),
 ('2200', '267000.0', 'Espagne'),
 ('14000', '330000.0', 'Italie');

 INSERT INTO Spectacle (id_spectacle, name, production_count, distribution_count)
 VALUES
 ('1', 'Grease', '100000.0', '30000.0'),
 ('2', 'Roi Lion', '80000.0', '25000.0'),
 ('3', 'Roméo et Juliette', '120000.0', '40000.0'),
 ('4', 'Les Pas perdus', '90000.0', '50000.0'),
 ('5', 'Le tartuffe', '75000.0', '30000.0');


INSERT INTO Ticket (price, reduc_price, date_Ticket, id_spectacle_Spectacle, nb_ticket_sold, nb_ticket_sold_today)
 VALUES
(10, 10, '2021-01-05', 1, 0, 0),
(12, 12, '2021-01-01', 2, 0, 0);



/*
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
 ('5', 'Chanel','30000.0', '','','3');
 */
 
insert into Calendar(index_date, date) VALUES (1, "2021-01-02");
insert into day_show(global_fix_price, date_start, date_end, travel_costs, staging_costs, comedians_fees, id_foreign_theatre, id_theatre_Theatre, id_spectacle_Spectacle) VALUES (NULL,"2021-01-01","2021-01-01",300, 4000,1000,1,1,1), (NULL,"2021-01-01","2021-01-03", 500, 1000,1000,2,1,2);
SELECT * FROM day_show;

/*
UPDATE Ticket 
INNER JOIN day_show ON Ticket.id_spectacle_Spectacle = day_show.id_spectacle_Spectacle 
INNER JOIN Theatre ON day_show.id_spectacle_Spectacle = Theatre.id_theatre 
SET nb_ticket_sold_today = ROUND(RAND() * Theatre.capacity DIV 15);

UPDATE Ticket 
INNER JOIN day_show ON Ticket.id_spectacle_Spectacle = day_show.id_spectacle_Spectacle 
INNER JOIN Theatre ON day_show.id_spectacle_Spectacle = Theatre.id_theatre 
SET nb_ticket_sold_today = ROUND(RAND() * Theatre.capacity DIV 15);

SELECT * FROM Ticket;
-- select ticket_reduction('2021-01-01', '2021-01-01', 100, 500);
-- select random_ticket((Select capacity from Theatre));
*/

Select * FROM Theatre INNER JOIN day_show ON id_theatre_Theatre = Theatre.id_Theatre;
