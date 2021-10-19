DROP TABLE IF EXISTS Theatre;
CREATE TABLE Theatre(
        id_company   Int  Auto_increment,
        id_theatre     Int (25),
        capacity     Int (25),
        budget     Float (25),
        city     Char (25),
        PRIMARY KEY (id_company,id_theatre)
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
        id_spectacle_Spectacle   int  Auto_increment,
        PRIMARY KEY (id_ticket)
)ENGINE=InnoDB;



DROP TABLE IF EXISTS Sponsor;
CREATE TABLE Sponsor(
        id_sponsor  int  Auto_increment,
        name     Char (25),
        price_Subventionner     Float (25),
        date_start_Subventionner     Date,
        date_end_Subventionner     Date,
        id_company_Theatre   int Auto_increment,
        id_theatre_Theatre     Int (25),
        PRIMARY KEY (id_sponsor)
)ENGINE=InnoDB;



DROP TABLE IF EXISTS Produire;
CREATE TABLE Produire(
        id_company_Theatre   int Auto_increment,
        id_theatre_Theatre     Int (25),
        id_spectacle_Spectacle    int Auto_increment,
        PRIMARY KEY (id_company_Theatre,id_theatre_Theatre,id_spectacle_Spectacle)
)ENGINE=InnoDB;



DROP TABLE IF EXISTS Accueillie;
CREATE TABLE Accueillie(
        global_fix_price     Float (25),
        date_start     Date,
        date_end     Date,
        frais_transport     Float (25),
        frais_mes     Float (25),
        id_company_Theatre    int Auto_increment,
        id_theatre_Theatre     Int (25),
        id_spectacle_Spectacle   int  Auto_increment,
        PRIMARY KEY (id_company_Theatre,id_theatre_Theatre,id_spectacle_Spectacle)
)ENGINE=InnoDB;



ALTER TABLE Ticket ADD CONSTRAINT FK_Ticket_id_spectacle_Spectacle FOREIGN KEY (id_spectacle_Spectacle) REFERENCES Spectacle(id_spectacle);
ALTER TABLE Sponsor ADD CONSTRAINT FK_Sponsor_id_company_Theatre FOREIGN KEY (id_company_Theatre) REFERENCES Theatre(id_company);
ALTER TABLE Sponsor ADD CONSTRAINT FK_Sponsor_id_theatre_Theatre FOREIGN KEY (id_theatre_Theatre) REFERENCES Theatre(id_theatre);
ALTER TABLE Produire ADD CONSTRAINT FK_Produire_id_company_Theatre FOREIGN KEY (id_company_Theatre) REFERENCES Theatre(id_company);
ALTER TABLE Produire ADD CONSTRAINT FK_Produire_id_theatre_Theatre FOREIGN KEY (id_theatre_Theatre) REFERENCES Theatre(id_theatre);
ALTER TABLE Produire ADD CONSTRAINT FK_Produire_id_spectacle_Spectacle FOREIGN KEY (id_spectacle_Spectacle) REFERENCES Spectacle(id_spectacle);
ALTER TABLE Accueillie ADD CONSTRAINT FK_Accueillie_id_company_Theatre FOREIGN KEY (id_company_Theatre) REFERENCES Theatre(id_company);
ALTER TABLE Accueillie ADD CONSTRAINT FK_Accueillie_id_theatre_Theatre FOREIGN KEY (id_theatre_Theatre) REFERENCES Theatre(id_theatre);
ALTER TABLE Accueillie ADD CONSTRAINT FK_Accueillie_id_spectacle_Spectacle FOREIGN KEY (id_spectacle_Spectacle) REFERENCES Spectacle(id_spectacle);