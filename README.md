# Infra_Oracle_Project  ( DIGI_NETWORK )
Projet complet de gestion d’infrastructure Systèmes &amp; Réseaux + Oracle 19c &amp; Linux

📖 Contexte
En tant que Technicienne Spécialiste Systèmes & Réseaux et Junior Oracle DBA, j’ai travaillé sur le projet DIGI_NETWORK, visant à simuler une infrastructure IT d’entreprise. Mon rôle consistait à :

Déployer une base Oracle 19c Multitenant pour centraliser les données sur équipements, utilisateurs et services.

Automatiser le suivi des incidents, interventions et sauvegardes.

Garantir intégrité, sécurité et performance des données.

🛠️ Workflow Technique

Setup DB: Création de la PDB DIGI_NETWORK et tablespaces dédiés (ts_data_infra, ts_index_infra, ts_backup_infra)

Modélisation des données: Tables principales (EQUIPEMENT, UTILISATEUR, INCIDENT, INTERVENTION, SAUVEGARDE) avec contraintes et clés primaires/étrangères

PL/SQL & Automation: Procédures, triggers et fonctions pour automatiser la gestion et la journalisation

Bash Scripts: Monitoring système, backups RMAN et gestion des services Linux/Oracle

Sécurité & Roles: RBAC avec ROLE_ADMIN_DBA, ROLE_TECH_RESEAU, ROLE_SUPPORT et audit des actions

🏗️ Architecture

Serveur Oracle Linux 8

Oracle 19c Multitenant (CDB/PDB)

VLAN simulés : Admin / Serveurs / Support

Tablespaces optimisés pour performance et sauvegarde

📂 Résultats Clés

Infrastructure prête pour simulation IT d’entreprise

Données sécurisées et intégrité assurée grâce aux contraintes et triggers

Automatisation des backups et monitoring opérationnel

Gestion des rôles et audit fonctionnel
