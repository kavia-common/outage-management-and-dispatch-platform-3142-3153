-- MySQL dump 10.13  Distrib 8.0.44, for Linux (x86_64)
--
-- Host: localhost    Database: myapp
-- ------------------------------------------------------
-- Server version	8.0.44-0ubuntu0.24.04.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `myapp`
--

/*!40000 DROP DATABASE IF EXISTS `myapp`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `myapp` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `myapp`;

--
-- Table structure for table `crews`
--

DROP TABLE IF EXISTS `crews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `crews` (
  `id` char(36) NOT NULL,
  `organization_id` char(36) NOT NULL,
  `name` varchar(200) NOT NULL,
  `lead_user_id` char(36) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_crews_org` (`organization_id`),
  KEY `ix_crews_lead` (`lead_user_id`),
  CONSTRAINT `fk_crews_lead` FOREIGN KEY (`lead_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_crews_org` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `crews`
--

LOCK TABLES `crews` WRITE;
/*!40000 ALTER TABLE `crews` DISABLE KEYS */;
INSERT INTO `crews` VALUES ('00000000-0000-0000-0000-000000000401','00000000-0000-0000-0000-000000000001','Crew Alpha','00000000-0000-0000-0000-000000000201',1,'2026-03-25 21:09:12');
/*!40000 ALTER TABLE `crews` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_status_events`
--

DROP TABLE IF EXISTS `job_status_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_status_events` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `job_id` char(36) NOT NULL,
  `status` enum('pending','assigned','en_route','on_site','completed','cancelled') NOT NULL,
  `changed_by_user_id` char(36) DEFAULT NULL,
  `message` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_job_events_job` (`job_id`),
  KEY `ix_job_events_created` (`created_at`),
  KEY `fk_job_events_user` (`changed_by_user_id`),
  CONSTRAINT `fk_job_events_job` FOREIGN KEY (`job_id`) REFERENCES `jobs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_job_events_user` FOREIGN KEY (`changed_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_status_events`
--

LOCK TABLES `job_status_events` WRITE;
/*!40000 ALTER TABLE `job_status_events` DISABLE KEYS */;
INSERT INTO `job_status_events` VALUES (1,'00000000-0000-0000-0000-000000000701','assigned','00000000-0000-0000-0000-000000000101','Job assigned to Crew Alpha','2026-03-25 21:09:12');
/*!40000 ALTER TABLE `job_status_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jobs` (
  `id` char(36) NOT NULL,
  `organization_id` char(36) NOT NULL,
  `outage_id` char(36) NOT NULL,
  `assigned_crew_id` char(36) DEFAULT NULL,
  `assigned_to_user_id` char(36) DEFAULT NULL,
  `status` enum('pending','assigned','en_route','on_site','completed','cancelled') NOT NULL DEFAULT 'pending',
  `priority` enum('low','normal','high','urgent') NOT NULL DEFAULT 'normal',
  `notes` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_jobs_org` (`organization_id`),
  KEY `ix_jobs_outage` (`outage_id`),
  KEY `ix_jobs_status` (`status`),
  KEY `ix_jobs_crew` (`assigned_crew_id`),
  KEY `fk_jobs_user` (`assigned_to_user_id`),
  CONSTRAINT `fk_jobs_crew` FOREIGN KEY (`assigned_crew_id`) REFERENCES `crews` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_jobs_org` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_jobs_outage` FOREIGN KEY (`outage_id`) REFERENCES `outages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_jobs_user` FOREIGN KEY (`assigned_to_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
INSERT INTO `jobs` VALUES ('00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000601','00000000-0000-0000-0000-000000000401','00000000-0000-0000-0000-000000000201','assigned','high','Investigate transformer and restore service','2026-03-25 21:09:12','2026-03-25 21:09:12');
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `locations`
--

DROP TABLE IF EXISTS `locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `locations` (
  `id` char(36) NOT NULL,
  `organization_id` char(36) NOT NULL,
  `address_line1` varchar(200) NOT NULL,
  `address_line2` varchar(200) DEFAULT NULL,
  `city` varchar(120) NOT NULL,
  `state` varchar(120) DEFAULT NULL,
  `postal_code` varchar(30) DEFAULT NULL,
  `country` varchar(120) NOT NULL DEFAULT 'US',
  `latitude` decimal(9,6) DEFAULT NULL,
  `longitude` decimal(9,6) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_locations_org` (`organization_id`),
  KEY `ix_locations_latlng` (`latitude`,`longitude`),
  CONSTRAINT `fk_locations_org` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `locations`
--

LOCK TABLES `locations` WRITE;
/*!40000 ALTER TABLE `locations` DISABLE KEYS */;
INSERT INTO `locations` VALUES ('00000000-0000-0000-0000-000000000501','00000000-0000-0000-0000-000000000001','100 Main St',NULL,'Springfield','CA','90001','US',34.052235,-118.243683,'2026-03-25 21:09:12');
/*!40000 ALTER TABLE `locations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `organization_id` char(36) NOT NULL,
  `user_id` char(36) DEFAULT NULL,
  `outage_id` char(36) DEFAULT NULL,
  `job_id` char(36) DEFAULT NULL,
  `channel` enum('push','sms','email','in_app') NOT NULL DEFAULT 'in_app',
  `title` varchar(200) NOT NULL,
  `body` text NOT NULL,
  `status` enum('queued','sent','failed') NOT NULL DEFAULT 'queued',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `sent_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_notifications_org` (`organization_id`),
  KEY `ix_notifications_user` (`user_id`),
  KEY `ix_notifications_status` (`status`),
  KEY `fk_notifications_outage` (`outage_id`),
  KEY `fk_notifications_job` (`job_id`),
  CONSTRAINT `fk_notifications_job` FOREIGN KEY (`job_id`) REFERENCES `jobs` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifications_org` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_notifications_outage` FOREIGN KEY (`outage_id`) REFERENCES `outages` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,'00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000601','00000000-0000-0000-0000-000000000701','in_app','New job assigned','You have been assigned a new outage job near 100 Main St.','sent','2026-03-25 21:09:12','2026-03-25 21:09:12');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organizations`
--

DROP TABLE IF EXISTS `organizations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `organizations` (
  `id` char(36) NOT NULL,
  `name` varchar(200) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organizations`
--

LOCK TABLES `organizations` WRITE;
/*!40000 ALTER TABLE `organizations` DISABLE KEYS */;
INSERT INTO `organizations` VALUES ('00000000-0000-0000-0000-000000000001','Demo Utility','2026-03-25 21:09:12');
/*!40000 ALTER TABLE `organizations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `outage_updates`
--

DROP TABLE IF EXISTS `outage_updates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `outage_updates` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `outage_id` char(36) NOT NULL,
  `update_type` enum('note','status_change','system') NOT NULL DEFAULT 'note',
  `message` text NOT NULL,
  `created_by_user_id` char(36) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_outage_updates_outage` (`outage_id`),
  KEY `ix_outage_updates_created` (`created_at`),
  KEY `fk_outage_updates_user` (`created_by_user_id`),
  CONSTRAINT `fk_outage_updates_outage` FOREIGN KEY (`outage_id`) REFERENCES `outages` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_outage_updates_user` FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `outage_updates`
--

LOCK TABLES `outage_updates` WRITE;
/*!40000 ALTER TABLE `outage_updates` DISABLE KEYS */;
INSERT INTO `outage_updates` VALUES (1,'00000000-0000-0000-0000-000000000601','note','Outage logged via call center intake','00000000-0000-0000-0000-000000000101','2026-03-25 21:09:12');
/*!40000 ALTER TABLE `outage_updates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `outages`
--

DROP TABLE IF EXISTS `outages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `outages` (
  `id` char(36) NOT NULL,
  `organization_id` char(36) NOT NULL,
  `reported_by_user_id` char(36) DEFAULT NULL,
  `customer_user_id` char(36) DEFAULT NULL,
  `location_id` char(36) NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text,
  `severity` enum('low','medium','high','critical') NOT NULL DEFAULT 'medium',
  `status` enum('new','triaged','dispatched','in_progress','resolved','cancelled') NOT NULL DEFAULT 'new',
  `started_at` datetime DEFAULT NULL,
  `resolved_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_outages_org` (`organization_id`),
  KEY `ix_outages_status` (`status`),
  KEY `ix_outages_location` (`location_id`),
  KEY `fk_outages_reporter` (`reported_by_user_id`),
  KEY `fk_outages_customer` (`customer_user_id`),
  CONSTRAINT `fk_outages_customer` FOREIGN KEY (`customer_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_outages_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_outages_org` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_outages_reporter` FOREIGN KEY (`reported_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `outages`
--

LOCK TABLES `outages` WRITE;
/*!40000 ALTER TABLE `outages` DISABLE KEYS */;
INSERT INTO `outages` VALUES ('00000000-0000-0000-0000-000000000601','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000301','00000000-0000-0000-0000-000000000501','Transformer outage near Main St','Customer reported power loss in area','high','new','2026-03-25 21:09:12',NULL,'2026-03-25 21:09:12','2026-03-25 21:09:12');
/*!40000 ALTER TABLE `outages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` char(36) NOT NULL,
  `organization_id` char(36) NOT NULL,
  `email` varchar(320) NOT NULL,
  `full_name` varchar(200) NOT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `role` enum('operator','crew','customer','admin') NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_org_email` (`organization_id`,`email`),
  KEY `ix_users_org` (`organization_id`),
  CONSTRAINT `fk_users_org` FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000001','operator@demo.local','Demo Operator',NULL,'operator',1,'2026-03-25 21:09:12'),('00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000001','crew1@demo.local','Crew Member One',NULL,'crew',1,'2026-03-25 21:09:12'),('00000000-0000-0000-0000-000000000301','00000000-0000-0000-0000-000000000001','customer1@demo.local','Demo Customer',NULL,'customer',1,'2026-03-25 21:09:12');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'myapp'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-25 21:09:13
