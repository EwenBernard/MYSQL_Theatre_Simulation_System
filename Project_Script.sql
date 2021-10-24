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
        id_company_Theatre    int,
        id_theatre_Theatre     Int (25),
        id_spectacle_Spectacle   int,
        PRIMARY KEY (id_company_Theatre, id_spectacle_Spectacle)
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
    CASE
		WHEN date_diff = 0 AND (30 * capacity DIV 100) > NEW.nb_ticket_sold THEN SET NEW.reduc_price = OLD.price DIV 2;
        WHEN date_diff = 0 AND (50 * capacity DIV 100) > NEW.nb_ticket_sold THEN SET NEW.reduc_price = OLD.price - (30 * OLD.price);
        WHEN date_diff < 15 THEN SET NEW.reduc_price = OLD.price - (20 * OLD.price);
    END CASE;
 END/   

CREATE FUNCTION ticket_reduction(current_day DATE, show_date DATE, ticket_sold INT, capacity INT, price INT) RETURNS INT
    BEGIN
    DECLARE date_diff INT;
    DECLARE ret float;
    SET date_diff = DATEDIFF(show_date, current_day);
    CASE
		WHEN date_diff = 0 AND (30 * capacity DIV 100) > ticket_sold THEN SET ret = price DIV 2;
        WHEN date_diff = 0 AND (50 * capacity DIV 100) > ticket_sold THEN SET ret = price - (30 * price);
        WHEN date_diff < 15 THEN SET ret = price - (20 * price);
        ELSE SET ret = price;
    END CASE;
    RETURN ret;
end; /

CREATE FUNCTION random_ticket(theatre_capacity INT) RETURNS INT
BEGIN
	RETURN ROUND(RAND() * theatre_capacity) DIV 15;
end; /



CREATE PROCEDURE main()
    BEGIN
        DECLARE current_day DATE;
        DECLARE offset int;
        SET offset = 0;
        WHILE (SELECT offset < (SELECT row_count() FROM Calendar)) DO
            SET current_day = (SELECT date FROM Calendar WHERE (index_date = offset));
            INSERT INTO day_show(global_fix_price, date_start, date_end, travel_costs, staging_costs, comedians_fees, id_company_Theatre, id_theatre_Theatre,
                                 id_spectacle_Spectacle) SELECT * FROM Accueillie
                                                         WHERE current_day >= Accueillie.date_start
                                                         AND current_day <= Accueillie.date_end;
            IF (SELECT COUNT(*) FROM day_show) > 0 THEN
                -- pay travel cost if show is played in another theatre
                UPDATE Theatre SET budget = budget - (SELECT travel_costs FROM day_show WHERE id_company = id_company_Theatre)
                WHERE id_theatre != (SELECT id_theatre_Theatre FROM day_show WHERE id_company = id_company_Theatre AND date_start = current_day);
                -- pay stagings cost the first day for all the representations
                UPDATE Theatre SET budget = budget - ((SELECT staging_costs FROM day_show WHERE id_company = id_company_Theatre)
                                   * (SELECT DATEDIFF(date_start, date_end) AS days FROM day_show))
                WHERE id_theatre = (SELECT id_theatre_Theatre FROM day_show WHERE date_start = current_day);
                IF ((SELECT id_company_Theatre FROM day_show) != (SELECT id_theatre_Theatre FROM day_show)) THEN
                    UPDATE Theatre SET budget = budget - ((SELECT staging_costs FROM day_show WHERE id_company = id_company_Theatre)
                                   * (SELECT DATEDIFF(date_start, date_end) AS days FROM day_show))
                    WHERE id_theatre = (SELECT id_company_Theatre FROM day_show WHERE date_start = current_day);
                end if;
                -- pay comedians fee
                UPDATE Theatre SET budget = budget - (SELECT comedians_fees FROM day_show WHERE id_company_Theatre = id_company)
                WHERE id_company = (SELECT id_company_Theatre FROM day_show WHERE id_company_Theatre = id_company);
                
                -- simulate ticket sell
                UPDATE Ticket 
                INNER JOIN day_show ON Ticket.id_spectacle_Spectacle = day_show.id_spectacle_Spectacle 
                INNER JOIN Theatre ON day_show.id_spectacle_Spectacle = Theatre.id_theatre 
                SET nb_ticket_sold = nb_ticket_sold + ROUND(RAND() * Theatre.capacity DIV 15);
                
            end if;
		UPDATE Calendar 
        SET index_date = index_date + 1, date = DATE_ADD(date, INTERVAL 1 DAY);
        end while;
    end /

DELIMITER ;

ALTER TABLE Ticket ADD CONSTRAINT FK_Ticket_id_spectacle_Spectacle FOREIGN KEY (id_spectacle_Spectacle) REFERENCES Spectacle(id_spectacle);
-- ALTER TABLE Sponsor ADD CONSTRAINT FK_Sponsor_id_company_Theatre FOREIGN KEY (id_company_Theatre) REFERENCES Theatre(id_company);
ALTER TABLE Sponsor ADD CONSTRAINT FK_Sponsor_id_theatre_Theatre FOREIGN KEY (id_theatre_Theatre) REFERENCES Theatre(id_theatre);
-- ALTER TABLE Produire ADD CONSTRAINT FK_Produire_id_company_Theatre FOREIGN KEY (id_company_Theatre) REFERENCES Theatre(id_company);
ALTER TABLE Produire ADD CONSTRAINT FK_Produire_id_theatre_Theatre FOREIGN KEY (id_theatre_Theatre) REFERENCES Theatre(id_theatre);
ALTER TABLE Produire ADD CONSTRAINT FK_Produire_id_spectacle_Spectacle FOREIGN KEY (id_spectacle_Spectacle) REFERENCES Spectacle(id_spectacle);
-- ALTER TABLE Accueillie ADD CONSTRAINT FK_Accueillie_id_company_Theatre FOREIGN KEY (id_company_Theatre) REFERENCES Theatre(id_company);
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


INSERT INTO Ticket (price, reduc_price, date_Ticket, id_spectacle_Spectacle, nb_ticket_sold)
 VALUES
('10','10','2021-01-01','1','0'),
('12','12','2021-01-01','2','0');



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
 
 insert into Calendar(index_date, date) VALUES (1, "2021-01-01");
 insert into day_show(global_fix_price, date_start, date_end, staging_costs, comedians_fees, id_company_Theatre, id_theatre_Theatre, id_spectacle_Spectacle) VALUES (NULL,NULL,NULL,NULL,NULL,1,1,1), (NULL,NULL,NULL,NULL,NULL,2,1,2);
SELECT * FROM day_show;
-- UPDATE Ticket SET nb_ticket_sold = nb_ticket_sold + ROUND(RAND() * (SELECT capacity FROM Theatre WHERE id_theatre = 1) DIV 15);
                -- (SELECT id_theatre FROM day_show WHERE id_spectacle_Spectacle = Ticket.id_spectacle_Spectacle)) DIV 15) ;
UPDATE Ticket 
INNER JOIN day_show ON Ticket.id_spectacle_Spectacle = day_show.id_spectacle_Spectacle 
INNER JOIN Theatre ON day_show.id_spectacle_Spectacle = Theatre.id_theatre 
SET nb_ticket_sold = nb_ticket_sold + ROUND(RAND() * Theatre.capacity DIV 15);

SELECT * FROM Ticket;
-- select ticket_reduction('2021-01-01', '2021-01-01', 100, 500);
-- select random_ticket((Select capacity from Theatre));
