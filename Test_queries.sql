use database_project;

-- ORGANISATION
/*A show can't overlap another because date / theatre ID are a primary key so can't take place at the same date in the same theatre.*/

/*
SELECT city FROM Theatre 
INNER JOIN Accueillie ON Theatre.id_theatre = Accueillie.id_theatre_Theatre
WHERE Accueillie.id_foreign_theatre != Accueillie.id_theatre_Theatre 
AND id_foreign_theatre = 3; -- Choose company id
*/

-- TICKET
-- Select today ticket price 
/*
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

-- GET TRANSACTION HISTORY
-- SELECT * FROM Transaction_History;

-- NETWORK