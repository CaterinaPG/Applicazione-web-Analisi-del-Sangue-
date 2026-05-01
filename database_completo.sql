-- MySQL dump 10.13  Distrib 9.5.0, for macos15 (x86_64)
--
-- Host: localhost    Database: analisi_sanguigne
-- ------------------------------------------------------
-- Server version	9.5.0

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
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ 'c5783fc2-cedb-11f0-8a63-3c429a3b5c1a:1-348';

--
-- Table structure for table `biomarkers`
--

DROP TABLE IF EXISTS `biomarkers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `biomarkers` (
  `biomarker_id` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) NOT NULL,
  `unita_misura` varchar(100) NOT NULL,
  PRIMARY KEY (`biomarker_id`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `biomarkers`
--

LOCK TABLES `biomarkers` WRITE;
/*!40000 ALTER TABLE `biomarkers` DISABLE KEYS */;
INSERT INTO `biomarkers` VALUES (1,'Globuli Rossi (RBC)','10^6/uL'),(2,'Emoglobina (Hb)','g/dL'),(3,'Ematocrito (Ht)','%'),(4,'Volume Corpuscolare Medio (MCV)','fL'),(5,'Contenuto Medio di Hb (MCH)','pg'),(6,'Conc. Media di Hb (MCHC)','g/dL'),(7,'Ampiezza Distribuzione RBC (RDW)','%'),(8,'Globuli Bianchi (WBC)','10^3/uL'),(9,'Neutrofili (%)','%'),(10,'Neutrofili (Valore Assoluto)','10^3/uL'),(11,'Linfociti (%)','%'),(12,'Linfociti (Valore Assoluto)','10^3/uL'),(13,'Monociti (%)','%'),(14,'Monociti (Valore Assoluto)','10^3/uL'),(15,'Eosinofili (%)','%'),(16,'Eosinofili (Valore Assoluto)','10^3/uL'),(17,'Basofili (%)','%'),(18,'Basofili (Valore Assoluto)','10^3/uL'),(19,'Piastrine (PLT)','10^3/uL'),(20,'Glicemia','mg/dL'),(21,'Emoglobina Glicata','mmol/mol'),(22,'Colesterolo Totale','mg/dL'),(23,'Colesterolo LDL','mg/dL'),(24,'Colesterolo HDL','mg/dL'),(25,'Trigliceridi','mg/dL'),(26,'PCR (Proteina C Reattiva)','mg/L'),(27,'Sideremia','ug/dL'),(28,'Ferritina','ng/mL');
/*!40000 ALTER TABLE `biomarkers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `references_ranges`
--

DROP TABLE IF EXISTS `references_ranges`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `references_ranges` (
  `range_id` int NOT NULL AUTO_INCREMENT,
  `biomarker_id` int DEFAULT NULL,
  `sesso` enum('M','F') NOT NULL,
  `eta_min` int DEFAULT '0',
  `eta_max` int DEFAULT '120',
  `valore_min` decimal(10,2) DEFAULT NULL,
  `valore_max` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`range_id`),
  KEY `biomarker_id` (`biomarker_id`),
  CONSTRAINT `references_ranges_ibfk_1` FOREIGN KEY (`biomarker_id`) REFERENCES `biomarkers` (`biomarker_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=77 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `references_ranges`
--

LOCK TABLES `references_ranges` WRITE;
/*!40000 ALTER TABLE `references_ranges` DISABLE KEYS */;
INSERT INTO `references_ranges` VALUES (1,1,'M',18,120,4.50,5.90),(2,1,'F',18,120,4.10,5.10),(3,2,'M',18,120,14.00,17.50),(4,2,'F',18,120,12.30,15.30),(5,3,'M',18,120,41.50,50.40),(6,3,'F',18,120,35.90,44.60),(7,4,'M',18,120,80.00,100.00),(8,4,'F',18,120,80.00,100.00),(9,5,'M',18,120,27.00,33.00),(10,5,'F',18,120,27.00,33.00),(11,6,'M',18,120,32.00,36.00),(12,6,'F',18,120,32.00,36.00),(13,7,'M',18,120,11.50,14.50),(14,7,'F',18,120,11.50,14.50),(15,8,'M',18,120,4.50,11.00),(16,8,'F',18,120,4.50,11.00),(17,9,'M',18,120,40.00,75.00),(18,9,'F',18,120,40.00,75.00),(19,10,'M',18,120,1.80,7.50),(20,10,'F',18,120,1.80,7.50),(21,11,'M',18,120,20.00,45.00),(22,11,'F',18,120,20.00,45.00),(23,12,'M',18,120,1.00,4.50),(24,12,'F',18,120,1.00,4.50),(25,13,'M',18,120,2.00,10.00),(26,13,'F',18,120,2.00,10.00),(27,14,'M',18,120,0.10,1.00),(28,14,'F',18,120,0.10,1.00),(29,15,'M',18,120,1.00,6.00),(30,15,'F',18,120,1.00,6.00),(31,16,'M',18,120,0.00,0.40),(32,16,'F',18,120,0.00,0.40),(33,17,'M',18,120,0.00,1.00),(34,17,'F',18,120,0.00,1.00),(35,18,'M',18,120,0.00,0.10),(36,18,'F',18,120,0.00,0.10),(37,19,'M',18,120,150.00,450.00),(38,19,'F',18,120,150.00,450.00),(39,20,'M',18,120,70.00,100.00),(40,20,'F',18,120,70.00,100.00),(41,21,'M',18,120,20.00,42.00),(42,21,'F',18,120,20.00,42.00),(43,22,'M',18,120,120.00,200.00),(44,22,'F',18,120,120.00,200.00),(45,23,'M',18,120,0.00,130.00),(46,23,'F',18,120,0.00,130.00),(47,24,'M',18,120,40.00,100.00),(48,24,'F',18,120,50.00,100.00),(49,25,'M',18,120,40.00,150.00),(50,25,'F',18,120,40.00,150.00),(51,26,'M',18,120,0.00,5.00),(52,26,'F',18,120,0.00,5.00),(53,27,'M',18,120,60.00,160.00),(54,27,'F',18,120,60.00,160.00),(55,28,'M',18,120,20.00,250.00),(56,28,'F',18,120,10.00,120.00),(57,1,'M',0,17,4.00,5.20),(58,1,'F',0,17,4.00,5.20),(59,2,'M',0,17,11.50,15.50),(60,2,'F',0,17,11.50,15.50),(61,8,'M',0,17,5.00,15.00),(62,8,'F',0,17,5.00,15.00),(63,19,'M',0,17,150.00,450.00),(64,19,'F',0,17,150.00,450.00),(65,20,'M',0,17,60.00,100.00),(66,20,'F',0,17,60.00,100.00),(67,22,'M',0,17,120.00,170.00),(68,22,'F',0,17,120.00,170.00),(69,23,'M',0,17,0.00,110.00),(70,23,'F',0,17,0.00,110.00),(71,25,'M',0,17,30.00,100.00),(72,25,'F',0,17,30.00,100.00),(73,27,'M',0,17,50.00,120.00),(74,27,'F',0,17,50.00,120.00),(75,28,'M',0,17,10.00,100.00),(76,28,'F',0,17,10.00,100.00);
/*!40000 ALTER TABLE `references_ranges` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `test_results`
--

DROP TABLE IF EXISTS `test_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_results` (
  `result_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `biomarker_id` int DEFAULT NULL,
  `valore_misurato` decimal(10,2) NOT NULL,
  `data_test` date NOT NULL,
  PRIMARY KEY (`result_id`),
  KEY `user_id` (`user_id`),
  KEY `biomarker_id` (`biomarker_id`),
  CONSTRAINT `test_results_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `test_results_ibfk_2` FOREIGN KEY (`biomarker_id`) REFERENCES `biomarkers` (`biomarker_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `test_results`
--

LOCK TABLES `test_results` WRITE;
/*!40000 ALTER TABLE `test_results` DISABLE KEYS */;
INSERT INTO `test_results` VALUES (1,1,20,110.00,'2026-03-16');
/*!40000 ALTER TABLE `test_results` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(200) NOT NULL,
  `password_hash` varchar(200) NOT NULL,
  `nome` varchar(100) DEFAULT NULL,
  `cognome` varchar(100) DEFAULT NULL,
  `data_nascita` date NOT NULL,
  `sesso` enum('M','F') NOT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'bambino@test.com','hash123','Luca','Verdi','2016-01-01','M');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-30 11:44:37
