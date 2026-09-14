-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Sep 14, 2026 at 12:05 PM
-- Server version: 11.8.9-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u456796838_pwestora`
--

-- --------------------------------------------------------

--
-- Table structure for table `applications`
--

CREATE TABLE `applications` (
  `id` int(11) NOT NULL,
  `property_id` int(11) NOT NULL,
  `lessor_id` int(11) NOT NULL,
  `lessee_id` int(11) DEFAULT NULL,
  `tenant_name` varchar(150) NOT NULL,
  `business_name` varchar(150) DEFAULT NULL,
  `term_months` int(11) NOT NULL,
  `rent` decimal(12,2) NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `submitted_at` datetime NOT NULL DEFAULT current_timestamp(),
  `checklist_negotiation` longtext DEFAULT NULL,
  `lessor_rebuttal` text DEFAULT NULL,
  `rebuttal_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `applications`
--

INSERT INTO `applications` (`id`, `property_id`, `lessor_id`, `lessee_id`, `tenant_name`, `business_name`, `term_months`, `rent`, `status`, `submitted_at`, `checklist_negotiation`, `lessor_rebuttal`, `rebuttal_at`) VALUES
(1, 1, 2, 3, 'jm', 'vv', 8, 508.00, 'approved', '2026-08-21 09:32:50', NULL, NULL, NULL),
(2, 1, 2, 3, 'jm', 'h j hh', 80, 80.00, 'approved', '2026-08-21 10:02:07', NULL, NULL, NULL),
(3, 1, 2, 7, 'glenn', 'glenn', 12, 2000.00, 'approved', '2026-08-27 01:03:44', NULL, NULL, NULL),
(4, 1, 2, 9, 'Chris Daniel Acot', 'Kapegaduhon', 24, 7000.00, 'rejected', '2026-09-06 14:15:34', NULL, NULL, NULL),
(5, 1, 2, 10, 'Daniel Pastor', 'Angels Hotdog', 24, 7000.00, 'approved', '2026-09-06 15:01:39', NULL, NULL, NULL),
(6, 1, 2, 12, 'Jake Peralta', 'BabyCakes', 12, 2500.00, 'approved', '2026-09-07 10:01:14', NULL, NULL, NULL),
(7, 1, 2, 17, 'Charmain Acot', 'MangJuan Store', 12, 4500.00, 'rejected', '2026-09-14 11:25:32', NULL, NULL, NULL),
(8, 1, 2, 17, 'Charmain Acot', 'Perfume Treats', 12, 1500.00, 'pending', '2026-09-14 12:03:45', '{\"security_deposit\":{\"agreed\":false,\"rebuttal_note\":\"Is it ok that I will pay 1 month rent? becuase this is beyond my cost and my budget is limited. I hope you will understand, Thankyou.\"},\"rent_escalation\":{\"agreed\":true,\"rebuttal_note\":null},\"lease_term\":{\"agreed\":true,\"rebuttal_note\":null},\"use_of_premises\":{\"agreed\":true,\"rebuttal_note\":null},\"maintenance\":{\"agreed\":true,\"rebuttal_note\":null},\"subleasing\":{\"agreed\":true,\"rebuttal_note\":null},\"termination_notice\":{\"agreed\":true,\"rebuttal_note\":null},\"insurance_compliance\":{\"agreed\":true,\"rebuttal_note\":null}}', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `audit_logs`
--

CREATE TABLE `audit_logs` (
  `id` int(11) NOT NULL,
  `actor_id` int(11) DEFAULT NULL,
  `action` varchar(150) NOT NULL,
  `details` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_logs`
--

INSERT INTO `audit_logs` (`id`, `actor_id`, `action`, `details`, `created_at`) VALUES
(1, 1, 'login', '', '2026-08-21 02:23:42'),
(2, 2, 'register', 'New lessor: Secret', '2026-08-21 02:32:16'),
(3, 1, 'login', '', '2026-08-21 02:32:42'),
(4, 1, 'Approved lessor verification', 'Lessor #2', '2026-08-21 02:33:07'),
(5, 2, 'login', '', '2026-08-21 02:33:40'),
(6, 1, 'login', '', '2026-08-21 02:49:24'),
(7, 2, 'login', '', '2026-08-21 02:50:32'),
(8, 2, 'Submitted property for verification', 'pwestora', '2026-08-21 02:59:19'),
(9, 1, 'login', '', '2026-08-21 02:59:24'),
(10, 1, 'Approved property verification', 'Property #1', '2026-08-21 03:00:01'),
(11, 2, 'login', '', '2026-08-21 03:01:00'),
(12, 1, 'login', '', '2026-08-21 03:05:56'),
(13, 1, 'login', '', '2026-08-21 06:08:33'),
(14, 1, 'login', '', '2026-08-21 06:23:59'),
(15, 2, 'login', '', '2026-08-21 06:24:20'),
(16, 2, 'login', '', '2026-08-21 06:25:29'),
(17, 1, 'login', '', '2026-08-21 06:26:23'),
(18, 2, 'login', '', '2026-08-21 06:29:58'),
(19, 1, 'login', '', '2026-08-21 07:15:23'),
(20, 2, 'login', '', '2026-08-21 07:15:40'),
(21, 2, 'login', '', '2026-08-21 07:20:43'),
(22, 1, 'login', '', '2026-08-21 07:29:06'),
(23, 2, 'login', '', '2026-08-21 07:34:31'),
(24, 1, 'login', '', '2026-08-21 07:38:17'),
(25, 1, 'Suspended user', 'jmantinola54@gmail.com', '2026-08-21 07:38:43'),
(26, 2, 'login', '', '2026-08-21 07:39:04'),
(27, 2, 'login', '', '2026-08-21 07:39:33'),
(28, 1, 'login', '', '2026-08-21 07:39:48'),
(29, 1, 'Active user', 'jmantinola54@gmail.com', '2026-08-21 07:39:51'),
(30, 2, 'login', '', '2026-08-21 07:40:03'),
(31, 1, 'login', '', '2026-08-21 07:42:14'),
(32, 1, 'Sent lessor notice', 'Compliance Notice to 1 lessor(s)', '2026-08-21 07:42:35'),
(33, 2, 'login', '', '2026-08-21 07:44:04'),
(34, 2, 'login', '', '2026-08-21 07:47:49'),
(35, 1, 'login', '', '2026-08-21 07:49:02'),
(36, 1, 'Sent lessor notice', 'Policy Update to 1 lessor(s)', '2026-08-21 07:49:31'),
(37, 2, 'login', '', '2026-08-21 07:49:58'),
(38, 1, 'login', '', '2026-08-21 08:04:11'),
(39, 3, 'Lessee registered via app', 'jm@gmail.com', '2026-08-21 09:27:25'),
(40, 2, 'login', '', '2026-08-21 09:33:10'),
(41, 2, 'Approved application', 'jm', '2026-08-21 09:33:24'),
(42, 2, 'Approved application', 'jm', '2026-08-21 10:02:16'),
(43, 2, 'Advanced maintenance ticket', 'hhh → Under Review', '2026-08-21 10:18:08'),
(44, 2, 'Advanced maintenance ticket', 'hhh → Approved', '2026-08-21 10:18:48'),
(45, 2, 'Advanced maintenance ticket', 'hhh → Contractor Assigned', '2026-08-21 10:44:30'),
(46, 2, 'Advanced maintenance ticket', 'hhh → Scheduled', '2026-08-21 10:44:33'),
(47, 2, 'Advanced maintenance ticket', 'hhh → In Progress', '2026-08-21 10:44:40'),
(48, 2, 'Advanced maintenance ticket', 'hhh → Inspection', '2026-08-21 10:44:45'),
(49, 4, 'register', 'New lessor: gwapo ako', '2026-08-21 14:16:11'),
(50, 4, 'login', '', '2026-08-21 14:16:23'),
(51, 5, 'Lessee registered via app', 'glenn@gmail.com', '2026-08-21 22:11:11'),
(52, 2, 'Issued violation', 'Late Operating Hours — strike 1', '2026-08-22 04:39:09'),
(53, 2, 'Logged rent payment', '₱1000 via Cash', '2026-08-22 04:54:21'),
(54, 2, 'Logged rent payment', '₱1000 via Cash', '2026-08-22 04:54:44'),
(55, 2, 'Issued violation', 'Late Operating Hours — strike 2', '2026-08-22 05:06:46'),
(56, 4, 'login', '', '2026-08-22 06:11:34'),
(57, 1, 'login', '', '2026-08-22 06:14:13'),
(58, 1, 'Approved lessor verification', 'Lessor #4', '2026-08-22 06:14:27'),
(59, 1, 'Suspended user', 'jmantinola54@gmail.com', '2026-08-22 06:14:35'),
(60, 1, 'Active user', 'jmantinola54@gmail.com', '2026-08-22 06:14:37'),
(61, 1, 'login', '', '2026-08-23 06:52:28'),
(62, 2, 'login (OTP verified)', '', '2026-08-23 07:04:55'),
(63, 6, 'register', 'New lessor: Sample', '2026-08-23 07:20:22'),
(64, 1, 'login (OTP verified)', '', '2026-08-23 07:52:00'),
(65, 1, 'Approved lessor verification', 'Lessor #6', '2026-08-23 07:52:15'),
(66, 6, 'login (OTP verified)', '', '2026-08-23 07:55:09'),
(67, 2, 'login (OTP verified)', '', '2026-08-23 07:59:41'),
(68, 1, 'login (OTP verified)', '', '2026-08-23 08:50:49'),
(69, 2, 'login (OTP verified)', '', '2026-08-23 08:58:02'),
(70, 4, 'login (OTP verified)', '', '2026-08-23 13:57:24'),
(71, 4, 'login (OTP verified)', '', '2026-08-23 14:04:18'),
(72, 2, 'login', '', '2026-08-25 04:43:31'),
(73, 1, 'login', '', '2026-08-25 07:42:56'),
(74, 1, 'login', '', '2026-08-25 07:54:33'),
(75, 1, 'login', '', '2026-08-25 07:59:44'),
(76, 2, 'login', '', '2026-08-25 08:00:00'),
(77, 1, 'login', '', '2026-08-25 08:06:35'),
(78, 2, 'login', '', '2026-08-25 08:11:18'),
(79, 2, 'Advanced maintenance ticket', 'hhh → Completed', '2026-08-25 08:11:50'),
(80, 4, 'login', '', '2026-08-25 11:55:47'),
(81, 2, 'login', '', '2026-08-25 12:32:12'),
(82, 4, 'login', '', '2026-08-25 12:35:19'),
(83, 4, 'login', '', '2026-08-26 00:14:09'),
(84, 1, 'login', '', '2026-08-27 00:34:01'),
(85, 2, 'login', '', '2026-08-27 00:34:27'),
(86, 7, 'Lessee registered via app', 'witness.22.15@gmail.com', '2026-08-27 01:01:54'),
(87, 2, 'login', '', '2026-08-27 01:04:15'),
(88, 2, 'Approved application', 'glenn', '2026-08-27 01:04:28'),
(89, 2, 'login', '', '2026-08-27 01:22:10'),
(90, 8, 'Lessee registered via app', 'paolopastorcot305@gmail.com', '2026-08-27 01:36:11'),
(91, 2, 'login', '', '2026-08-27 09:49:01'),
(92, 2, 'login', '', '2026-08-29 01:15:42'),
(93, 4, 'login', '', '2026-09-03 03:51:11'),
(94, 4, 'login', '', '2026-09-03 17:58:22'),
(95, 9, 'Lessee registered via app', 'chrisdanielacot5226@gmail.com', '2026-09-06 14:14:42'),
(96, 10, 'Lessee registered via app', 'chrisdaniel305@gmail.com', '2026-09-06 14:56:32'),
(97, 1, 'login', '', '2026-09-06 14:58:28'),
(98, 2, 'login', '', '2026-09-06 15:00:32'),
(99, 2, 'Approved application', 'Daniel Pastor', '2026-09-06 15:01:51'),
(100, 11, 'Lessee registered via app', 'it.prolifemanagement@gmail.com', '2026-09-07 05:34:38'),
(101, 2, 'login', '', '2026-09-07 06:09:36'),
(102, 4, 'login', '', '2026-09-07 06:10:09'),
(103, 12, 'Lessee registered via app', 'jakeperalta@gmail.com', '2026-09-07 10:00:21'),
(104, 2, 'login', '', '2026-09-07 10:02:51'),
(105, 2, 'Approved application', 'Jake Peralta', '2026-09-07 10:03:01'),
(106, 13, 'Lessee registered via app', 'johnsazon@gmail.com', '2026-09-07 13:48:40'),
(107, 2, 'login', '', '2026-09-08 00:45:50'),
(108, 1, 'login', '', '2026-09-08 00:56:29'),
(109, 14, 'Lessee registered via app', 'holt@gmail.com', '2026-09-12 04:33:22'),
(110, 1, 'login', '', '2026-09-12 04:34:22'),
(111, 2, 'login', '', '2026-09-12 04:37:28'),
(112, 2, 'Rejected application', 'Chris Daniel Acot', '2026-09-12 04:37:49'),
(113, 15, 'register', 'New lessor: KapeNagus2', '2026-09-12 04:46:52'),
(114, 16, 'register', 'New lessor: KapeNagus2', '2026-09-12 04:47:34'),
(115, 16, 'login (OTP verified)', '', '2026-09-12 04:48:02'),
(116, 1, 'login', '', '2026-09-12 04:48:15'),
(117, 1, 'Rejected lessor verification', 'Lessor #15', '2026-09-12 04:48:38'),
(118, 1, 'Approved lessor verification', 'Lessor #16', '2026-09-12 04:48:44'),
(119, 16, 'login', '', '2026-09-12 04:49:00'),
(120, 16, 'Submitted property for verification', 'KapeNagus2', '2026-09-12 04:51:13'),
(121, 1, 'Approved property verification', 'Property #2', '2026-09-12 04:51:51'),
(122, 1, 'login', '', '2026-09-13 03:17:15'),
(123, 1, 'Suspended user', 'paolopastoracot305@gmail.com', '2026-09-13 03:17:22'),
(124, 17, 'Lessee registered via app', 'charmaine@gmail.com', '2026-09-14 11:12:40'),
(125, 2, 'login', '', '2026-09-14 11:19:22'),
(126, 1, 'login', '', '2026-09-14 11:20:00'),
(127, 2, 'Rejected application', 'Charmain Acot', '2026-09-14 12:02:18');

-- --------------------------------------------------------

--
-- Table structure for table `deposits`
--

CREATE TABLE `deposits` (
  `id` int(11) NOT NULL,
  `lessor_id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `status` enum('locked','released') NOT NULL DEFAULT 'locked',
  `note` varchar(255) DEFAULT NULL,
  `released_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `disputes`
--

CREATE TABLE `disputes` (
  `id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `lessor_id` int(11) NOT NULL,
  `type` varchar(150) NOT NULL,
  `status` enum('open','resolved') NOT NULL DEFAULT 'open',
  `filed_at` datetime NOT NULL DEFAULT current_timestamp(),
  `resolved_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `installment_requests`
--

CREATE TABLE `installment_requests` (
  `id` int(11) NOT NULL,
  `lessor_id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `plan_label` varchar(60) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lease_checklist_acknowledgments`
--

CREATE TABLE `lease_checklist_acknowledgments` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `item_key` varchar(60) NOT NULL,
  `acknowledged_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `lease_checklist_acknowledgments`
--

INSERT INTO `lease_checklist_acknowledgments` (`id`, `user_id`, `item_key`, `acknowledged_at`) VALUES
(1, 7, 'security_deposit', '2026-08-27 01:03:04'),
(2, 7, 'rent_escalation', '2026-08-27 01:03:04'),
(3, 7, 'use_of_premises', '2026-08-27 01:03:04'),
(4, 7, 'maintenance_responsibility', '2026-08-27 01:03:04'),
(5, 7, 'no_sublease', '2026-08-27 01:03:04'),
(6, 7, 'termination_notice', '2026-08-27 01:03:04'),
(7, 7, 'insurance', '2026-08-27 01:03:04'),
(8, 7, 'compliance', '2026-08-27 01:03:04');

-- --------------------------------------------------------

--
-- Table structure for table `lessor_profiles`
--

CREATE TABLE `lessor_profiles` (
  `user_id` int(11) NOT NULL,
  `business_permit_path` varchar(255) DEFAULT NULL,
  `sec_dti_path` varchar(255) DEFAULT NULL,
  `bir_cert_path` varchar(255) DEFAULT NULL,
  `land_title_path` varchar(255) DEFAULT NULL,
  `gov_id_path` varchar(255) DEFAULT NULL,
  `bank_account` varchar(150) DEFAULT NULL,
  `verified_by` int(11) DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `lessor_profiles`
--

INSERT INTO `lessor_profiles` (`user_id`, `business_permit_path`, `sec_dti_path`, `bir_cert_path`, `land_title_path`, `gov_id_path`, `bank_account`, `verified_by`, `verified_at`) VALUES
(2, NULL, NULL, NULL, NULL, NULL, NULL, 1, '2026-08-21 02:33:07'),
(4, 'uploads/verification/4/business_permit_77f52372.png', 'uploads/verification/4/sec_dti_ac9c0fb6.png', 'uploads/verification/4/bir_cert_055d3d64.png', 'uploads/verification/4/land_title_191e3c3f.png', 'uploads/verification/4/gov_id_8b50f31c.png', NULL, 1, '2026-08-22 06:14:27'),
(6, 'uploads/verification/6/business_permit_b9265cfc.jpg', 'uploads/verification/6/sec_dti_14341017.jpg', 'uploads/verification/6/bir_cert_a60de5f8.jpg', 'uploads/verification/6/land_title_f401abd3.png', 'uploads/verification/6/gov_id_9e8bc6e2.jpg', NULL, 1, '2026-08-23 07:52:15'),
(15, 'uploads/verification/15/business_permit_0b56f651.png', 'uploads/verification/15/sec_dti_678bd95e.jpg', 'uploads/verification/15/bir_cert_c520aa1d.jpg', 'uploads/verification/15/land_title_99c453c1.jpg', 'uploads/verification/15/gov_id_324dd8fa.jpg', NULL, NULL, NULL),
(16, 'uploads/verification/16/business_permit_fe7debcf.jpeg', 'uploads/verification/16/sec_dti_603b0e05.png', 'uploads/verification/16/bir_cert_c9790144.jpg', 'uploads/verification/16/land_title_f847dc24.png', 'uploads/verification/16/gov_id_c99b6252.jpeg', NULL, 1, '2026-09-12 04:48:44');

-- --------------------------------------------------------

--
-- Table structure for table `maintenance_tickets`
--

CREATE TABLE `maintenance_tickets` (
  `id` int(11) NOT NULL,
  `lessor_id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `category` varchar(40) NOT NULL,
  `priority` enum('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
  `title` varchar(255) NOT NULL,
  `stage` tinyint(4) NOT NULL DEFAULT 0,
  `contractor` varchar(150) DEFAULT NULL,
  `sla_due_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `maintenance_tickets`
--

INSERT INTO `maintenance_tickets` (`id`, `lessor_id`, `tenant_id`, `category`, `priority`, `title`, `stage`, `contractor`, `sla_due_at`, `created_at`) VALUES
(1, 2, 2, 'plumbing', 'medium', 'hhh', 7, NULL, NULL, '2026-08-21 10:17:48');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` int(11) NOT NULL,
  `thread_id` int(11) NOT NULL,
  `sender` enum('lessor','tenant') NOT NULL,
  `notice_type` varchar(60) DEFAULT NULL,
  `body` text NOT NULL,
  `sent_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `thread_id`, `sender`, `notice_type`, `body`, `sent_at`) VALUES
(1, 1, 'tenant', NULL, 'Hey', '2026-08-22 05:06:33'),
(2, 1, 'lessor', NULL, 'gahod', '2026-08-22 05:07:09'),
(3, 2, 'lessor', NULL, 'hello', '2026-09-07 10:04:20'),
(4, 1, 'tenant', NULL, 'Sabad simo glenn', '2026-09-08 00:51:54'),
(5, 1, 'lessor', NULL, 'gwapo ko', '2026-09-08 00:51:58'),
(6, 1, 'lessor', NULL, 'gwapo ko', '2026-09-08 00:52:07'),
(7, 2, 'tenant', NULL, 'boss musta', '2026-09-14 10:54:17');

-- --------------------------------------------------------

--
-- Table structure for table `message_threads`
--

CREATE TABLE `message_threads` (
  `id` int(11) NOT NULL,
  `lessor_id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `message_threads`
--

INSERT INTO `message_threads` (`id`, `lessor_id`, `tenant_id`) VALUES
(1, 2, 2),
(2, 2, 5);

-- --------------------------------------------------------

--
-- Table structure for table `notifications_log`
--

CREATE TABLE `notifications_log` (
  `id` int(11) NOT NULL,
  `sender_id` int(11) NOT NULL,
  `audience` varchar(60) NOT NULL,
  `title` varchar(150) NOT NULL,
  `body` text NOT NULL,
  `sent_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications_log`
--

INSERT INTO `notifications_log` (`id`, `sender_id`, `audience`, `title`, `body`, `sent_at`) VALUES
(1, 1, 'Secret', 'Compliance Notice', 'Pakabuot', '2026-08-21 07:42:35'),
(2, 1, 'All lessors (1)', 'Policy Update', 'gwapo', '2026-08-21 07:49:31');

-- --------------------------------------------------------

--
-- Table structure for table `notification_recipients`
--

CREATE TABLE `notification_recipients` (
  `id` int(11) NOT NULL,
  `notification_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `read_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notification_recipients`
--

INSERT INTO `notification_recipients` (`id`, `notification_id`, `user_id`, `read_at`) VALUES
(1, 2, 2, '2026-08-21 08:01:39');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `lessor_id` int(11) NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `method` enum('cash','bank_transfer','gcash','check','other') NOT NULL DEFAULT 'cash',
  `note` varchar(255) DEFAULT NULL,
  `paid_at` date NOT NULL,
  `logged_by` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `tenant_id`, `lessor_id`, `amount`, `method`, `note`, `paid_at`, `logged_by`, `created_at`) VALUES
(1, 1, 2, 1000.00, 'cash', NULL, '2026-08-22', 2, '2026-08-22 04:54:21'),
(2, 2, 2, 1000.00, 'cash', NULL, '2026-08-22', 2, '2026-08-22 04:54:44');

-- --------------------------------------------------------

--
-- Table structure for table `platform_settings`
--

CREATE TABLE `platform_settings` (
  `setting_key` varchar(100) NOT NULL,
  `setting_value` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `platform_settings`
--

INSERT INTO `platform_settings` (`setting_key`, `setting_value`) VALUES
('auto_generate_eviction', '0'),
('auto_renewal_offers', '1'),
('maintenance_mode', '0'),
('platform_fee_percent', '5'),
('qr_audit_required', '1');

-- --------------------------------------------------------

--
-- Table structure for table `properties`
--

CREATE TABLE `properties` (
  `id` int(11) NOT NULL,
  `lessor_id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `type` varchar(60) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `asking_rent` decimal(12,2) DEFAULT NULL,
  `status` enum('pending','verified','rejected') NOT NULL DEFAULT 'pending',
  `title_doc_path` varchar(255) DEFAULT NULL,
  `tax_dec_path` varchar(255) DEFAULT NULL,
  `photos_path` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `properties`
--

INSERT INTO `properties` (`id`, `lessor_id`, `name`, `type`, `address`, `latitude`, `longitude`, `asking_rent`, `status`, `title_doc_path`, `tax_dec_path`, `photos_path`, `created_at`) VALUES
(1, 2, 'pwestora', 'Other', 'dss', NULL, NULL, NULL, 'verified', 'uploads/properties/1/title_doc_97bf08ad.jpg', 'uploads/properties/1/tax_dec_253bc4b8.jpg', 'uploads/properties/1/photos_37ca3a94.jpg', '2026-08-21 02:59:19'),
(2, 16, 'KapeNagus2', 'Food Stall', 'Brgy. Mansilingan, Bacolod City', NULL, NULL, 2000.00, 'verified', 'uploads/properties/2/title_doc_e93a2337.jpg', 'uploads/properties/2/tax_dec_41e65a52.png', NULL, '2026-09-12 04:51:13');

-- --------------------------------------------------------

--
-- Table structure for table `property_photos`
--

CREATE TABLE `property_photos` (
  `id` int(11) NOT NULL,
  `property_id` int(11) NOT NULL,
  `photo_path` varchar(255) NOT NULL,
  `uploaded_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `property_photos`
--

INSERT INTO `property_photos` (`id`, `property_id`, `photo_path`, `uploaded_at`) VALUES
(1, 2, 'uploads/properties/2/photo_ac5134fa.webp', '2026-09-12 04:51:13');

-- --------------------------------------------------------

--
-- Table structure for table `tenants`
--

CREATE TABLE `tenants` (
  `id` int(11) NOT NULL,
  `lessor_id` int(11) NOT NULL,
  `property_id` int(11) NOT NULL,
  `application_id` int(11) DEFAULT NULL,
  `lessee_id` int(11) DEFAULT NULL,
  `tenant_name` varchar(150) NOT NULL,
  `unit_label` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tenants`
--

INSERT INTO `tenants` (`id`, `lessor_id`, `property_id`, `application_id`, `lessee_id`, `tenant_name`, `unit_label`, `created_at`) VALUES
(1, 2, 1, 1, NULL, 'jm', NULL, '2026-08-21 09:33:24'),
(2, 2, 1, 2, 3, 'jm', NULL, '2026-08-21 10:02:16'),
(3, 2, 1, 3, 7, 'glenn', NULL, '2026-08-27 01:04:28'),
(4, 2, 1, 5, 10, 'Daniel Pastor', NULL, '2026-09-06 15:01:51'),
(5, 2, 1, 6, 12, 'Jake Peralta', NULL, '2026-09-07 10:03:01');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `role` enum('lessor','superadmin','lessee') NOT NULL DEFAULT 'lessor',
  `status` enum('pending','active','suspended') NOT NULL DEFAULT 'pending',
  `company_name` varchar(150) DEFAULT NULL,
  `full_name` varchar(150) NOT NULL,
  `email` varchar(150) NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `api_token` varchar(64) DEFAULT NULL,
  `otp_code` varchar(6) DEFAULT NULL,
  `otp_expires_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `role`, `status`, `company_name`, `full_name`, `email`, `phone`, `password_hash`, `api_token`, `otp_code`, `otp_expires_at`, `created_at`, `updated_at`) VALUES
(1, 'superadmin', 'active', NULL, 'John Michael Antinola', 'pwestora.unknownprogrammer@gmail.com', NULL, '$2y$10$A5DbzVabC1Ysu14JAMBJGeX/fzdO8a/iZzNsy8flypxo/4ETM2Mc2', NULL, NULL, NULL, '2026-08-21 02:22:51', '2026-08-23 08:50:49'),
(2, 'lessor', 'active', 'Secret', 'glenn', 'jmantinola54@gmail.com', '0911', '$2y$10$ohDDjgx2N4pe9KTIlgXJx.kBFQpI9FOuYvilQVaGAO1fTranky/Ga', NULL, NULL, NULL, '2026-08-21 02:32:16', '2026-08-23 08:58:02'),
(3, 'lessee', 'active', NULL, 'jm', 'jm@gmail.com', '588558', '$2y$10$2CE9Oa3PYijMUq5uqdbqquZZrXBQfvIZ4UmWChFna43VN3.xUW22.', '9725872376531cef995e19287f9375af6ba37d3effe6a522f7b914276250459e', NULL, NULL, '2026-08-21 09:27:25', '2026-09-08 00:51:42'),
(4, 'lessor', 'active', 'gwapo ako', 'gwaposiglenn?', 'glennxlord@gmail.com', '09646454545454', '$2y$10$6JQXg1fjpn0kZCXeSWdHBOeLtLnpBkJTEVy68Z45xocNcm1fDQmse', NULL, NULL, NULL, '2026-08-21 14:16:11', '2026-08-23 14:04:18'),
(5, 'lessee', 'active', NULL, 'h', 'glenn@gmail.com', '39', '$2y$10$0r35W.kN81dvkhWSdBPn6eKxU0DekhtdAkzK0SClosxYxnqBEDK2.', '930ba507aa99e10f3a0ee2e9b3ad3883582f27bae87da55c6f9ce9ef81db758b', NULL, NULL, '2026-08-21 22:11:11', '2026-08-21 22:11:11'),
(6, 'lessor', 'active', 'Sample', 'Bacolod', 'jmantinola58@gmail.com', '09323232', '$2y$10$JP1w8Cq6ZEggbYx8PNNlGeRzlTDN/AUXBj9KSjvd7xDIBArAOaAJC', NULL, NULL, NULL, '2026-08-23 07:20:22', '2026-08-23 07:55:09'),
(7, 'lessee', 'active', NULL, 'glenn', 'witness.22.15@gmail.com', '123456789', '$2y$10$wRXV/KSPpzMW1DwdSqmLJu4AWxPDSbhUkqGprZQPQpKjGCrO7OCMa', '6b6d6103c433884bb22083a687d56f013b9ef800090b200c89e2f9f5bc42aebe', NULL, NULL, '2026-08-27 01:01:54', '2026-08-27 01:01:54'),
(8, 'lessee', 'active', NULL, 'glenngwapo', 'paolopastorcot305@gmail.com', '09649454588', '$2y$10$S.HX8Fdw.foiE.P.UiM4vuZACi/o5X5m5V7O7CjhCocNfgcSf/KZS', '56cf9e21c7a26e381914ca2d070443b59fed3367c9b15916d2253f2a003517d7', NULL, NULL, '2026-08-27 01:36:11', '2026-08-27 01:36:11'),
(9, 'lessee', 'active', NULL, 'Chris Daniel Acot', 'chrisdanielacot5226@gmail.com', '09945884126', '$2y$10$CW9Hjjs0V9qobOfF1eUbbuZGEng7ryhtAXm8NLm.a6CjqBqqTcZtG', '2c342df0f9f2afae42da64e32384b486e05921d42f9381f99577216061ea5adb', NULL, NULL, '2026-09-06 14:14:42', '2026-09-06 14:14:42'),
(10, 'lessee', 'active', NULL, 'Daniel Pastor', 'chrisdaniel305@gmail.com', '09945884126', '$2y$10$nG9DOmh4vyz1mirIeX4xRueCwjs4gjaUcMXzn2mZ9LNdZpfLPQ1H.', '714e913644c85f0610c0a6620643a7cf69169cd786da47e5c205ebe53442f912', NULL, NULL, '2026-09-06 14:56:32', '2026-09-06 14:56:32'),
(11, 'lessee', 'active', NULL, 'jm', 'it.prolifemanagement@gmail.com', '688686', '$2y$10$RLnytSI9nOSeF6wGjN2pHuXyQv7loqcTDewbwjkIpyUVrCBFlEYEy', '7ff2e5cd78e6ce9c86fafcb37f4f0bab50fd6a3acc3ff3b28d9f5465f5c696da', NULL, NULL, '2026-09-07 05:34:38', '2026-09-07 05:34:38'),
(12, 'lessee', 'active', NULL, 'Jake Peralta', 'jakeperalta@gmail.com', '09123141146', '$2y$10$bbfDBJyaOx6adVzjLmCxwe2kPEaWvg6vpVGj48xEqUeTZ6JYsS4jW', '4065a9f3c0608dcceb451f89d5c988103c6f5cebfef24f08b21d38be1e89bb13', NULL, NULL, '2026-09-07 10:00:21', '2026-09-14 10:54:02'),
(13, 'lessee', 'active', NULL, 'John Sazon', 'johnsazon@gmail.com', '09945884122', '$2y$10$42L/ToWnbwHocHQbFzcI6edodd3dt4CMnS/FyAPA.CppA6C1OyicC', '85425aead077c44f4aa287f70aca9d1794a9166646dbf52e51404bb05a94bbfd', NULL, NULL, '2026-09-07 13:48:40', '2026-09-08 00:44:53'),
(14, 'lessee', 'active', NULL, 'Holt Raymund', 'holt@gmail.com', '09266982730', '$2y$10$PMnMN9NGUEkkrSCyqs5g1uBBmuwRQHqe.GyZNaCcqiLUrBVUEFM0C', '0604c2fffb69cfaa6c297c9566a16e4d519f8beea49c532f1f65a05b864f0948', NULL, NULL, '2026-09-12 04:33:22', '2026-09-12 04:33:22'),
(15, 'lessor', 'suspended', 'KapeNagus2', 'Daniel Acot', 'danielacot@gmail.com', '09945884126', '$2y$10$svnGMDkKW1n1nLpN6zuMxe3IgCeY1RZ8kyoUcnlnEl.OIcWjCIxSm', NULL, '511274', '2026-09-12 04:56:52', '2026-09-12 04:46:52', '2026-09-12 04:48:38'),
(16, 'lessor', 'suspended', 'KapeNagus2', 'Daniel Acot', 'paolopastoracot305@gmail.com', '09945884126', '$2y$10$VS8SfbIcilPjHCinBfRbMen23vO5dR9ygUJBH/RAe5HOTGIs78Sm.', NULL, NULL, NULL, '2026-09-12 04:47:34', '2026-09-13 03:17:22'),
(17, 'lessee', 'active', NULL, 'Charmain Acot', 'charmaine@gmail.com', '09937481293', '$2y$10$t0AQW/DB63EKZBQVJj2QI.dcgzK9t2FjUAtzHkYmrQHiutqVMQX5S', '08cc4697b2b97ab0d93013ff3a862bb7d0c1d0cb90d98d2af083c88193d7585b', NULL, NULL, '2026-09-14 11:12:40', '2026-09-14 11:12:40');

-- --------------------------------------------------------

--
-- Table structure for table `violations`
--

CREATE TABLE `violations` (
  `id` int(11) NOT NULL,
  `lessor_id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `category` varchar(100) NOT NULL,
  `strike` tinyint(4) NOT NULL DEFAULT 1,
  `acknowledged` tinyint(1) NOT NULL DEFAULT 0,
  `issued_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `violations`
--

INSERT INTO `violations` (`id`, `lessor_id`, `tenant_id`, `category`, `strike`, `acknowledged`, `issued_at`) VALUES
(1, 2, 2, 'Late Operating Hours', 1, 1, '2026-08-22 04:39:09'),
(2, 2, 2, 'Late Operating Hours', 2, 0, '2026-08-22 05:06:46');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `applications`
--
ALTER TABLE `applications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `property_id` (`property_id`),
  ADD KEY `lessor_id` (`lessor_id`),
  ADD KEY `fk_applications_lessee` (`lessee_id`);

--
-- Indexes for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `actor_id` (`actor_id`);

--
-- Indexes for table `deposits`
--
ALTER TABLE `deposits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `lessor_id` (`lessor_id`),
  ADD KEY `tenant_id` (`tenant_id`);

--
-- Indexes for table `disputes`
--
ALTER TABLE `disputes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `tenant_id` (`tenant_id`),
  ADD KEY `lessor_id` (`lessor_id`);

--
-- Indexes for table `installment_requests`
--
ALTER TABLE `installment_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `lessor_id` (`lessor_id`),
  ADD KEY `tenant_id` (`tenant_id`);

--
-- Indexes for table `lease_checklist_acknowledgments`
--
ALTER TABLE `lease_checklist_acknowledgments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_user_item` (`user_id`,`item_key`);

--
-- Indexes for table `lessor_profiles`
--
ALTER TABLE `lessor_profiles`
  ADD PRIMARY KEY (`user_id`),
  ADD KEY `verified_by` (`verified_by`);

--
-- Indexes for table `maintenance_tickets`
--
ALTER TABLE `maintenance_tickets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `lessor_id` (`lessor_id`),
  ADD KEY `tenant_id` (`tenant_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `thread_id` (`thread_id`);

--
-- Indexes for table `message_threads`
--
ALTER TABLE `message_threads`
  ADD PRIMARY KEY (`id`),
  ADD KEY `lessor_id` (`lessor_id`),
  ADD KEY `tenant_id` (`tenant_id`);

--
-- Indexes for table `notifications_log`
--
ALTER TABLE `notifications_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sender_id` (`sender_id`);

--
-- Indexes for table `notification_recipients`
--
ALTER TABLE `notification_recipients`
  ADD PRIMARY KEY (`id`),
  ADD KEY `notification_id` (`notification_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `tenant_id` (`tenant_id`),
  ADD KEY `lessor_id` (`lessor_id`),
  ADD KEY `logged_by` (`logged_by`);

--
-- Indexes for table `platform_settings`
--
ALTER TABLE `platform_settings`
  ADD PRIMARY KEY (`setting_key`);

--
-- Indexes for table `properties`
--
ALTER TABLE `properties`
  ADD PRIMARY KEY (`id`),
  ADD KEY `lessor_id` (`lessor_id`);

--
-- Indexes for table `property_photos`
--
ALTER TABLE `property_photos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `property_id` (`property_id`);

--
-- Indexes for table `tenants`
--
ALTER TABLE `tenants`
  ADD PRIMARY KEY (`id`),
  ADD KEY `lessor_id` (`lessor_id`),
  ADD KEY `property_id` (`property_id`),
  ADD KEY `application_id` (`application_id`),
  ADD KEY `fk_tenants_lessee` (`lessee_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `api_token` (`api_token`);

--
-- Indexes for table `violations`
--
ALTER TABLE `violations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `lessor_id` (`lessor_id`),
  ADD KEY `tenant_id` (`tenant_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `applications`
--
ALTER TABLE `applications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `audit_logs`
--
ALTER TABLE `audit_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=128;

--
-- AUTO_INCREMENT for table `deposits`
--
ALTER TABLE `deposits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `disputes`
--
ALTER TABLE `disputes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `installment_requests`
--
ALTER TABLE `installment_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lease_checklist_acknowledgments`
--
ALTER TABLE `lease_checklist_acknowledgments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `maintenance_tickets`
--
ALTER TABLE `maintenance_tickets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `message_threads`
--
ALTER TABLE `message_threads`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `notifications_log`
--
ALTER TABLE `notifications_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `notification_recipients`
--
ALTER TABLE `notification_recipients`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `properties`
--
ALTER TABLE `properties`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `property_photos`
--
ALTER TABLE `property_photos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tenants`
--
ALTER TABLE `tenants`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `violations`
--
ALTER TABLE `violations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `applications`
--
ALTER TABLE `applications`
  ADD CONSTRAINT `applications_ibfk_1` FOREIGN KEY (`property_id`) REFERENCES `properties` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `applications_ibfk_2` FOREIGN KEY (`lessor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_applications_lessee` FOREIGN KEY (`lessee_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD CONSTRAINT `audit_logs_ibfk_1` FOREIGN KEY (`actor_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `deposits`
--
ALTER TABLE `deposits`
  ADD CONSTRAINT `deposits_ibfk_1` FOREIGN KEY (`lessor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `deposits_ibfk_2` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `disputes`
--
ALTER TABLE `disputes`
  ADD CONSTRAINT `disputes_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `disputes_ibfk_2` FOREIGN KEY (`lessor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `installment_requests`
--
ALTER TABLE `installment_requests`
  ADD CONSTRAINT `installment_requests_ibfk_1` FOREIGN KEY (`lessor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `installment_requests_ibfk_2` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `lease_checklist_acknowledgments`
--
ALTER TABLE `lease_checklist_acknowledgments`
  ADD CONSTRAINT `lease_checklist_acknowledgments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `lessor_profiles`
--
ALTER TABLE `lessor_profiles`
  ADD CONSTRAINT `lessor_profiles_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `lessor_profiles_ibfk_2` FOREIGN KEY (`verified_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `maintenance_tickets`
--
ALTER TABLE `maintenance_tickets`
  ADD CONSTRAINT `maintenance_tickets_ibfk_1` FOREIGN KEY (`lessor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `maintenance_tickets_ibfk_2` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`thread_id`) REFERENCES `message_threads` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `message_threads`
--
ALTER TABLE `message_threads`
  ADD CONSTRAINT `message_threads_ibfk_1` FOREIGN KEY (`lessor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `message_threads_ibfk_2` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications_log`
--
ALTER TABLE `notifications_log`
  ADD CONSTRAINT `notifications_log_ibfk_1` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notification_recipients`
--
ALTER TABLE `notification_recipients`
  ADD CONSTRAINT `notification_recipients_ibfk_1` FOREIGN KEY (`notification_id`) REFERENCES `notifications_log` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notification_recipients_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`lessor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `payments_ibfk_3` FOREIGN KEY (`logged_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `properties`
--
ALTER TABLE `properties`
  ADD CONSTRAINT `properties_ibfk_1` FOREIGN KEY (`lessor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `property_photos`
--
ALTER TABLE `property_photos`
  ADD CONSTRAINT `property_photos_ibfk_1` FOREIGN KEY (`property_id`) REFERENCES `properties` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `tenants`
--
ALTER TABLE `tenants`
  ADD CONSTRAINT `fk_tenants_lessee` FOREIGN KEY (`lessee_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `tenants_ibfk_1` FOREIGN KEY (`lessor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `tenants_ibfk_2` FOREIGN KEY (`property_id`) REFERENCES `properties` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `tenants_ibfk_3` FOREIGN KEY (`application_id`) REFERENCES `applications` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `violations`
--
ALTER TABLE `violations`
  ADD CONSTRAINT `violations_ibfk_1` FOREIGN KEY (`lessor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `violations_ibfk_2` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
