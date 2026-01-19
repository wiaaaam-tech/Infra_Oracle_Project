-- ============================================
-- PROJETT: Infrastructure DIGI_NETWORK
-- Fichier: DIGI_NETWORK_INFRA.sql
-- Auteur: Wiam Amanou – Technicienne Spécialiste Systèmes & Réseaux | Junior Oracle DBA
-- Description: Gestion d’infrastructures systèmes et réseaux avec administration Oracle DBA
-- ============================================

-- ---------------------------------------------------------
-- PARTIE 0: CRÉATION DE LA PDB ET INITIALISATION
-- ---------------------------------------------------------

-- Connexion en tant que SYS au CDB
CONNECT sys/oracle@localhost:1521/ORCL as sysdba

SET SERVEROUTPUT ON
SET FEEDBACK ON
SET ECHO ON
SET VERIFY ON

PROMPT =======================================================
PROMPT ÉTAPE 0: Création de la PDB DIGI_NETWORK
PROMPT =======================================================

        -- Créer la PDB
        CREATE PLUGGABLE DATABASE DIGI_NETWORK
        ADMIN USER pdbadmin IDENTIFIED BY "PdbAdmin123#"
        ROLES = (DBA)
        FILE_NAME_CONVERT = ('/u01/app/oracle/oradata/ORCL/pdbseed/', 
                            '/u01/app/oracle/oradata/ORCL/DIGI_NETWORK/')
        STORAGE (MAXSIZE UNLIMITED);
        
        DBMS_OUTPUT.PUT_LINE('SUCCÈS: PDB DIGI_NETWORK créée.');
END;
/

-- Ouvrir la PDB
ALTER PLUGGABLE DATABASE DIGI_NETWORK OPEN;

-- Configurer pour ouverture automatique
ALTER PLUGGABLE DATABASE DIGI_NETWORK SAVE STATE;

-- Vérification de l'état de la PDB
PROMPT
PROMPT Vérification de l'état de la PDB...
COLUMN name FORMAT A20
COLUMN open_mode FORMAT A15
SELECT name, open_mode, restricted, total_size/1024/1024 as size_mb
FROM v$pdbs
WHERE name = 'DIGI_NETWORK';

-- Se connecter à la PDB
ALTER SESSION SET CONTAINER = DIGI_NETWORK;

PROMPT =======================================================
PROMPT ÉTAPE 1: Création des tablespaces
PROMPT =======================================================

-- Créer les tablespaces spécifiques
CREATE TABLESPACE TS_DATA_INFRA 
DATAFILE '/u01/app/oracle/oradata/ORCL/DIGI_NETWORK/data_infra01.dbf' 
SIZE 500M AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

CREATE TABLESPACE TS_INDEX_INFRA 
DATAFILE '/u01/app/oracle/oradata/ORCL/DIGI_NETWORK/index_infra01.dbf' 
SIZE 200M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

CREATE TABLESPACE TS_TEMP_INFRA 
TEMPFILE '/u01/app/oracle/oradata/ORCL/DIGI_NETWORK/temp_infra01.dbf' 
SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE 500M;

PROMPT Tablespaces créés avec succès.

-- Vérifier les tablespaces
PROMPT
PROMPT Vérification des tablespaces...
SELECT tablespace_name, file_name, 
       bytes/1024/1024 as size_mb, 
       autoextensible,
       status
FROM dba_data_files
WHERE tablespace_name LIKE '%INFRA%'
UNION ALL
SELECT tablespace_name, file_name, 
       bytes/1024/1024 as size_mb, 
       autoextensible,
       status
FROM dba_temp_files
WHERE tablespace_name LIKE '%INFRA%'
ORDER BY tablespace_name;

PROMPT =======================================================
PROMPT ÉTAPE 2: Création des utilisateurs
PROMPT =======================================================

-- Créer l'utilisateur principal de l'infrastructure
CREATE USER infra_admin IDENTIFIED BY "InfraAdmin456#"
DEFAULT TABLESPACE TS_DATA_INFRA
TEMPORARY TABLESPACE TS_TEMP_INFRA
QUOTA UNLIMITED ON TS_DATA_INFRA
QUOTA UNLIMITED ON TS_INDEX_INFRA
ACCOUNT UNLOCK;

-- Créer un utilisateur pour les connexions applicatives
CREATE USER infra_app IDENTIFIED BY "InfraApp789#"
DEFAULT TABLESPACE TS_DATA_INFRA
TEMPORARY TABLESPACE TS_TEMP_INFRA
QUOTA 100M ON TS_DATA_INFRA
QUOTA 50M ON TS_INDEX_INFRA
ACCOUNT UNLOCK;

PROMPT
PROMPT Utilisateurs créés:
PROMPT - infra_admin/InfraAdmin456#
PROMPT - infra_app/InfraApp789#

-- Accorder les privilèges à infra_admin
GRANT CREATE SESSION TO infra_admin;
GRANT CREATE TABLE TO infra_admin;
GRANT CREATE SEQUENCE TO infra_admin;
GRANT CREATE PROCEDURE TO infra_admin;
GRANT CREATE TRIGGER TO infra_admin;
GRANT CREATE VIEW TO infra_admin;
GRANT CREATE JOB TO infra_admin;
GRANT CREATE TYPE TO infra_admin;
GRANT CREATE SYNONYM TO infra_admin;
GRANT CREATE ANY DIRECTORY TO infra_admin;
GRANT DROP ANY DIRECTORY TO infra_admin;
GRANT UNLIMITED TABLESPACE TO infra_admin;

-- Accorder les rôles système
GRANT CONNECT, RESOURCE TO infra_admin;
GRANT DBA TO infra_admin;

-- Accorder les privilèges à infra_app
GRANT CREATE SESSION TO infra_app;
GRANT SELECT ANY TABLE TO infra_app;
GRANT INSERT ANY TABLE TO infra_app;
GRANT UPDATE ANY TABLE TO infra_app;
GRANT DELETE ANY TABLE TO infra_app;

PROMPT
PROMPT Vérification des utilisateurs...
SELECT username, default_tablespace, temporary_tablespace, 
       created, account_status
FROM dba_users
WHERE username IN ('INFRA_ADMIN', 'INFRA_APP', 'PDBADMIN')
ORDER BY username;

PROMPT =======================================================
PROMPT ÉTAPE 3: Connexion en tant qu'infra_admin
PROMPT =======================================================

-- Se connecter en tant qu'infra_admin
CONNECT infra_admin/InfraAdmin456#@localhost:1521/DIGI_NETWORK

-- Vérifier la connexion
SELECT USER as "Utilisateur actuel", 
       SYS_CONTEXT('USERENV', 'CON_NAME') as "PDB",
       SYS_CONTEXT('USERENV', 'DB_NAME') as "Base de données",
       TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') as "Date/heure"
FROM dual;

PROMPT =======================================================
PROMPT ÉTAPE 4: Création des tables
PROMPT =======================================================

-- Table EQUIPEMENT
PROMPT Création de la table EQUIPEMENT...
CREATE TABLE EQUIPEMENT (
    id_equipement INT PRIMARY KEY,
    nom_equipement VARCHAR2(50) NOT NULL,
    type_equipement VARCHAR2(30) CHECK (type_equipement IN ('Serveur','Switch','Routeur','Firewall','AP')),
    adresse_mac VARCHAR2(30) UNIQUE,
    emplacement VARCHAR2(50),
    date_installation DATE,
    statut VARCHAR2(20) DEFAULT 'ACTIF' CHECK (statut IN ('ACTIF', 'INACTIF', 'MAINTENANCE'))
) TABLESPACE TS_DATA_INFRA;

-- Table UTILISATEUR
PROMPT Création de la table UTILISATEUR...
CREATE TABLE UTILISATEUR (
    id_user INT PRIMARY KEY,
    nom VARCHAR2(50) NOT NULL,
    prenom VARCHAR2(50) NOT NULL,
    role VARCHAR2(20) CHECK(role IN ('Admin','Technicien','Employe')),
    telephone VARCHAR2(20) UNIQUE,
    email VARCHAR2(100) UNIQUE,
    date_creation DATE DEFAULT SYSDATE,
    statut VARCHAR2(10) DEFAULT 'ACTIF' CHECK (statut IN ('ACTIF', 'INACTIF'))
) TABLESPACE TS_DATA_INFRA;

-- Table SERVICE
PROMPT Création de la table SERVICE...
CREATE TABLE SERVICE (
    id_service INT PRIMARY KEY,
    nom_service VARCHAR2(50) UNIQUE NOT NULL,
    description VARCHAR2(200),
    criticite VARCHAR2(10) CHECK (criticite IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    port_number INT CHECK (port_number BETWEEN 1 AND 65535)
) TABLESPACE TS_DATA_INFRA;

-- Table EQUIPEMENT_SERVICE
PROMPT Création de la table EQUIPEMENT_SERVICE...
CREATE TABLE EQUIPEMENT_SERVICE (
    id_equipement INT,
    id_service INT,
    date_affectation DATE DEFAULT SYSDATE,
    port_utilise INT,
    PRIMARY KEY(id_equipement, id_service),
    CONSTRAINT fk_es_equip FOREIGN KEY (id_equipement) 
        REFERENCES EQUIPEMENT(id_equipement) ON DELETE CASCADE,
    CONSTRAINT fk_es_service FOREIGN KEY (id_service) 
        REFERENCES SERVICE(id_service) ON DELETE CASCADE
) TABLESPACE TS_DATA_INFRA;

-- Table ADRESSE_IP
PROMPT Création de la table ADRESSE_IP...
CREATE TABLE ADRESSE_IP (
    id_ip INT PRIMARY KEY,
    adresse_ip VARCHAR2(15) UNIQUE NOT NULL,
    masque VARCHAR2(15) NOT NULL,
    reseau VARCHAR2(50),
    gateway VARCHAR2(15),
    type_ip VARCHAR2(10) CHECK (type_ip IN ('STATIC', 'DHCP', 'RESERVED')),
    id_equipement INT,
    date_attribution DATE DEFAULT SYSDATE,
    CONSTRAINT fk_ip_equip FOREIGN KEY (id_equipement) 
        REFERENCES EQUIPEMENT(id_equipement) ON DELETE SET NULL
) TABLESPACE TS_DATA_INFRA;

-- Table INCIDENT
PROMPT Création de la table INCIDENT...
CREATE TABLE INCIDENT (
    id_incident INT PRIMARY KEY,
    id_equipement INT,
    id_service INT NULL,
    date_incident DATE DEFAULT SYSDATE NOT NULL,
    date_detection DATE DEFAULT SYSDATE,
    description VARCHAR2(500) NOT NULL,
    criticite VARCHAR2(10) CHECK (criticite IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    statut VARCHAR2(20) DEFAULT 'Ouvert' CHECK (statut IN ('Ouvert','En cours','Résolu','Fermé')),
    priorite VARCHAR2(10) CHECK (priorite IN ('P1','P2','P3','P4')),
    CONSTRAINT fk_incident_equip FOREIGN KEY (id_equipement) 
        REFERENCES EQUIPEMENT(id_equipement) ON DELETE CASCADE,
    CONSTRAINT fk_incident_service FOREIGN KEY (id_service) 
        REFERENCES SERVICE(id_service) ON DELETE SET NULL
) TABLESPACE TS_DATA_INFRA;

-- Table INTERVENTION
PROMPT Création de la table INTERVENTION...
CREATE TABLE INTERVENTION (
    id_intervention INT PRIMARY KEY,
    id_incident INT NOT NULL,
    id_user INT NOT NULL,
    date_debut DATE DEFAULT SYSDATE,
    date_fin DATE,
    action_realisee VARCHAR2(1000) NOT NULL,
    duree_minutes INT,
    type_intervention VARCHAR2(30) CHECK (type_intervention IN ('CORRECTIVE', 'PREVENTIVE', 'EVOLUTIVE')),
    cout_estime NUMBER(10,2),
    CONSTRAINT fk_interv_incident FOREIGN KEY (id_incident) 
        REFERENCES INCIDENT(id_incident) ON DELETE CASCADE,
    CONSTRAINT fk_interv_user FOREIGN KEY (id_user) 
        REFERENCES UTILISATEUR(id_user) ON DELETE CASCADE,
    CONSTRAINT chk_dates CHECK (date_fin IS NULL OR date_fin >= date_debut)
) TABLESPACE TS_DATA_INFRA;

-- Table SAUVEGARDE
PROMPT Création de la table SAUVEGARDE...
CREATE TABLE SAUVEGARDE (
    id_sauvegarde INT PRIMARY KEY,
    id_equipement INT,
    type_sauvegarde VARCHAR2(20) CHECK (type_sauvegarde IN ('COMPLETE', 'INCREMENTAL', 'DIFFERENTIAL')),
    date_sauvegarde DATE DEFAULT SYSDATE,
    taille_mb NUMBER(10,2),
    emplacement VARCHAR2(200),
    statut VARCHAR2(20) CHECK (statut IN ('SUCCESS', 'FAILED', 'IN PROGRESS')),
    details VARCHAR2(500),
    CONSTRAINT fk_sauv_equip FOREIGN KEY (id_equipement) 
        REFERENCES EQUIPEMENT(id_equipement) ON DELETE CASCADE
) TABLESPACE TS_DATA_INFRA;

-- Table LOG_CONNEXION
PROMPT Création de la table LOG_CONNEXION...
CREATE TABLE LOG_CONNEXION (
    log_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR2(50) NOT NULL,
    date_connexion TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    action VARCHAR2(50) NOT NULL,
    ip_address VARCHAR2(15),
    user_os VARCHAR2(50),
    programme VARCHAR2(100),
    details VARCHAR2(500)
) TABLESPACE TS_DATA_INFRA;

PROMPT
PROMPT Vérification des tables créées...
SELECT table_name, tablespace_name, num_rows, last_analyzed
FROM user_tables
ORDER BY table_name;

PROMPT =======================================================
PROMPT ÉTAPE 5: Création des index
PROMPT =======================================================

-- Index pour les recherches fréquentes
PROMPT Création des index...
CREATE INDEX idx_equip_nom ON EQUIPEMENT(nom_equipement) 
TABLESPACE TS_INDEX_INFRA;

CREATE INDEX idx_incident_date ON INCIDENT(date_incident) 
TABLESPACE TS_INDEX_INFRA;

CREATE INDEX idx_incident_statut ON INCIDENT(statut, criticite) 
TABLESPACE TS_INDEX_INFRA;

CREATE INDEX idx_intervention_user ON INTERVENTION(id_user, date_debut) 
TABLESPACE TS_INDEX_INFRA;

CREATE INDEX idx_adresse_equip ON ADRESSE_IP(id_equipement) 
TABLESPACE TS_INDEX_INFRA;

CREATE INDEX idx_log_connexion_user ON LOG_CONNEXION(username, date_connexion) 
TABLESPACE TS_INDEX_INFRA;

PROMPT
PROMPT Vérification des index créés...
SELECT index_name, table_name, uniqueness, status
FROM user_indexes
WHERE index_name LIKE 'IDX_%'
ORDER BY index_name;

PROMPT =======================================================
PROMPT ÉTAPE 6: Création des séquences
PROMPT =======================================================

PROMPT Création des séquences...
CREATE SEQUENCE seq_equipement 
START WITH 100 INCREMENT BY 1 
NOCACHE NOCYCLE;

CREATE SEQUENCE seq_utilisateur 
START WITH 10 INCREMENT BY 1 
NOCACHE NOCYCLE;

CREATE SEQUENCE seq_service 
START WITH 10 INCREMENT BY 1 
NOCACHE NOCYCLE;

CREATE SEQUENCE seq_adresse_ip 
START WITH 100 INCREMENT BY 1 
NOCACHE NOCYCLE;

CREATE SEQUENCE seq_incident 
START WITH 1000 INCREMENT BY 1 
NOCACHE NOCYCLE;

CREATE SEQUENCE seq_intervention 
START WITH 1000 INCREMENT BY 1 
NOCACHE NOCYCLE;

CREATE SEQUENCE seq_sauvegarde 
START WITH 1 INCREMENT BY 1 
NOCACHE NOCYCLE;

PROMPT
PROMPT Vérification des séquences...
SELECT sequence_name, min_value, max_value, increment_by, last_number
FROM user_sequences
ORDER BY sequence_name;

PROMPT =======================================================
PROMPT ÉTAPE 7: Insertion des données
PROMPT =======================================================

-- EQUIPEMENT
PROMPT Insertion des équipements...
INSERT INTO EQUIPEMENT VALUES(1, 'SRV-AD-PRIMARY', 'Serveur', 'AA-BB-CC-DD-11-22', 'Salle Serveurs A', DATE '2023-01-10', 'ACTIF');
INSERT INTO EQUIPEMENT VALUES(2, 'SW-CORE-01', 'Switch', '00-1A-2B-3C-4D-5E', 'Local Réseau Principal', DATE '2022-05-03', 'ACTIF');
INSERT INTO EQUIPEMENT VALUES(3, 'RT-ISP-MAIN', 'Routeur', '11-22-33-44-55-66', 'Salle Serveurs A', DATE '2021-11-20', 'ACTIF');
INSERT INTO EQUIPEMENT VALUES(4, 'FW-PALOALTO-01', 'Firewall', '99-88-77-66-55-44', 'Entrée WAN', DATE '2022-08-15', 'ACTIF');
INSERT INTO EQUIPEMENT VALUES(5, 'SRV-FILE-01', 'Serveur', 'AA-CC-DD-EE-FF-11', 'Salle Serveurs B', DATE '2023-03-15', 'ACTIF');
INSERT INTO EQUIPEMENT VALUES(6, 'AP-WIFI-FLOOR1', 'AP', 'BB-CC-DD-EE-FF-22', 'Étage 1', DATE '2023-06-20', 'ACTIF');
INSERT INTO EQUIPEMENT VALUES(7, 'SW-ACCESS-01', 'Switch', 'CC-DD-EE-FF-AA-BB', 'Local Réseau Secondaire', DATE '2023-09-10', 'MAINTENANCE');
COMMIT;

-- UTILISATEUR
PROMPT Insertion des utilisateurs...
INSERT INTO UTILISATEUR VALUES(1, 'Benali', 'Sara', 'Admin', '0611223344', 'sara.benali@entreprise.com', DATE '2022-01-15', 'ACTIF');
INSERT INTO UTILISATEUR VALUES(2, 'Hassan', 'Youssef', 'Technicien', '0677889900', 'youssef.hassan@entreprise.com', DATE '2022-03-10', 'ACTIF');
INSERT INTO UTILISATEUR VALUES(3, 'Mouad', 'Karim', 'Employe', '0655443322', 'karim.mouad@entreprise.com', DATE '2022-05-20', 'ACTIF');
INSERT INTO UTILISATEUR VALUES(4, 'Rami', 'Fatima', 'Technicien', '0622334455', 'fatima.rami@entreprise.com', DATE '2023-01-30', 'ACTIF');
INSERT INTO UTILISATEUR VALUES(5, 'Idrissi', 'Mehdi', 'Admin', '0633445566', 'mehdi.idrissi@entreprise.com', DATE '2023-07-15', 'ACTIF');
COMMIT;

-- SERVICE
PROMPT Insertion des services...
INSERT INTO SERVICE VALUES(1, 'Active Directory', 'Service d annuaire et authentification', 'CRITICAL', 389);
INSERT INTO SERVICE VALUES(2, 'DNS', 'Résolution de noms de domaine', 'HIGH', 53);
INSERT INTO SERVICE VALUES(3, 'DHCP', 'Attribution d adresses IP', 'HIGH', 67);
INSERT INTO SERVICE VALUES(4, 'VPN', 'Réseau privé virtuel', 'HIGH', 1194);
INSERT INTO SERVICE VALUES(5, 'Serveur WEB', 'Hébergement web interne', 'MEDIUM', 80);
INSERT INTO SERVICE VALUES(6, 'FTP', 'Transfert de fichiers', 'LOW', 21);
INSERT INTO SERVICE VALUES(7, 'SSH', 'Accès sécurisé distant', 'HIGH', 22);
INSERT INTO SERVICE VALUES(8, 'Monitoring', 'Supervision Nagios', 'MEDIUM', 5666);
COMMIT;

-- EQUIPEMENT_SERVICE
PROMPT Insertion des relations équipement-service...
INSERT INTO EQUIPEMENT_SERVICE VALUES(1, 1, DATE '2023-01-15', 389);
INSERT INTO EQUIPEMENT_SERVICE VALUES(1, 2, DATE '2023-01-15', 53);
INSERT INTO EQUIPEMENT_SERVICE VALUES(1, 3, DATE '2023-01-15', 67);
INSERT INTO EQUIPEMENT_SERVICE VALUES(4, 4, DATE '2022-08-20', 1194);
INSERT INTO EQUIPEMENT_SERVICE VALUES(4, 7, DATE '2022-08-20', 22);
INSERT INTO EQUIPEMENT_SERVICE VALUES(5, 6, DATE '2023-03-20', 21);
INSERT INTO EQUIPEMENT_SERVICE VALUES(5, 5, DATE '2023-03-20', 80);
INSERT INTO EQUIPEMENT_SERVICE VALUES(1, 8, DATE '2023-10-01', 5666);
COMMIT;

-- ADRESSE_IP
PROMPT Insertion des adresses IP...
INSERT INTO ADRESSE_IP VALUES(1, '192.168.1.10', '255.255.255.0', '192.168.1.0/24', '192.168.1.1', 'STATIC', 1, DATE '2023-01-10');
INSERT INTO ADRESSE_IP VALUES(2, '192.168.1.2', '255.255.255.0', '192.168.1.0/24', '192.168.1.1', 'STATIC', 2, DATE '2022-05-03');
INSERT INTO ADRESSE_IP VALUES(3, '192.168.1.1', '255.255.255.0', '192.168.1.0/24', '192.168.0.1', 'STATIC', 3, DATE '2021-11-20');
INSERT INTO ADRESSE_IP VALUES(4, '192.168.1.254', '255.255.255.0', '192.168.1.0/24', '192.168.1.1', 'STATIC', 4, DATE '2022-08-15');
INSERT INTO ADRESSE_IP VALUES(5, '192.168.1.20', '255.255.255.0', '192.168.1.0/24', '192.168.1.1', 'STATIC', 5, DATE '2023-03-15');
INSERT INTO ADRESSE_IP VALUES(6, '192.168.1.50', '255.255.255.0', '192.168.1.0/24', '192.168.1.1', 'DHCP', 6, DATE '2023-06-20');
INSERT INTO ADRESSE_IP VALUES(7, '192.168.2.10', '255.255.255.0', '192.168.2.0/24', '192.168.2.1', 'STATIC', 7, DATE '2023-09-10');
COMMIT;

-- INCIDENT
PROMPT Insertion des incidents...
INSERT INTO INCIDENT VALUES(1, 2, NULL, DATE '2025-01-12', DATE '2025-01-12 08:30', 'Switch ne répond pas au ping depuis 10 minutes', 'HIGH', 'Résolu', 'P1');
INSERT INTO INCIDENT VALUES(2, 4, 4, DATE '2025-01-18', DATE '2025-01-18 14:20', 'Firewall redémarre automatiquement toutes les 2 heures', 'MEDIUM', 'En cours', 'P2');
INSERT INTO INCIDENT VALUES(3, 1, 2, DATE '2025-02-02', DATE '2025-02-02 09:15', 'DNS ne résout pas les noms externes', 'HIGH', 'Ouvert', 'P1');
INSERT INTO INCIDENT VALUES(4, 6, NULL, DATE '2025-02-10', DATE '2025-02-10 11:45', 'Point d accès WiFi déconnecté', 'MEDIUM', 'Résolu', 'P3');
INSERT INTO INCIDENT VALUES(5, 5, 5, DATE '2025-02-15', DATE '2025-02-15 16:30', 'Serveur web lent - temps de réponse > 5s', 'LOW', 'Ouvert', 'P4');
COMMIT;

-- INTERVENTION
PROMPT Insertion des interventions...
INSERT INTO INTERVENTION VALUES(1, 1, 2, DATE '2025-01-12 08:45', DATE '2025-01-12 09:15', 'Redémarrage du switch + vérification VLAN + test des ports', 30, 'CORRECTIVE', 150.00);
INSERT INTO INTERVENTION VALUES(2, 2, 1, DATE '2025-01-18 14:30', DATE '2025-01-18 15:15', 'Mise à jour firmware Firewall + vérification règles + test débit', 45, 'CORRECTIVE', 300.00);
INSERT INTO INTERVENTION VALUES(3, 3, 2, DATE '2025-02-02 09:30', DATE '2025-02-02 09:55', 'Restart service DNS + vérification logs + flush cache', 25, 'CORRECTIVE', 125.00);
INSERT INTO INTERVENTION VALUES(4, 4, 4, DATE '2025-02-10 12:00', DATE '2025-02-10 12:25', 'Réinitialisation AP + mise à jour configuration + test couverture', 25, 'CORRECTIVE', 100.00);
INSERT INTO INTERVENTION VALUES(5, 2, 1, DATE '2025-02-20 10:00', NULL, 'Analyse logs détaillée + monitoring températures', NULL, 'PREVENTIVE', NULL);
COMMIT;

-- SAUVEGARDE
PROMPT Insertion des sauvegardes...
INSERT INTO SAUVEGARDE VALUES(1, 1, 'COMPLETE', DATE '2025-01-01', 10240.5, '/backup/srv-ad/full_20250101.bkp', 'SUCCESS', 'Sauvegarde complète mensuelle');
INSERT INTO SAUVEGARDE VALUES(2, 1, 'INCREMENTAL', DATE '2025-01-08', 512.75, '/backup/srv-ad/incr_20250108.bkp', 'SUCCESS', 'Sauvegarde incrémentielle hebdomadaire');
INSERT INTO SAUVEGARDE VALUES(3, 4, 'COMPLETE', DATE '2025-01-15', 2048.0, '/backup/fw/full_20250115.bkp', 'SUCCESS', 'Sauvegarde configuration firewall');
INSERT INTO SAUVEGARDE VALUES(4, 5, 'COMPLETE', DATE '2025-02-01', 5120.25, '/backup/filesrv/full_20250201.bkp', 'FAILED', 'Échec - espace disque insuffisant');
COMMIT;

-- LOG_CONNEXION
PROMPT Insertion des logs...
INSERT INTO LOG_CONNEXION (username, action, ip_address, user_os, programme, details) 
VALUES ('INFRA_ADMIN', 'CONNEXION', '192.168.1.100', 'oracle', 'SQL Developer', 'Connexion normale');

INSERT INTO LOG_CONNEXION (username, action, ip_address, user_os, programme, details) 
VALUES ('TECH_NETWORK', 'UPDATE', '192.168.1.101', 'linux', 'SQL*Plus', 'Mise à jour équipement ID:2');
COMMIT;

PROMPT
PROMPT Vérification des données insérées...
SELECT 'EQUIPEMENT' as TABLE_NAME, COUNT(*) as NB_LIGNES FROM EQUIPEMENT
UNION ALL
SELECT 'UTILISATEUR', COUNT(*) FROM UTILISATEUR
UNION ALL
SELECT 'SERVICE', COUNT(*) FROM SERVICE
UNION ALL
SELECT 'EQUIPEMENT_SERVICE', COUNT(*) FROM EQUIPEMENT_SERVICE
UNION ALL
SELECT 'ADRESSE_IP', COUNT(*) FROM ADRESSE_IP
UNION ALL
SELECT 'INCIDENT', COUNT(*) FROM INCIDENT
UNION ALL
SELECT 'INTERVENTION', COUNT(*) FROM INTERVENTION
UNION ALL
SELECT 'SAUVEGARDE', COUNT(*) FROM SAUVEGARDE
UNION ALL
SELECT 'LOG_CONNEXION', COUNT(*) FROM LOG_CONNEXION
ORDER BY TABLE_NAME;

PROMPT =======================================================
PROMPT ÉTAPE 8: Création des vues
PROMPT =======================================================

PROMPT Création des vues...

-- Vue: Équipements avec adresses IP
CREATE OR REPLACE VIEW V_EQUIPEMENT_IP AS
SELECT e.id_equipement, e.nom_equipement, e.type_equipement,
       a.adresse_ip, a.masque, a.reseau, e.emplacement, e.statut
FROM EQUIPEMENT e
LEFT JOIN ADRESSE_IP a ON e.id_equipement = a.id_equipement;

-- Vue: Incidents ouverts avec équipement
CREATE OR REPLACE VIEW V_INCIDENTS_OUVERTS AS
SELECT i.id_incident, i.date_incident, i.description,
       i.criticite, i.priorite, e.nom_equipement, e.type_equipement,
       u.nom || ' ' || u.prenom as assigne_a
FROM INCIDENT i
JOIN EQUIPEMENT e ON i.id_equipement = e.id_equipement
LEFT JOIN INTERVENTION iv ON i.id_incident = iv.id_incident
LEFT JOIN UTILISATEUR u ON iv.id_user = u.id_user
WHERE i.statut IN ('Ouvert', 'En cours')
ORDER BY i.criticite DESC, i.date_incident DESC;

-- Vue: Statistiques interventions par technicien
CREATE OR REPLACE VIEW V_STATS_INTERVENTIONS AS
SELECT u.id_user, u.nom || ' ' || u.prenom as technicien,
       COUNT(i.id_intervention) as nb_interventions,
       SUM(i.duree_minutes) as total_minutes,
       AVG(i.duree_minutes) as moyenne_minutes,
       MIN(i.date_debut) as premiere_intervention,
       MAX(i.date_debut) as derniere_intervention
FROM UTILISATEUR u
JOIN INTERVENTION i ON u.id_user = i.id_user
WHERE u.role = 'Technicien'
GROUP BY u.id_user, u.nom, u.prenom;

-- Vue: Équipements par service
CREATE OR REPLACE VIEW V_EQUIPEMENTS_SERVICES AS
SELECT s.nom_service, s.criticite as criticite_service,
       e.nom_equipement, e.type_equipement, e.statut as statut_equipement,
       es.date_affectation
FROM SERVICE s
JOIN EQUIPEMENT_SERVICE es ON s.id_service = es.id_service
JOIN EQUIPEMENT e ON es.id_equipement = e.id_equipement
ORDER BY s.criticite DESC, e.nom_equipement;

PROMPT
PROMPT Vérification des vues créées...
SELECT view_name, text_length, read_only
FROM user_views
ORDER BY view_name;

PROMPT =======================================================
PROMPT ÉTAPE 9: Création des procédures et fonctions
PROMPT =======================================================

PROMPT Création du package PKG_GESTION_INFRA...

-- Package de gestion des incidents
CREATE OR REPLACE PACKAGE PKG_GESTION_INFRA AS
    
    -- Déclarer un nouvel incident
    PROCEDURE declarer_incident(
        p_id_equipement IN INT,
        p_description IN VARCHAR2,
        p_criticite IN VARCHAR2 DEFAULT 'MEDIUM'
    );
    
    -- Assigner un technicien à un incident
    PROCEDURE assigner_technicien(
        p_id_incident IN INT,
        p_id_user IN INT
    );
    
    -- Fermer un incident
    PROCEDURE fermer_incident(
        p_id_incident IN INT,
        p_commentaire IN VARCHAR2
    );
    
    -- Obtenir les statistiques mensuelles
    FUNCTION obtenir_stats_mensuelles(
        p_mois IN INT DEFAULT EXTRACT(MONTH FROM SYSDATE),
        p_annee IN INT DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN SYS_REFCURSOR;
    
    -- Vérifier la criticité des équipements
    PROCEDURE verifier_criticite_equipements;
    
END PKG_GESTION_INFRA;
/

CREATE OR REPLACE PACKAGE BODY PKG_GESTION_INFRA AS
    
    PROCEDURE declarer_incident(
        p_id_equipement IN INT,
        p_description IN VARCHAR2,
        p_criticite IN VARCHAR2 DEFAULT 'MEDIUM'
    ) IS
        v_id_incident INT;
        v_priorite VARCHAR2(10);
    BEGIN
        -- Déterminer la priorité basée sur la criticité
        IF p_criticite IN ('CRITICAL', 'HIGH') THEN
            v_priorite := 'P1';
        ELSIF p_criticite = 'MEDIUM' THEN
            v_priorite := 'P2';
        ELSE
            v_priorite := 'P3';
        END IF;
        
        -- Générer nouvel ID
        SELECT seq_incident.NEXTVAL INTO v_id_incident FROM dual;
        
        -- Insérer l'incident
        INSERT INTO INCIDENT (
            id_incident, id_equipement, date_incident,
            date_detection, description, criticite,
            statut, priorite
        ) VALUES (
            v_id_incident, p_id_equipement, SYSDATE,
            SYSDATE, p_description, p_criticite,
            'Ouvert', v_priorite
        );
        
        COMMIT;
        
        -- Journaliser
        INSERT INTO LOG_CONNEXION (username, action, details)
        VALUES (USER, 'INCIDENT_CREATED', 
                'Incident ' || v_id_incident || ' créé pour équipement ' || p_id_equipement);
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Incident ' || v_id_incident || ' créé avec succès.');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Erreur création incident: ' || SQLERRM);
    END declarer_incident;
    
    PROCEDURE assigner_technicien(
        p_id_incident IN INT,
        p_id_user IN INT
    ) IS
        v_user_role VARCHAR2(20);
    BEGIN
        -- Vérifier que l'utilisateur est un technicien
        SELECT role INTO v_user_role
        FROM UTILISATEUR
        WHERE id_user = p_id_user;
        
        IF v_user_role != 'Technicien' THEN
            RAISE_APPLICATION_ERROR(-20001, 'L utilisateur doit être un technicien');
        END IF;
        
        -- Créer une intervention
        INSERT INTO INTERVENTION (
            id_intervention, id_incident, id_user,
            date_debut, action_realisee, type_intervention
        ) VALUES (
            seq_intervention.NEXTVAL, p_id_incident, p_id_user,
            SYSDATE, 'Incident assigné au technicien', 'CORRECTIVE'
        );
        
        -- Mettre à jour le statut de l'incident
        UPDATE INCIDENT
        SET statut = 'En cours'
        WHERE id_incident = p_id_incident;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Technicien assigné avec succès à l incident ' || p_id_incident);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Utilisateur non trouvé');
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Erreur assignation: ' || SQLERRM);
    END assigner_technicien;
    
    PROCEDURE fermer_incident(
        p_id_incident IN INT,
        p_commentaire IN VARCHAR2
    ) IS
    BEGIN
        UPDATE INCIDENT
        SET statut = 'Fermé',
            description = description || CHR(10) || 'Fermeture: ' || p_commentaire
        WHERE id_incident = p_id_incident;
        
        -- Fermer les interventions en cours
        UPDATE INTERVENTION
        SET date_fin = SYSDATE,
            duree_minutes = ROUND((SYSDATE - date_debut) * 24 * 60)
        WHERE id_incident = p_id_incident
        AND date_fin IS NULL;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Incident ' || p_id_incident || ' fermé.');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Erreur fermeture: ' || SQLERRM);
    END fermer_incident;
    
    FUNCTION obtenir_stats_mensuelles(
        p_mois IN INT DEFAULT EXTRACT(MONTH FROM SYSDATE),
        p_annee IN INT DEFAULT EXTRACT(YEAR FROM SYSDATE)
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT 
                EXTRACT(DAY FROM i.date_incident) as jour,
                COUNT(*) as nb_incidents,
                SUM(CASE WHEN i.criticite = 'CRITICAL' THEN 1 ELSE 0 END) as critiques,
                SUM(CASE WHEN i.criticite = 'HIGH' THEN 1 ELSE 0 END) as hauts,
                AVG(iv.duree_minutes) as duree_moyenne
            FROM INCIDENT i
            LEFT JOIN INTERVENTION iv ON i.id_incident = iv.id_incident
            WHERE EXTRACT(MONTH FROM i.date_incident) = p_mois
              AND EXTRACT(YEAR FROM i.date_incident) = p_annee
            GROUP BY EXTRACT(DAY FROM i.date_incident)
            ORDER BY jour;
            
        RETURN v_cursor;
    END;
    
    PROCEDURE verifier_criticite_equipements IS
        CURSOR c_equipements IS
            SELECT e.id_equipement, e.nom_equipement,
                   COUNT(DISTINCT s.id_service) as nb_services_critiques
            FROM EQUIPEMENT e
            JOIN EQUIPEMENT_SERVICE es ON e.id_equipement = es.id_equipement
            JOIN SERVICE s ON es.id_service = s.id_service
            WHERE s.criticite IN ('CRITICAL', 'HIGH')
              AND e.statut != 'INACTIF'
            GROUP BY e.id_equipement, e.nom_equipement
            HAVING COUNT(DISTINCT s.id_service) >= 2;
    BEGIN
        FOR rec IN c_equipements LOOP
            DBMS_OUTPUT.PUT_LINE('ALERTE: ' || rec.nom_equipement || 
                               ' a ' || rec.nb_services_critiques || 
                               ' services critiques');
        END LOOP;
    END verifier_criticite_equipements;
    
END PKG_GESTION_INFRA;
/

PROMPT
PROMPT Vérification du package créé...
SELECT object_name, object_type, status, created
FROM user_objects
WHERE object_name = 'PKG_GESTION_INFRA';

PROMPT =======================================================
PROMPT ÉTAPE 10: Création des triggers
PROMPT =======================================================

PROMPT Création des triggers...

-- Trigger pour journalisation des modifications d'équipements
CREATE OR REPLACE TRIGGER TRG_AUDIT_EQUIPEMENT
AFTER INSERT OR UPDATE OR DELETE ON EQUIPEMENT
FOR EACH ROW
DECLARE
    v_action VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        v_action := 'INSERT';
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
    ELSE
        v_action := 'DELETE';
    END IF;
    
    INSERT INTO LOG_CONNEXION (
        username, action, details
    ) VALUES (
        USER,
        'EQUIPEMENT_' || v_action,
        'ID: ' || NVL(TO_CHAR(:OLD.id_equipement), TO_CHAR(:NEW.id_equipement)) ||
        ' - Nom: ' || :OLD.nom_equipement || ' -> ' || :NEW.nom_equipement
    );
END;
/

-- Trigger pour mise à jour automatique du statut d'incident
CREATE OR REPLACE TRIGGER TRG_UPDATE_INCIDENT_STATUS
AFTER UPDATE ON INTERVENTION
FOR EACH ROW
BEGIN
    -- Si une intervention est terminée, vérifier si toutes sont terminées
    IF :NEW.date_fin IS NOT NULL THEN
        DECLARE
            v_incident_id INT := :NEW.id_incident;
            v_toutes_terminees BOOLEAN := TRUE;
        BEGIN
            -- Vérifier s'il reste des interventions ouvertes
            FOR rec IN (
                SELECT 1 FROM INTERVENTION
                WHERE id_incident = v_incident_id
                AND date_fin IS NULL
            ) LOOP
                v_toutes_terminees := FALSE;
                EXIT;
            END LOOP;
            
            -- Si toutes les interventions sont terminées, fermer l'incident
            IF v_toutes_terminees THEN
                UPDATE INCIDENT
                SET statut = 'Résolu'
                WHERE id_incident = v_incident_id
                AND statut != 'Fermé';
            END IF;
        END;
    END IF;
END;
/

-- Trigger pour empêcher la suppression d'équipement actif
CREATE OR REPLACE TRIGGER TRG_PREVENT_EQUIP_DELETE
BEFORE DELETE ON EQUIPEMENT
FOR EACH ROW
BEGIN
    IF :OLD.statut = 'ACTIF' THEN
        RAISE_APPLICATION_ERROR(-20003, 
            'Impossible de supprimer un équipement actif. Mettez-le en INACTIF d abord.');
    END IF;
END;
/

PROMPT
PROMPT Vérification des triggers créés...
SELECT trigger_name, table_name, triggering_event, status
FROM user_triggers
ORDER BY trigger_name;

PROMPT =======================================================
PROMPT ÉTAPE 11: Création des rôles et privilèges
PROMPT =======================================================

PROMPT Création des rôles applicatifs...

-- Création des rôles applicatifs
CREATE ROLE ROLE_INFRA_ADMIN;
CREATE ROLE ROLE_TECH_RESEAU;
CREATE ROLE ROLE_SUPPORT;
CREATE ROLE ROLE_CONSULT;

-- Attribution des privilèges à ROLE_INFRA_ADMIN
GRANT SELECT, INSERT, UPDATE, DELETE ON EQUIPEMENT TO ROLE_INFRA_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON UTILISATEUR TO ROLE_INFRA_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON SERVICE TO ROLE_INFRA_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON EQUIPEMENT_SERVICE TO ROLE_INFRA_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON ADRESSE_IP TO ROLE_INFRA_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON INCIDENT TO ROLE_INFRA_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON INTERVENTION TO ROLE_INFRA_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON SAUVEGARDE TO ROLE_INFRA_ADMIN;
GRANT SELECT ON LOG_CONNEXION TO ROLE_INFRA_ADMIN;
GRANT EXECUTE ON PKG_GESTION_INFRA TO ROLE_INFRA_ADMIN;

-- Attribution des privilèges à ROLE_TECH_RESEAU
GRANT SELECT, INSERT, UPDATE ON EQUIPEMENT TO ROLE_TECH_RESEAU;
GRANT SELECT ON UTILISATEUR TO ROLE_TECH_RESEAU;
GRANT SELECT ON SERVICE TO ROLE_TECH_RESEAU;
GRANT SELECT, INSERT, UPDATE ON EQUIPEMENT_SERVICE TO ROLE_TECH_RESEAU;
GRANT SELECT, INSERT, UPDATE ON ADRESSE_IP TO ROLE_TECH_RESEAU;
GRANT SELECT, INSERT, UPDATE ON INCIDENT TO ROLE_TECH_RESEAU;
GRANT SELECT, INSERT, UPDATE ON INTERVENTION TO ROLE_TECH_RESEAU;
GRANT SELECT ON SAUVEGARDE TO ROLE_TECH_RESEAU;
GRANT EXECUTE ON PKG_GESTION_INFRA TO ROLE_TECH_RESEAU;

-- Attribution des privilèges à ROLE_SUPPORT
GRANT SELECT ON EQUIPEMENT TO ROLE_SUPPORT;
GRANT SELECT ON UTILISATEUR TO ROLE_SUPPORT;
GRANT SELECT ON SERVICE TO ROLE_SUPPORT;
GRANT SELECT ON EQUIPEMENT_SERVICE TO ROLE_SUPPORT;
GRANT SELECT ON ADRESSE_IP TO ROLE_SUPPORT;
GRANT SELECT, INSERT ON INCIDENT TO ROLE_SUPPORT;
GRANT SELECT ON INTERVENTION TO ROLE_SUPPORT;

-- Attribution des privilèges à ROLE_CONSULT
GRANT SELECT ON V_EQUIPEMENT_IP TO ROLE_CONSULT;
GRANT SELECT ON V_INCIDENTS_OUVERTS TO ROLE_CONSULT;
GRANT SELECT ON V_STATS_INTERVENTIONS TO ROLE_CONSULT;
GRANT SELECT ON V_EQUIPEMENTS_SERVICES TO ROLE_CONSULT;

-- Création des utilisateurs applicatifs
PROMPT Création des utilisateurs applicatifs...

CREATE USER admin_app IDENTIFIED BY "AppAdmin789#"
DEFAULT TABLESPACE TS_DATA_INFRA
TEMPORARY TABLESPACE TS_TEMP_INFRA
QUOTA 100M ON TS_DATA_INFRA
QUOTA 50M ON TS_INDEX_INFRA
ACCOUNT UNLOCK;

CREATE USER tech_reseau IDENTIFIED BY "TechReseau123#"
DEFAULT TABLESPACE TS_DATA_INFRA
TEMPORARY TABLESPACE TS_TEMP_INFRA
QUOTA 50M ON TS_DATA_INFRA
QUOTA 25M ON TS_INDEX_INFRA
ACCOUNT UNLOCK;

CREATE USER support_user IDENTIFIED BY "Support456#"
DEFAULT TABLESPACE TS_DATA_INFRA
TEMPORARY TABLESPACE TS_TEMP_INFRA
QUOTA 20M ON TS_DATA_INFRA
QUOTA 10M ON TS_INDEX_INFRA
ACCOUNT UNLOCK;

CREATE USER consult_user IDENTIFIED BY "Consult789#"
DEFAULT TABLESPACE TS_DATA_INFRA
TEMPORARY TABLESPACE TS_TEMP_INFRA
QUOTA 10M ON TS_DATA_INFRA
QUOTA 5M ON TS_INDEX_INFRA
ACCOUNT UNLOCK;

-- Attribution des rôles aux utilisateurs
GRANT ROLE_INFRA_ADMIN TO admin_app;
GRANT ROLE_TECH_RESEAU TO tech_reseau;
GRANT ROLE_SUPPORT TO support_user;
GRANT ROLE_CONSULT TO consult_user;

-- Privilèges de base
GRANT CREATE SESSION TO admin_app, tech_reseau, support_user, consult_user;

PROMPT
PROMPT Vérification des utilisateurs créés...
SELECT username, default_tablespace, account_status, created
FROM dba_users
WHERE username LIKE '%APP' OR username LIKE '%USER'
ORDER BY username;

PROMPT =======================================================
PROMPT ÉTAPE 12: Tests et vérifications
PROMPT =======================================================

PROMPT Test 1: Vérification de la création des objets...
SELECT object_type, COUNT(*) as nombre
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

PROMPT
PROMPT Test 2: Statistiques des équipements...
SELECT type_equipement, COUNT(*) as nombre, 
       ROUND(AVG(MONTHS_BETWEEN(SYSDATE, date_installation)), 1) as age_moyen_mois
FROM EQUIPEMENT
GROUP BY type_equipement
ORDER BY nombre DESC;

PROMPT
PROMPT Test 3: Incidents par criticité...
SELECT criticite, statut, COUNT(*) as nombre,
       ROUND(AVG(duree_minutes), 1) as duree_moyenne_min
FROM INCIDENT i
LEFT JOIN INTERVENTION iv ON i.id_incident = iv.id_incident
GROUP BY criticite, statut
ORDER BY criticite DESC, statut;

PROMPT
PROMPT Test 4: Utilisation des adresses IP...
SELECT reseau, 
       COUNT(*) as total_adresses,
       COUNT(CASE WHEN id_equipement IS NOT NULL THEN 1 END) as utilisees,
       COUNT(CASE WHEN id_equipement IS NULL THEN 1 END) as disponibles,
       ROUND(COUNT(CASE WHEN id_equipement IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) as pourcentage_utilise
FROM ADRESSE_IP
GROUP BY reseau
ORDER BY reseau;

PROMPT
PROMPT Test 5: Test de la procédure de déclaration d incident...
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Déclaration d un nouvel incident ---');
    PKG_GESTION_INFRA.declarer_incident(
        p_id_equipement => 3,
        p_description => 'Test: Routeur perte de paquets',
        p_criticite => 'HIGH'
    );
    DBMS_OUTPUT.PUT_LINE('--- Incident créé avec succès ---');
END;
/

PROMPT Vérification de l incident créé...
SELECT * FROM INCIDENT 
WHERE description LIKE 'Test:%'
ORDER BY id_incident DESC;

PROMPT
PROMPT Test 6: Test des triggers...
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Test trigger d audit ---');
    UPDATE EQUIPEMENT 
    SET emplacement = 'Salle Serveurs A - Rack 2'
    WHERE id_equipement = 1;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('--- Équipement mis à jour, audit généré ---');
END;
/

PROMPT Vérification de l audit...
SELECT username, action, details, TO_CHAR(date_connexion, 'DD/MM HH24:MI:SS') as heure
FROM LOG_CONNEXION
WHERE action LIKE 'EQUIPEMENT%'
ORDER BY date_connexion DESC
FETCH FIRST 3 ROWS ONLY;

PROMPT =======================================================
PROMPT ÉTAPE 13: Résumé final
PROMPT =======================================================

-- Afficher un résumé final
PROMPT
PROMPT *******************************************************
PROMPT *** RÉSUMÉ DU DÉPLOIEMENT DIGI_NETWORK ***
PROMPT *******************************************************
PROMPT

SELECT '1. PDB créée: DIGI_NETWORK' as RESUME FROM dual
UNION ALL
SELECT '2. Tablespaces: TS_DATA_INFRA, TS_INDEX_INFRA, TS_TEMP_INFRA' FROM dual
UNION ALL
SELECT '3. Utilisateurs système: INFRA_ADMIN, INFRA_APP' FROM dual
UNION ALL
SELECT '4. Tables créées: 8 tables principales' FROM dual
UNION ALL
SELECT '5. Index créés: 6 index d optimisation' FROM dual
UNION ALL
SELECT '6. Séquences créées: 7 séquences' FROM dual
UNION ALL
SELECT '7. Vues créées: 4 vues de reporting' FROM dual
UNION ALL
SELECT '8. Package créé: PKG_GESTION_INFRA' FROM dual
UNION ALL
SELECT '9. Triggers créés: 3 triggers' FROM dual
UNION ALL
SELECT '10. Rôles créés: 4 rôles applicatifs' FROM dual
UNION ALL
SELECT '11. Utilisateurs applicatifs: 4 utilisateurs' FROM dual;

PROMPT
PROMPT *******************************************************
PROMPT *** INFORMATIONS DE CONNEXION ***
PROMPT *******************************************************
PROMPT
PROMPT Administrateur PDB:
PROMPT   sqlplus pdbadmin/PdbAdmin123#@localhost:1521/DIGI_NETWORK
PROMPT
PROMPT Administrateur application:
PROMPT   sqlplus infra_admin/InfraAdmin456#@localhost:1521/DIGI_NETWORK
PROMPT
PROMPT Utilisateurs applicatifs:
PROMPT   Admin:     sqlplus admin_app/AppAdmin789#@localhost:1521/DIGI_NETWORK
PROMPT   Technicien: sqlplus tech_reseau/TechReseau123#@localhost:1521/DIGI_NETWORK
PROMPT   Support:    sqlplus support_user/Support456#@localhost:1521/DIGI_NETWORK
PROMPT   Consultant: sqlplus consult_user/Consult789#@localhost:1521/DIGI_NETWORK
PROMPT
PROMPT *******************************************************
PROMPT *** STATISTIQUES DES DONNÉES ***
PROMPT *******************************************************
PROMPT

SELECT 'Équipements: ' || COUNT(*) as STATISTIQUE FROM EQUIPEMENT
UNION ALL
SELECT 'Utilisateurs: ' || COUNT(*) FROM UTILISATEUR
UNION ALL
SELECT 'Services: ' || COUNT(*) FROM SERVICE
UNION ALL
SELECT 'Adresses IP: ' || COUNT(*) FROM ADRESSE_IP
UNION ALL
SELECT 'Incidents: ' || COUNT(*) FROM INCIDENT
UNION ALL
SELECT 'Interventions: ' || COUNT(*) FROM INTERVENTION
UNION ALL
SELECT 'Sauvegardes: ' || COUNT(*) FROM SAUVEGARDE
UNION ALL
SELECT 'Logs connexion: ' || COUNT(*) FROM LOG_CONNEXION;

PROMPT
PROMPT *******************************************************
PROMPT *** DÉPLOIEMENT TERMINÉ AVEC SUCCÈS! ***
PROMPT *******************************************************

-- Commit final
COMMIT;

-- Afficher la date de fin
SELECT 'Script exécuté le: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') as FIN_D_EXECUTION FROM dual;
