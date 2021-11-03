SET GLOBAL log_bin_trust_function_creators = 1;
drop database database_project;
create database if not exists database_project;
use database_project;
SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS=0;


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
        date_Subventionner     Date,
        id_theatre_Theatre     Int (25),
        donation_type Char(25),
        PRIMARY KEY (id_sponsor)
)ENGINE=InnoDB;



DROP TABLE IF EXISTS Produire;
CREATE TABLE Produire(
        id_theatre_Theatre     Int (25),
        id_spectacle_Spectacle    int,
        PRIMARY KEY (id_theatre_Theatre,id_spectacle_Spectacle)
)ENGINE=InnoDB;

CREATE TABLE Transaction_History(
	id_transaction int Auto_increment,
    transaction_date date,
    id_theatre_payer int,
    id_theatre_receiver int,
    id_theatre_account_balance int,
    amount int,
    label char(25),
    PRIMARY KEY(id_transaction)
)ENGINE=InnoDB;

DROP TABLE IF EXISTS Accueillie;
CREATE TABLE Accueillie(
        date_start     Date,
        date_end     Date,
        travel_costs   Float (25),
        staging_costs     Float (25),
        comedians_fees Float (25),
        id_foreign_theatre    int,
        id_theatre_Theatre     Int (25),
        id_spectacle_Spectacle   int,
        PRIMARY KEY (id_foreign_theatre,id_theatre_Theatre,id_spectacle_Spectacle)
)ENGINE=InnoDB;

CREATE TABLE Calendar (
  index_date int,
  date DATE,
  PRIMARY KEY (index_date)
)ENGINE=InnoDB;

DROP TABLE IF EXISTS day_show;
CREATE TABLE day_show(
        date_start     Date,
        date_end     Date,
        travel_costs   Float (25),
        staging_costs     Float (25),
        comedians_fees Float (25),
        id_foreign_theatre    int,
        id_theatre_Theatre     Int (25),
        id_spectacle_Spectacle   int,
        PRIMARY KEY (id_foreign_theatre, id_spectacle_Spectacle, date_start, date_end)
)ENGINE=InnoDB;

DELIMITER /

CREATE TRIGGER before_update_Ticket BEFORE UPDATE
ON Ticket FOR EACH ROW
BEGIN 
	DECLARE date_diff INT;
    DECLARE capacity INT;
    SET date_diff = DATEDIFF(OLD.date_Ticket, (SELECT date FROM Calendar));
    SET capacity = (SELECT Theatre.capacity FROM Ticket 
				    INNER JOIN day_show ON Ticket.id_spectacle_Spectacle = day_show.id_spectacle_Spectacle 
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
 
 CREATE PROCEDURE pay_sponsors()
 BEGIN 
	UPDATE Theatre 
    INNER JOIN Sponsor ON Sponsor.id_theatre_Theatre = Theatre.id_theatre
    SET Theatre.budget = Theatre.budget + Sponsor.price_Subventionner
    WHERE (Sponsor.date_Subventionner = (SELECT Date FROM Calendar) AND Sponsor.donation_type = "SINGLE")
    OR (DAY(Sponsor.date_Subventionner) = DAY((SELECT Date FROM Calendar)) AND Sponsor.donation_type = "MONTHLY")
    OR (DAY(Sponsor.date_Subventionner) = DAY((SELECT Date FROM Calendar)) AND MONTH(Sponsor.date_Subventionner) = MONTH((SELECT Date FROM Calendar)) AND Sponsor.donation_type = "YEARLY");
    
    INSERT INTO Transaction_History(id_theatre_receiver, id_theatre_account_balance, amount) 
    SELECT Theatre.id_theatre, Theatre.budget, Sponsor.price_Subventionner 
	FROM Theatre INNER JOIN Sponsor ON Sponsor.id_theatre_Theatre = Theatre.id_theatre
	WHERE (Sponsor.date_Subventionner = (SELECT Date FROM Calendar) AND Sponsor.donation_type = "SINGLE")
	OR (DAY(Sponsor.date_Subventionner) = DAY((SELECT Date FROM Calendar)) AND Sponsor.donation_type = "MONTHLY")
	OR (DAY(Sponsor.date_Subventionner) = DAY((SELECT Date FROM Calendar)) AND MONTH(Sponsor.date_Subventionner) = MONTH((SELECT Date FROM Calendar)) AND Sponsor.donation_type = "YEARLY");
    
    UPDATE Transaction_History SET transaction_date = (SELECT Date FROM Calendar), label = 'Sponsors' WHERE transaction_date IS NULL AND label IS NULL;  
end / 
 
 
 CREATE PROCEDURE pay_ticket()
 BEGIN 
	DECLARE id_spectacle_loop int;
	DECLARE reduc_price_loop int; 
	DECLARE nb_ticket_sold_today_loop int;
	DECLARE finished INT DEFAULT 0;
    DECLARE ticket_cursor CURSOR FOR SELECT id_spectacle_Spectacle, reduc_price, nb_ticket_sold_today FROM Ticket;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    
	OPEN ticket_cursor;
	updateBudget : LOOP
		FETCH ticket_cursor INTO id_spectacle_loop, reduc_price_loop, nb_ticket_sold_today_loop;
		IF finished = 1 THEN
			LEAVE updateBudget;
		END IF;   
		UPDATE Theatre SET Theatre.budget = Theatre.budget + ROUND(0.85 * nb_ticket_sold_today_loop *  reduc_price_loop + 0.1275 * nb_ticket_sold_today_loop *  reduc_price_loop) 
        WHERE id_spectacle_loop IN (SELECT id_spectacle_Spectacle FROM day_show WHERE id_theatre_Theatre = Theatre.id_theatre);
        
        INSERT INTO Transaction_History(id_theatre_receiver, id_theatre_account_balance) SELECT id_theatre, budget FROM Theatre 
        WHERE id_spectacle_loop IN (SELECT id_spectacle_Spectacle FROM day_show WHERE id_theatre_Theatre = Theatre.id_theatre);
        UPDATE Transaction_History SET amount = ROUND(0.85 * nb_ticket_sold_today_loop *  reduc_price_loop + 0.1275 * nb_ticket_sold_today_loop *  reduc_price_loop), 
        transaction_date = (SELECT date from Calendar), label = 'Ticket Sold' WHERE amount IS NULL;
	END LOOP updateBudget;
	CLOSE ticket_cursor;
 END/


CREATE PROCEDURE main()
BEGIN
	DECLARE current_day DATE;
	DECLARE offset int;
	DECLARE nb_days int;
	SET offset = 0;
	SET nb_days = 60;
	
	WHILE (SELECT offset < nb_days) DO
		SET current_day = (SELECT date FROM Calendar);
		INSERT INTO day_show(date_start, date_end, travel_costs, staging_costs, comedians_fees, id_foreign_theatre, id_theatre_Theatre,
							 id_spectacle_Spectacle) SELECT * FROM Accueillie
													 WHERE current_day >= Accueillie.date_start
													 AND current_day <= Accueillie.date_end;
		
		IF (select count(1) where exists (select * from day_show)) THEN
			-- pay travel cost if show is played in another theatre
			UPDATE Theatre 
			INNER JOIN day_show ON id_theatre_Theatre = Theatre.id_Theatre
			SET Theatre.budget = budget - day_show.travel_costs 
			WHERE day_show.id_foreign_theatre != id_theatre_Theatre;
            
            -- UPDATE TRANSACTION HISTORY
			INSERT INTO Transaction_History (id_theatre_payer, id_theatre_account_balance, amount) 
			SELECT Theatre.id_theatre, Theatre.Budget, day_show.travel_costs FROM Theatre 
			INNER JOIN day_show ON id_theatre_Theatre = Theatre.id_Theatre;

			UPDATE Transaction_History SET transaction_date = (SELECT Date FROM Calendar), label = 'Travel Costs' WHERE transaction_date IS NULL AND label IS NULL;
			
			-- pay stagings cost the first day for all the representations
			UPDATE Theatre 
			INNER JOIN day_show ON day_show.id_foreign_theatre = Theatre.id_Theatre
			SET Theatre.budget = Theatre.budget - (day_show.staging_costs * (DATEDIFF(day_show.date_end, day_show.date_start) + 1))
            WHERE day_show.date_start = current_day;

			UPDATE Theatre 
			INNER JOIN day_show ON day_show.id_theatre_Theatre = Theatre.id_Theatre
			SET Theatre.budget = Theatre.budget + (day_show.staging_costs * (DATEDIFF(day_show.date_end, day_show.date_start) + 1))
			WHERE Theatre.id_theatre != day_show.id_foreign_theatre AND day_show.date_start = current_day;
            
            -- UPDATE TRANSACTION_HISTORY
			INSERT INTO Transaction_History (id_theatre_payer, id_theatre_receiver, id_theatre_account_balance, amount) 
			SELECT Theatre.id_theatre, day_show.id_theatre_Theatre, Theatre.budget, (day_show.staging_costs * (DATEDIFF(day_show.date_end, day_show.date_start) + 1))  FROM Theatre 
			INNER JOIN day_show ON day_show.id_foreign_Theatre = Theatre.id_Theatre
            WHERE day_show.date_start = (SELECT Date FROM Calendar);

			UPDATE Transaction_History SET transaction_date = (SELECT Date FROM Calendar), label = 'Staging Costs' WHERE transaction_date IS NULL AND label IS NULL; 
			UPDATE Transaction_History SET id_theatre_receiver = NULL WHERE id_theatre_payer = id_theatre_receiver;
			
			-- pay comedians fee
			UPDATE Theatre 
			INNER JOIN day_show ON id_theatre_Theatre = Theatre.id_Theatre
			SET Theatre.budget = Theatre.budget - day_show.comedians_fees
			WHERE current_day BETWEEN day_show.date_start AND day_show.date_end;
            
            INSERT INTO Transaction_History (id_theatre_payer, id_theatre_account_balance, amount) 
			SELECT Theatre.id_theatre, Theatre.budget, day_show.travel_costs 
			FROM Theatre 
			INNER JOIN day_show ON id_theatre_Theatre = Theatre.id_Theatre
			WHERE current_day BETWEEN day_show.date_start AND day_show.date_end;

			UPDATE Transaction_History SET transaction_date = (SELECT Date FROM Calendar), label = 'Comedian Fees' WHERE transaction_date IS NULL AND label IS NULL;
			
			-- simulate ticket sell
			UPDATE Ticket 
			INNER JOIN day_show ON Ticket.id_spectacle_Spectacle = day_show.id_spectacle_Spectacle 
			INNER JOIN Theatre ON day_show.id_spectacle_Spectacle = Theatre.id_theatre 
			SET nb_ticket_sold_today = ROUND(RAND() * Theatre.capacity DIV 15);
			
			CALL pay_ticket();
            
            -- pay sponsors
            
			CALL pay_sponsors();
		
		end if;
        -- Delete selected show
		DELETE FROM day_show;
        -- Change date
		UPDATE Calendar 
		SET index_date = index_date + 1, date = DATE_ADD(date, INTERVAL 1 DAY);
		SET offset = offset + 1;
    end while;
end/

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


INSERT INTO Sponsor (id_sponsor, name, price_Subventionner, date_Subventionner, id_theatre_Theatre, donation_type)
 VALUES
 ('1', 'Orange', '10000.0', '2021-01-01', '1' ,'SINGLE'),
 ('2', 'Bnp Paribas','20000.0', '2021-02-01', '2','MONTHLY'),
 ('3', 'Amrican Express','35000.0', '2021-01-05', '4','YEARLY');
 /*
 ('4', 'British Land','40000.0', '5','SINGLE'),
 ('5', 'Chanel','30000.0', '1','SINGLE'),
 ('6', 'RedBull','25000.0', '3','MONTHLY'), #What a shame ...
 ('7', 'My Big Paella','30000.0', '5','YEARLY'),
 ('8', 'Bank of America','50000.0', '6','SINGLE'),
 ('9', 'My Small Paella','15000.0', '4','SINGLE'),
 ('10', 'Tods','25000.0', '1','YEARLY');*/


insert into Calendar(index_date, date) VALUES (1, "2021-01-01");

INSERT INTO Accueillie (date_start, date_end, travel_costs, staging_costs, comedians_fees, id_foreign_theatre, id_theatre_Theatre, id_spectacle_Spectacle)
VALUES
('2021-01-06', '2021-01-08', 500, 3500, 700, 3, 2, 4),
("2021-01-01","2021-01-01",300, 4000,1000,1,1,1), 
("2021-01-01","2021-01-03", 500, 1000,1000,2,1,2);
 
 /*
insert into day_show(date_start, date_end, travel_costs, staging_costs, comedians_fees, id_foreign_theatre, id_theatre_Theatre, id_spectacle_Spectacle) VALUES ("2021-01-01","2021-01-01",300, 4000,1000,1,1,1), ("2021-01-01","2021-01-03", 500, 1000,1000,2,1,2);
SELECT * FROM day_show;*/


CALL main();
/*
SELECT * FROM Theatre;
SELECT * FROM Transaction_History;


-- TICKET

-- Select today ticket price 
SELECT reduc_price, Accueillie.id_spectacle_Spectacle, Theatre.id_theatre FROM Ticket 
INNER JOIN Accueillie ON Ticket.id_spectacle_Spectacle = Accueillie.id_spectacle_Spectacle 
INNER JOIN Theatre ON Accueillie.id_spectacle_Spectacle = Theatre.id_theatre;
*/

/*
-- Select nb ticket sold by Theatre
select sum(nb_ticket_sold), Theatre.id_theatre
from Ticket 
INNER JOIN Accueillie ON Ticket.id_spectacle_Spectacle = Accueillie.id_spectacle_Spectacle 
INNER JOIN Theatre ON Accueillie.id_spectacle_Spectacle = Theatre.id_theatre
group by Theatre.id_theatre;
*/

/*
-- Select AVG ticket sold by day for each theatre
select sum(nb_ticket_sold) DIV 60, Theatre.id_theatre
from Ticket 
INNER JOIN Accueillie ON Ticket.id_spectacle_Spectacle = Accueillie.id_spectacle_Spectacle 
INNER JOIN Theatre ON Accueillie.id_spectacle_Spectacle = Theatre.id_theatre
group by Theatre.id_theatre;
*/

/*
-- Average load for each theatre
select AVG(nb_ticket_sold), Theatre.id_theatre
from Ticket 
INNER JOIN Accueillie ON Ticket.id_spectacle_Spectacle = Accueillie.id_spectacle_Spectacle 
INNER JOIN Theatre ON Accueillie.id_spectacle_Spectacle = Theatre.id_theatre
group by Theatre.id_theatre;
*/

-- ACCOUNTING

/*
-- Get first date and ID_theatre where account balance is null
SELECT transaction_date, id_theatre_payer FROM Transaction_History WHERE id_theatre_account_balance <= 0 GROUP BY id_theatre_payer;
*/

/*
The distribution of ticket sales is not fixed in a table. It is done randomly depending on several parameters such as the size of the theater. 
It is therefore impossible to know exactly when a theater will go banrukpt. 
We can however consider that under -30000 euros the theater will not get enough money in to compensate the losses. 
*/
/*
-- get date and id_theatre where account balance will move permanently to the red
SELECT transaction_date, id_theatre_payer FROM Transaction_History WHERE id_theatre_account_balance <= -30000 GROUP BY id_theatre_payer;
*/

-- GET DIFFERENCE COST / EARNING FROM THEATRE
/*
SELECT pay_table.id_theatre, (IFNULL(receive_sum, 0) - IFNULL(pay_table.pay_sum, 0)) AS Balance
FROM (SELECT id_theatre_payer AS id_theatre, SUM(amount) AS pay_sum FROM Transaction_History WHERE id_theatre_payer IS NOT NULL GROUP BY id_theatre_payer) AS pay_table
LEFT JOIN (SELECT id_theatre_receiver, SUM(amount) AS receive_sum FROM Transaction_History WHERE id_theatre_receiver IS NOT NULL GROUP BY id_theatre_receiver) AS receive_table
ON pay_table.id_theatre = receive_table.id_theatre_receiver;
*/

SELECT * FROM Transaction_History;


