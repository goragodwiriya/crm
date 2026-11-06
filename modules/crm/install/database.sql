-- ---------------------------------------------------------------------------
-- modules/crm/install/database.sql — ตารางที่โมดูล crm เป็นเจ้าของ
--
-- **ประกาศที่นี่ที่เดียว** ห้ามประกาศซ้ำใน install/database.sql ของโปรเจ็ค
--
-- ข้อกำหนด: InnoDB + utf8mb4 และเขียน PRIMARY KEY/KEY ไว้ในคำสั่ง CREATE TABLE
-- เลย — ของเดิมแยกคีย์ไปเป็น ALTER TABLE ท้ายไฟล์แบบที่ phpMyAdmin ส่งออกมา
-- ทำให้ตารางที่ ensureTable สร้างตอนปรับรุ่นไม่ได้ดัชนีติดมาด้วย
--
-- ⚠️ ห้ามประกาศ COLLATE เอง — convertToUtf8mb4() บังคับ utf8mb4_general_ci
-- ---------------------------------------------------------------------------

CREATE TABLE `{prefix}_activities` (
`id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
`type` enum('call','meeting','email','task','note','lunch','demo','follow_up') NOT NULL,
`subject` varchar(255) NOT NULL,
`description` mediumtext DEFAULT NULL,
`customer_id` int(10) UNSIGNED DEFAULT NULL,
`contact_id` int(10) UNSIGNED DEFAULT NULL,
`deal_id` int(10) UNSIGNED DEFAULT NULL,
`owner_id` int(10) UNSIGNED DEFAULT NULL,
`start_time` datetime DEFAULT NULL,
`end_time` datetime DEFAULT NULL,
`duration_minutes` int(11) DEFAULT NULL,
`location` varchar(255) DEFAULT NULL,
`status` enum('scheduled','completed','cancelled','no_show') NOT NULL DEFAULT 'scheduled',
`outcome` mediumtext DEFAULT NULL,
`priority` enum('low','medium','high') NOT NULL DEFAULT 'medium',
`reminder_at` datetime DEFAULT NULL,
`created_at` timestamp NOT NULL DEFAULT current_timestamp(),
`updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_type` (`type`),
  KEY `idx_customer` (`customer_id`),
  KEY `idx_contact` (`contact_id`),
  KEY `idx_deal` (`deal_id`),
  KEY `idx_owner` (`owner_id`),
  KEY `idx_status` (`status`),
  KEY `idx_start_time` (`start_time`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `{prefix}_campaigns` (
`id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
`name` varchar(255) NOT NULL,
`description` mediumtext DEFAULT NULL,
`type` enum('email','social','event','webinar','advertisement','other') NOT NULL DEFAULT 'email',
`status` enum('draft','scheduled','active','paused','completed','cancelled') NOT NULL DEFAULT 'draft',
`budget` decimal(15,2) DEFAULT 0.00,
`actual_cost` decimal(15,2) DEFAULT 0.00,
`start_date` date DEFAULT NULL,
`end_date` date DEFAULT NULL,
`target_leads` int(11) DEFAULT 0,
`actual_leads` int(11) DEFAULT 0,
`target_revenue` decimal(15,2) DEFAULT 0.00,
`actual_revenue` decimal(15,2) DEFAULT 0.00,
`owner_id` int(10) UNSIGNED DEFAULT NULL,
`created_at` timestamp NOT NULL DEFAULT current_timestamp(),
`updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_type` (`type`),
  KEY `idx_status` (`status`),
  KEY `idx_owner` (`owner_id`),
  KEY `idx_dates` (`start_date`,`end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `{prefix}_contacts` (
`id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
`customer_id` int(10) UNSIGNED DEFAULT NULL,
`first_name` varchar(100) NOT NULL,
`last_name` varchar(100) DEFAULT NULL,
`email` varchar(255) DEFAULT NULL,
`phone` varchar(50) DEFAULT NULL,
`mobile` varchar(50) DEFAULT NULL,
`job_title` varchar(100) DEFAULT NULL,
`department` varchar(100) DEFAULT NULL,
`is_primary` tinyint(1) NOT NULL DEFAULT 0,
`is_decision_maker` tinyint(1) NOT NULL DEFAULT 0,
`linkedin` varchar(255) DEFAULT NULL,
`notes` mediumtext DEFAULT NULL,
`status` enum('active','inactive') NOT NULL DEFAULT 'active',
`owner_id` int(10) UNSIGNED DEFAULT NULL,
`created_at` timestamp NOT NULL DEFAULT current_timestamp(),
`updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_customer` (`customer_id`),
  KEY `idx_email` (`email`),
  KEY `idx_owner` (`owner_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `{prefix}_customers` (
`id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
`name` varchar(255) NOT NULL,
`company_type` enum('company','individual') NOT NULL DEFAULT 'company',
`industry` varchar(100) DEFAULT NULL,
`website` varchar(255) DEFAULT NULL,
`email` varchar(255) DEFAULT NULL,
`phone` varchar(10) DEFAULT NULL,
`fax` varchar(10) DEFAULT NULL,
`address` mediumtext DEFAULT NULL,
`provinceID` int(2) DEFAULT NULL,
`zipcode` varchar(5) DEFAULT NULL,
`tax_id` varchar(13) DEFAULT NULL,
`status` enum('lead','prospect','customer','inactive','churned') NOT NULL DEFAULT 'lead',
`source` enum('website','referral','cold_call','advertisement','trade_show','social_media','other') DEFAULT 'website',
`annual_revenue` decimal(15,2) DEFAULT NULL,
`employee_count` int(11) DEFAULT NULL,
`rating` tinyint(3) UNSIGNED DEFAULT NULL COMMENT '1-5 stars',
`owner_id` int(11) UNSIGNED DEFAULT NULL,
`notes` mediumtext DEFAULT NULL,
`created_at` datetime NOT NULL DEFAULT current_timestamp(),
`updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_owner` (`owner_id`),
  KEY `idx_industry` (`industry`),
  KEY `idx_source` (`source`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `{prefix}_deals` (
`id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
`title` varchar(255) NOT NULL,
`customer_id` int(10) UNSIGNED NOT NULL,
`contact_id` int(10) UNSIGNED DEFAULT NULL,
`pipeline_id` int(10) UNSIGNED NOT NULL,
`stage_id` int(10) UNSIGNED NOT NULL,
`stage` enum('lead','qualified','proposal','negotiation','won','lost') NOT NULL DEFAULT 'lead',
`value` decimal(15,2) NOT NULL DEFAULT 0.00,
`currency` varchar(3) NOT NULL DEFAULT 'THB',
`probability` tinyint(3) UNSIGNED DEFAULT 0,
`expected_close_date` date DEFAULT NULL,
`actual_close_date` date DEFAULT NULL,
`lost_reason` varchar(255) DEFAULT NULL,
`owner_id` int(10) UNSIGNED DEFAULT NULL,
`source` enum('website','referral','cold_call','upsell','cross_sell','other') DEFAULT 'website',
`priority` enum('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
`notes` mediumtext DEFAULT NULL,
`created_at` timestamp NOT NULL DEFAULT current_timestamp(),
`updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_customer` (`customer_id`),
  KEY `idx_contact` (`contact_id`),
  KEY `idx_pipeline` (`pipeline_id`),
  KEY `idx_stage` (`stage_id`),
  KEY `idx_stage_enum` (`stage`),
  KEY `idx_owner` (`owner_id`),
  KEY `idx_expected_close` (`expected_close_date`),
  KEY `idx_created` (`created_at`),
  KEY `idx_value` (`value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `{prefix}_tasks` (
`id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
`title` varchar(255) NOT NULL,
`description` mediumtext DEFAULT NULL,
`customer_id` int(10) UNSIGNED DEFAULT NULL,
`contact_id` int(10) UNSIGNED DEFAULT NULL,
`deal_id` int(10) UNSIGNED DEFAULT NULL,
`owner_id` int(10) UNSIGNED DEFAULT NULL,
`assigned_to` int(10) UNSIGNED DEFAULT NULL,
`due_date` date DEFAULT NULL,
`due_time` time DEFAULT NULL,
`priority` enum('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
`status` enum('pending','in_progress','completed','cancelled') NOT NULL DEFAULT 'pending',
`completed_at` timestamp NULL DEFAULT NULL,
`reminder_at` datetime DEFAULT NULL,
`created_at` timestamp NOT NULL DEFAULT current_timestamp(),
`updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_customer` (`customer_id`),
  KEY `idx_deal` (`deal_id`),
  KEY `idx_owner` (`owner_id`),
  KEY `idx_assigned` (`assigned_to`),
  KEY `idx_due_date` (`due_date`),
  KEY `idx_status` (`status`),
  KEY `idx_priority` (`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `{prefix}_teams` (
`id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
`name` varchar(100) NOT NULL,
`description` mediumtext DEFAULT NULL,
`manager_id` int(10) UNSIGNED DEFAULT NULL,
`target_monthly` decimal(15,2) DEFAULT 0.00,
`target_quarterly` decimal(15,2) DEFAULT 0.00,
`target_yearly` decimal(15,2) DEFAULT 0.00,
`status` enum('active','inactive') NOT NULL DEFAULT 'active',
`created_at` timestamp NOT NULL DEFAULT current_timestamp(),
`updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_manager` (`manager_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `{prefix}_activities` (`id`, `type`, `subject`, `description`, `customer_id`, `contact_id`, `deal_id`, `owner_id`, `start_time`, `end_time`, `duration_minutes`, `location`, `status`, `outcome`, `priority`, `reminder_at`, `created_at`, `updated_at`) VALUES
(1, 'call', 'Follow up call', 'ติดตามผลหลังส่ง proposal', 4, 5, 11, 4, '2026-01-02 14:03:09', '2026-01-02 14:33:09', 30, '', 'scheduled', '', 'high', NULL, '2026-01-02 07:03:09', '2026-01-01 09:38:51'),
(2, 'meeting', 'Negotiation meeting', 'ประชุมเจรจาต่อรองราคา', 19, NULL, 13, 7, '2026-02-02 14:03:09', '2026-02-02 16:03:09', 120, NULL, 'scheduled', NULL, 'high', NULL, '2026-02-02 07:03:09', '2026-01-01 09:38:51'),
(3, 'demo', 'Product Demo', 'สาธิตระบบ ERP', 2, 3, 9, 4, '2026-03-02 14:03:09', '2026-03-02 15:03:09', 60, NULL, 'scheduled', NULL, 'medium', NULL, '2026-03-02 07:03:09', '2026-01-01 09:38:51'),
(4, 'meeting', 'Proposal Presentation', 'นำเสนอ proposal', 5, 6, 12, 6, '2026-04-02 14:03:09', '2026-04-02 16:03:09', 120, NULL, 'scheduled', NULL, 'high', NULL, '2026-04-02 07:03:09', '2026-01-01 09:38:51'),
(5, 'call', 'Requirements Discussion', 'สอบถามความต้องการเพิ่มเติม', 1, 1, 8, 3, '2026-05-02 14:03:09', '2026-05-02 14:33:09', 30, NULL, 'scheduled', NULL, 'medium', NULL, '2026-05-02 07:03:09', '2026-01-01 09:38:51'),
(6, 'lunch', 'Business Lunch', 'พบปะลูกค้า VIP', 8, 7, NULL, 4, '2026-06-02 14:03:09', '2026-06-02 15:33:09', 90, NULL, 'scheduled', NULL, 'medium', NULL, '2026-06-02 07:03:09', '2026-01-01 09:38:51'),
(7, 'call', 'Initial Contact', 'ติดต่อครั้งแรก', 23, NULL, NULL, 3, '2026-07-02 14:03:09', '2026-07-02 14:33:09', 30, NULL, 'completed', 'สนใจ ขอนัดประชุม', 'medium', NULL, '2026-07-02 07:03:09', '2026-01-01 09:38:51'),
(8, 'meeting', 'Requirements Gathering', 'สำรวจความต้องการ', 4, 5, 11, 4, '2026-08-02 14:03:09', '2026-08-02 16:03:09', 120, NULL, 'completed', 'ได้ข้อมูลครบถ้วน พร้อมทำ proposal', 'high', NULL, '2026-08-02 07:03:09', '2026-01-01 09:38:51'),
(9, 'email', 'Proposal Sent', 'ส่ง proposal ทางอีเมล', 5, 6, 12, 6, '2026-09-02 14:03:09', NULL, NULL, NULL, 'completed', 'ลูกค้าได้รับแล้ว รอพิจารณา', 'high', NULL, '2026-09-02 07:03:09', '2026-01-01 09:36:22'),
(10, 'call', 'Quote Follow-up', 'ติดตามใบเสนอราคา', 17, NULL, NULL, 6, '2026-10-02 14:03:09', '2026-10-02 14:18:09', 15, NULL, 'completed', 'กำลังพิจารณา จะตอบภายในสัปดาห์หน้า', 'medium', NULL, '2026-10-02 07:03:09', '2026-01-01 09:38:51'),
(11, 'meeting', 'Contract Signing', 'เซ็นสัญญา', 8, 7, 1, 4, '2026-11-02 14:03:09', '2026-11-02 15:03:09', 60, NULL, 'completed', 'เซ็นสัญญาเรียบร้อย', 'high', NULL, '2026-11-02 07:03:09', '2026-01-01 09:38:51'),
(12, 'call', 'Thank You Call', 'ขอบคุณลูกค้า', 11, 10, 2, 4, '2026-12-02 14:03:09', '2026-12-02 14:18:09', 15, NULL, 'completed', 'ลูกค้าพอใจมาก', 'low', NULL, '2026-12-02 07:03:09', '2026-01-01 09:38:51');

INSERT INTO `{prefix}_campaigns` (`id`, `name`, `description`, `type`, `status`, `budget`, `actual_cost`, `start_date`, `end_date`, `target_leads`, `actual_leads`, `target_revenue`, `actual_revenue`, `owner_id`, `created_at`, `updated_at`) VALUES
(1, 'Q4 2024 Enterprise Push', 'แคมเปญขายระบบ Enterprise สิ้นปี', 'email', 'active', '100000.00', '0.00', '2025-11-02', '2026-01-01', 50, 35, '10000000.00', '4300000.00', 2, '2026-12-02 07:03:09', '2026-01-01 09:43:58'),
(2, 'ERP Webinar Series', 'Webinar แนะนำระบบ ERP', 'webinar', 'completed', '50000.00', '0.00', '2025-10-03', '2025-11-02', 100, 120, '5000000.00', '3500000.00', 2, '2026-12-02 07:03:09', '2026-01-01 09:43:58'),
(3, 'SME Digital Transformation', 'แคมเปญ Digital Transformation สำหรับ SME', 'social', 'active', '80000.00', '0.00', '2025-11-17', '2026-01-16', 80, 25, '3000000.00', '800000.00', 5, '2026-12-02 07:03:09', '2026-01-01 09:43:58');

INSERT INTO `{prefix}_contacts` (`id`, `customer_id`, `first_name`, `last_name`, `email`, `phone`, `mobile`, `job_title`, `department`, `is_primary`, `is_decision_maker`, `linkedin`, `notes`, `status`, `owner_id`, `created_at`, `updated_at`) VALUES
(1, 1, 'วีรพงษ์', 'สุขสันต์', 'weerapong@digitalsolution.co.th', '021234567', '0812345678', 'CEO', 'Executive', 1, 1, '', '', 'active', 3, '2026-12-02 07:03:09', '2026-01-01 09:42:46'),
(2, 1, 'มาลี', 'ดีงาม', 'malee@digitalsolution.co.th', '02-123-4568', '082-345-6789', 'IT Manager', 'IT', 0, 0, NULL, NULL, 'active', 3, '2026-12-02 07:03:09', '2026-01-01 09:42:46'),
(3, 2, 'สมพงษ์', 'เจริญสุข', 'sompong@thaiinnovation.com', '02-234-5678', '083-456-7890', 'CTO', 'Technology', 1, 1, NULL, NULL, 'active', 4, '2026-12-02 07:03:09', '2026-01-01 09:42:46'),
(4, 2, 'นารี', 'สุขใจ', 'naree@thaiinnovation.com', '02-234-5679', '084-567-8901', 'Procurement Manager', 'Procurement', 0, 0, NULL, NULL, 'active', 4, '2026-12-02 07:03:09', '2026-01-01 09:42:46'),
(5, 4, 'ประสิทธิ์', 'มั่นคง', 'prasit@globalsoft.co.th', '02-456-7890', '085-678-9012', 'Managing Director', 'Executive', 1, 1, NULL, NULL, 'active', 4, '2026-12-02 07:03:09', '2026-01-01 09:42:46'),
(6, 5, 'รัตนา', 'ใจดี', 'rattana@cloudserve.co.th', '02-567-8901', '086-789-0123', 'IT Director', 'IT', 1, 1, NULL, NULL, 'active', 6, '2026-12-02 07:03:09', '2026-01-01 09:42:46'),
(7, 8, 'สมหมาย', 'ดีใจ', 'sommai@thaicommerce.co.th', '02-890-1234', '087-890-1234', 'CEO', 'Executive', 1, 1, NULL, NULL, 'active', 4, '2026-12-02 07:03:09', '2026-01-01 09:42:46'),
(8, 9, 'วิไล', 'สำราญ', 'wilai@mfgpro.co.th', '02-901-2345', '088-901-2345', 'COO', 'Operations', 1, 1, NULL, NULL, 'active', 7, '2026-12-02 07:03:09', '2026-01-01 09:42:46'),
(9, 10, 'ธนา', 'รุ่งเรือง', 'thana@logisticsplus.co.th', '02-012-3456', '089-012-3456', 'GM', 'Management', 1, 1, NULL, NULL, 'active', 3, '2026-12-02 07:03:09', '2026-01-01 09:42:46'),
(10, 11, 'จิราพร', 'เพียรดี', 'jiraporn@fintech.co.th', '02-111-2222', '090-123-4567', 'CFO', 'Finance', 1, 1, NULL, NULL, 'active', 4, '2026-12-02 07:03:09', '2026-01-01 09:42:46');

INSERT INTO `{prefix}_customers` (`id`, `name`, `company_type`, `industry`, `website`, `email`, `phone`, `fax`, `address`, `provinceID`, `zipcode`, `tax_id`, `status`, `source`, `annual_revenue`, `employee_count`, `rating`, `owner_id`, `notes`, `created_at`, `updated_at`) VALUES
(1, 'บริษัท ดิจิทัล โซลูชัน จำกัด', 'company', 'Technology', 'https://digitalsolution.co.th', 'contact@digitalsolution.co.th', '021234567', '', '123 ถนนสีลม', 10, '', '105562012345', 'lead', 'website', '50000000.00', 50, 3, 1, '', '2026-11-30 14:03:09', '2026-01-01 16:42:13'),
(2, 'บริษัท ไทย อินโนเวชั่น จำกัด', 'company', 'Technology', 'https://thaiinnovation.com', 'info@thaiinnovation.com', '022345678', NULL, '456 ถนนสาทร', 10, NULL, '0105562012346', 'lead', 'referral', '80000000.00', 80, 4, 4, NULL, '2026-11-29 14:03:09', '2026-01-01 16:42:13'),
(3, 'บริษัท สมาร์ท เทค จำกัด', 'company', 'Technology', 'https://smarttech.co.th', 'hello@smarttech.co.th', '023456789', NULL, '789 ถนนเพลินจิต', 10, NULL, '0105562012347', 'lead', 'cold_call', '30000000.00', 30, 2, 3, NULL, '2026-11-27 14:03:09', '2026-01-01 16:42:13'),
(4, 'บริษัท โกลบอล ซอฟต์ จำกัด', 'company', 'Software', 'https://globalsoft.co.th', 'sales@globalsoft.co.th', '024567890', NULL, '321 ถนนพระราม 4', 10, NULL, '0105562012348', 'prospect', 'website', '100000000.00', 100, 4, 4, NULL, '2026-11-22 14:03:09', '2026-01-01 16:42:13'),
(5, 'บริษัท คลาวด์ เซิร์ฟ จำกัด', 'company', 'Technology', 'https://cloudserve.co.th', 'contact@cloudserve.co.th', '025678901', NULL, '654 ถนนวิทยุ', 10, NULL, '0105562012349', 'prospect', 'trade_show', '75000000.00', 60, 3, 5, NULL, '2026-11-17 14:03:09', '2026-01-01 16:42:13'),
(6, 'บริษัท ดาต้า โปร จำกัด', 'company', 'Data Analytics', 'https://datapro.co.th', 'info@datapro.co.th', '026789012', NULL, '987 ถนนรัชดาภิเษก', 10, NULL, '0105562012350', 'prospect', 'social_media', '45000000.00', 40, 3, 3, NULL, '2026-11-12 14:03:09', '2026-01-01 16:42:13'),
(7, 'บริษัท เน็ตเวิร์ค โซลูชัน จำกัด', 'company', 'Networking', 'https://networksolution.co.th', 'support@networksolution.co.th', '027890123', NULL, '147 ถนนลาดพร้าว', 10, NULL, '0105562012351', 'prospect', 'advertisement', '60000000.00', 55, 4, 5, NULL, '2026-11-07 14:03:09', '2026-01-01 16:42:13'),
(8, 'บริษัท ไทย คอมเมิร์ซ จำกัด', 'company', 'E-commerce', 'https://thaicommerce.co.th', 'sales@thaicommerce.co.th', '028901234', NULL, '258 ถนนสุขุมวิท', 10, NULL, '0105562012352', 'customer', 'website', '200000000.00', 150, 5, 4, NULL, '2026-10-03 14:03:09', '2026-01-01 16:42:13'),
(9, 'บริษัท แมนูแฟคเจอริ่ง โปร จำกัด', 'company', 'Manufacturing', 'https://mfgpro.co.th', 'contact@mfgpro.co.th', '029012345', NULL, '369 ถนนพัฒนาการ', 10, NULL, '0105562012353', 'customer', 'referral', '500000000.00', 500, 5, 5, NULL, '2026-09-03 14:03:09', '2026-01-01 16:42:13'),
(10, 'บริษัท โลจิสติกส์ พลัส จำกัด', 'company', 'Logistics', 'https://logisticsplus.co.th', 'info@logisticsplus.co.th', '020123456', NULL, '471 ถนนบางนา', 10, NULL, '0105562012354', 'customer', 'cold_call', '150000000.00', 200, 4, 3, NULL, '2026-08-04 14:03:09', '2026-01-01 16:42:13'),
(11, 'บริษัท ไฟแนนซ์ เทค จำกัด', 'company', 'Finance', 'https://fintech.co.th', 'hello@fintech.co.th', '021112222', NULL, '582 ถนนอโศก', 10, NULL, '0105562012355', 'customer', 'trade_show', '300000000.00', 100, 5, 4, NULL, '2026-07-05 14:03:09', '2026-01-01 16:42:13'),
(12, 'บริษัท เฮลธ์แคร์ โซลูชัน จำกัด', 'company', 'Healthcare', 'https://healthcare-sol.co.th', 'contact@healthcare-sol.co.th', '022223333', NULL, '693 ถนนพหลโยธิน', 10, NULL, '0105562012356', 'customer', 'website', '180000000.00', 120, 4, 6, NULL, '2026-06-05 14:03:09', '2026-01-01 16:42:13'),
(13, 'บริษัท อีดูเคชั่น เทค จำกัด', 'company', 'Education', 'https://edutech.co.th', 'info@edutech.co.th', '023334444', NULL, '111 ถนนงามวงศ์วาน', 12, NULL, '0105562012357', 'customer', 'social_media', '80000000.00', 60, 4, 3, NULL, '2026-05-16 14:03:09', '2026-01-01 16:42:13'),
(14, 'บริษัท รีเทล พลัส จำกัด', 'company', 'Retail', 'https://retailplus.co.th', 'sales@retailplus.co.th', '024445555', NULL, '222 ถนนแจ้งวัฒนะ', 12, NULL, '0105562012358', 'customer', 'referral', '250000000.00', 300, 5, 4, NULL, '2026-04-26 14:03:09', '2026-01-01 16:42:13'),
(15, 'บริษัท ฟู้ด เซอร์วิส จำกัด', 'company', 'Food & Beverage', 'https://foodservice.co.th', 'contact@foodservice.co.th', '025556666', NULL, '333 ถนนติวานนท์', 12, NULL, '0105562012359', 'customer', 'advertisement', '120000000.00', 150, 4, 5, NULL, '2026-03-27 14:03:09', '2026-01-01 16:42:13'),
(16, 'บริษัท เชียงใหม่ เทค จำกัด', 'company', 'Technology', 'https://cmtech.co.th', 'info@cmtech.co.th', '053111222', NULL, '123 ถนนนิมมานเหมินท์', 50, NULL, '0105562012360', 'customer', 'website', '40000000.00', 35, 4, 5, NULL, '2026-02-25 14:03:09', '2026-01-01 16:42:13'),
(17, 'บริษัท อีสาน ซอฟต์ จำกัด', 'company', 'Software', 'https://esansoft.co.th', 'contact@esansoft.co.th', '043222333', NULL, '456 ถนนมิตรภาพ', 40, NULL, '0105562012361', 'prospect', 'cold_call', '25000000.00', 20, 3, 1, NULL, '2026-11-02 14:03:09', '2026-01-01 16:42:13'),
(18, 'บริษัท ภูเก็ต ดิจิทัล จำกัด', 'company', 'Technology', 'https://phuketdigital.co.th', 'hello@phuketdigital.co.th', '076333444', NULL, '789 ถนนทวีวงศ์', 83, NULL, '0105562012362', 'lead', 'social_media', '35000000.00', 25, 3, 1, NULL, '2026-11-25 14:03:09', '2026-01-01 16:42:13'),
(19, 'บริษัท ออโต้ พาร์ท จำกัด', 'company', 'Automotive', 'https://autopart.co.th', 'sales@autopart.co.th', '026667777', NULL, '444 ถนนเพชรบุรี', 10, NULL, '0105562012363', 'customer', 'trade_show', '400000000.00', 400, 5, 1, NULL, '2026-02-05 14:03:09', '2026-01-01 16:42:13'),
(20, 'บริษัท คอนสตรัคชั่น โปร จำกัด', 'company', 'Construction', 'https://constructionpro.co.th', 'info@constructionpro.co.th', '027778888', NULL, '555 ถนนพระราม 9', 10, NULL, '0105562012364', 'customer', 'referral', '600000000.00', 800, 5, 4, NULL, '2026-12-17 14:03:09', '2026-01-01 16:42:13'),
(21, 'คุณวิชัย ธรรมรัตน์', 'individual', 'Consulting', NULL, 'wichai@gmail.com', '0811112222', NULL, '123 หมู่บ้านเมืองทอง', 10, NULL, NULL, 'customer', 'referral', NULL, NULL, 4, 3, NULL, '2026-08-24 14:03:09', '2026-01-01 16:42:13'),
(22, 'คุณสุภาพร จิตรดี', 'individual', 'Training', '', 'supaporn@gmail.com', '0822223333', '', '456 คอนโด ลุมพินี', 10, '', '', 'prospect', 'website', '0.00', 0, 3, 2, '', '2026-11-20 14:03:09', '2026-01-01 16:42:13'),
(23, 'บริษัท นิว เทค สตาร์ทอัพ จำกัด', 'company', 'Technology', 'https://newtechstartup.co.th', 'info@newtechstartup.co.th', '028889999', NULL, '666 ถนนรามคำแหง', 10, NULL, '0105562012365', 'lead', 'website', '10000000.00', 15, 2, 3, NULL, '2026-12-01 14:03:09', '2026-01-01 16:42:13'),
(24, 'บริษัท เอไอ โซลูชัน จำกัด', 'company', 'AI/ML', 'https://aisolution.co.th', 'contact@aisolution.co.th', '029990000', '', '777 ถนนศรีนครินทร์', 10, '', '105562012366', 'lead', 'social_media', '20000000.00', 20, 0, 4, '', '2026-12-02 14:03:09', '2026-01-01 16:42:13'),
(25, 'บริษัท บล็อกเชน ไทย จำกัด', 'individual', 'Blockchain', 'https://blockchainthai.co.th', 'hello@blockchainthai.co.th', '020001111', '1234567890', '888 ถนนเจริญกรุง', 71, '71000', '1234567890123', 'churned', 'other', '10000000.00', 10, 5, 4, '', '2026-12-02 14:03:09', '2026-01-01 16:42:13');

INSERT INTO `{prefix}_deals` (`id`, `title`, `customer_id`, `contact_id`, `pipeline_id`, `stage_id`, `stage`, `value`, `currency`, `probability`, `expected_close_date`, `actual_close_date`, `lost_reason`, `owner_id`, `source`, `priority`, `notes`, `created_at`, `updated_at`) VALUES
(1, 'ERP System Implementation', 8, 7, 0, 0, 'lost', '1650000.00', 'THB', 100, '2025-11-27', NULL, '', 4, 'website', 'high', '', '2026-12-03 07:03:09', '2026-01-01 09:43:08'),
(2, 'CRM Pro License', 11, 10, 1, 5, 'lead', '300000.00', 'THB', 100, '2025-11-22', '2026-01-22', NULL, 4, 'referral', 'medium', NULL, '2026-12-18 07:03:09', '2026-01-01 09:43:08'),
(3, 'Annual Support Contract', 9, 8, 1, 5, 'proposal', '120000.00', 'THB', 100, '2025-11-17', '2026-02-17', NULL, 7, 'upsell', 'medium', NULL, '2026-12-02 07:03:09', '2026-01-28 12:43:29'),
(4, 'Server Infrastructure', 10, 9, 1, 5, 'lost', '785000.00', 'THB', 100, '2025-10-28', '2026-03-28', NULL, 3, 'cold_call', 'high', NULL, '2026-09-03 07:03:09', '2026-01-14 07:20:24'),
(5, 'HR Management System', 14, NULL, 1, 5, 'won', '250000.00', 'THB', 100, '2025-10-23', '2026-04-23', NULL, 4, 'referral', 'medium', NULL, '2026-09-13 07:03:09', '2026-01-01 09:43:08'),
(6, 'Cloud Migration Project', 6, NULL, 1, 6, 'won', '500000.00', 'THB', 0, '2025-11-24', '2026-05-24', NULL, 3, 'website', 'high', NULL, '2026-10-13 07:03:09', '2026-01-01 09:43:08'),
(7, 'Network Upgrade', 7, NULL, 1, 6, 'won', '350000.00', 'THB', 0, '2025-10-18', '2026-06-18', NULL, 7, '', 'medium', NULL, '2026-08-24 07:03:09', '2026-01-01 09:43:08'),
(8, 'ERP Consultation', 1, 1, 0, 0, 'won', '200000.00', 'THB', 25, '2026-01-01', '2026-07-20', '', 3, 'website', 'medium', '', '2026-11-30 07:03:09', '2026-01-01 09:43:08'),
(9, 'IT Infrastructure Review', 2, 3, 1, 2, 'won', '150000.00', 'THB', 25, '2026-01-16', '2026-08-21', NULL, 4, 'referral', 'medium', NULL, '2026-11-29 07:03:09', '2026-01-01 09:43:08'),
(10, 'Software Assessment', 3, NULL, 1, 1, 'won', '100000.00', 'THB', 10, '2026-01-31', '2026-09-12', NULL, 3, 'cold_call', 'low', NULL, '2026-11-27 07:03:09', '2026-01-01 09:43:08'),
(11, 'ERP Standard Package', 4, 5, 1, 3, 'won', '650000.00', 'THB', 50, '2025-12-17', '2026-10-01', NULL, 4, 'website', 'high', NULL, '2026-11-12 07:03:09', '2026-01-01 09:43:08'),
(12, 'Cloud Services Bundle', 5, 6, 1, 3, 'won', '480000.00', 'THB', 50, '2025-12-22', '2026-11-02', NULL, 6, '', 'high', NULL, '2026-11-07 07:03:09', '2026-01-01 09:43:08'),
(13, 'Enterprise Software Suite', 19, NULL, 2, 11, 'negotiation', '2500000.00', 'THB', 80, '2025-12-09', NULL, NULL, 7, '', 'urgent', NULL, '2026-10-18 07:03:09', '2026-01-01 09:43:08'),
(14, 'Data Analytics Platform', 20, NULL, 2, 11, 'lead', '1800000.00', 'THB', 80, '2025-12-12', NULL, NULL, 4, 'referral', 'high', NULL, '2026-10-03 07:03:09', '2026-01-15 03:37:51'),
(15, 'Training Program', 13, NULL, 1, 2, 'won', '70000.00', 'THB', 25, '2026-01-01', '2026-12-01', NULL, 3, '', 'medium', NULL, '2026-11-22 07:03:09', '2026-01-01 09:43:08'),
(16, 'Consulting Services', 12, NULL, 1, 3, 'won', '250000.00', 'THB', 50, '2025-12-27', NULL, NULL, 6, 'website', 'medium', NULL, '2026-11-17 07:03:09', '2026-01-01 09:43:08'),
(17, 'Monthly Maintenance Contract', 15, NULL, 1, 4, 'negotiation', '180000.00', 'THB', 75, '2025-12-07', NULL, NULL, 6, 'upsell', 'medium', NULL, '2026-11-02 07:03:09', '2026-01-01 09:43:08'),
(18, 'Regional Expansion Project', 16, NULL, 1, 2, 'qualified', '350000.00', 'THB', 25, '2026-01-31', '2026-01-01', NULL, 6, 'website', 'medium', NULL, '2026-11-27 07:03:09', '2026-01-15 03:37:47'),
(37, 'Initial Consultation Request', 23, NULL, 1, 1, 'proposal', '50000.00', 'THB', 10, '2026-01-28', NULL, NULL, 3, 'website', 'medium', NULL, '2026-12-29 08:57:40', '2026-01-01 09:43:08'),
(38, 'Software Demo Interest', 24, NULL, 1, 1, 'qualified', '75000.00', 'THB', 10, '2026-02-12', NULL, NULL, 4, 'website', 'low', NULL, '2026-12-29 08:57:40', '2026-01-01 09:43:08');

INSERT INTO `{prefix}_tasks` (`id`, `title`, `description`, `customer_id`, `contact_id`, `deal_id`, `owner_id`, `assigned_to`, `due_date`, `due_time`, `priority`, `status`, `completed_at`, `reminder_at`, `created_at`, `updated_at`) VALUES
(1, 'ส่งเอกสารเพิ่มเติม', 'ส่งเอกสาร specification ให้ลูกค้า', 4, NULL, 11, 4, 4, '2025-11-30', NULL, 'high', 'pending', NULL, NULL, '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(2, 'ติดตามการชำระเงิน', 'ติดตามการชำระเงินงวดแรก', 9, NULL, 3, 7, 7, '2025-12-01', NULL, 'high', 'pending', NULL, NULL, '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(3, 'โทรยืนยันนัดหมาย', 'โทรยืนยันการประชุมพรุ่งนี้', 5, NULL, 12, 6, 6, '2025-12-02', NULL, 'medium', 'pending', NULL, NULL, '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(4, 'เตรียม presentation', 'เตรียมเอกสารสำหรับการนำเสนอ', 19, NULL, 13, 7, 7, '2025-12-02', NULL, 'high', 'in_progress', NULL, NULL, '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(5, 'ร่างสัญญา', 'ร่างสัญญาและส่งให้ฝ่ายกฎหมายตรวจ', 19, NULL, 13, 7, 7, '2025-12-04', NULL, 'high', 'pending', NULL, NULL, '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(6, 'ส่ง quotation', 'ส่งใบเสนอราคาให้ลูกค้า', 1, NULL, 8, 3, 3, '2025-12-05', NULL, 'medium', 'pending', NULL, NULL, '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(7, 'นัดหมาย demo', 'ประสานงานนัด demo ให้ลูกค้า', 2, NULL, 9, 4, 4, '2025-12-06', NULL, 'medium', 'pending', NULL, NULL, '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(8, 'จัดเตรียมการติดตั้ง', 'เตรียมทีมและอุปกรณ์สำหรับการติดตั้ง', 8, NULL, 1, 4, 3, '2025-12-09', NULL, 'high', 'pending', NULL, NULL, '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(9, 'Training Schedule', 'วางแผนการอบรมผู้ใช้งาน', 8, NULL, 1, 4, 4, '2025-12-12', NULL, 'medium', 'pending', NULL, NULL, '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(10, 'ส่ง proposal', 'ส่ง proposal ให้ลูกค้า', 5, NULL, 12, 6, 6, '2025-11-29', NULL, 'high', 'completed', NULL, NULL, '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(11, 'สำรวจความต้องการ', 'สำรวจและจัดทำเอกสาร requirement', 4, NULL, 11, 4, 4, '2025-11-27', NULL, 'high', 'completed', NULL, NULL, '2025-12-02 07:03:09', '2025-12-02 07:03:09');

INSERT INTO `{prefix}_teams` (`id`, `name`, `description`, `manager_id`, `target_monthly`, `target_quarterly`, `target_yearly`, `status`, `created_at`, `updated_at`) VALUES
(1, 'ทีมขายกรุงเทพ', 'ทีมขายพื้นที่กรุงเทพและปริมณฑล', 2, '5000000.00', '15000000.00', '60000000.00', 'active', '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(2, 'ทีมขายภูมิภาค', 'ทีมขายพื้นที่ต่างจังหวัด', 5, '3000000.00', '9000000.00', '36000000.00', 'active', '2025-12-02 07:03:09', '2025-12-02 07:03:09'),
(3, 'ทีมขายองค์กร', 'ทีมขายลูกค้าองค์กรขนาดใหญ่', 7, '10000000.00', '30000000.00', '120000000.00', 'active', '2025-12-02 07:03:09', '2025-12-02 07:03:09');
