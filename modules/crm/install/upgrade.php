<?php
/**
 * modules/crm/install/upgrade.php — พาฐานเดิมมาถึงสคีมาของโมดูล crm
 *
 * install/upgrade_core.php เรียกไฟล์นี้ให้เอง ตัวแปรที่ใช้ได้คือชุดเดียวกับที่
 * upgrade_core ใช้ : $db, $db_config, $prefix, $content, $config
 *
 * นิยามตารางอยู่ที่ modules/crm/install/database.sql ที่เดียว — ไฟล์นี้อ่าน
 * นิยามจากที่นั่นผ่าน ensureTable() และรายการคอลัมน์ด้านล่างถูกสร้างจากไฟล์
 * เดียวกัน จึงไม่มีนิยามชุดที่สองให้ค่อย ๆ ต่างกัน
 *
 * กฎเดียวกับ upgrade_core : ทุกเงื่อนไขถามว่า "ต้องแก้ไหม" ไม่ใช่ "ตอนนี้เป็นอะไร"
 */
if (!defined('ROOT_PATH')) {
    exit;
}

foreach ([
    'activities',
    'campaigns',
    'contacts',
    'customers',
    'deals',
    'tasks',
    'teams'
] as $_name) {
    $_table = $prefix.'_'.$_name;
    if (ensureTable($db, $prefix, $_table)) {
        $content[] = '<li class="correct">crm: สร้างตาราง '.$_name.'</li>';
    }
    // ⚠️ ต้องแปลงก่อนปรับคอลัมน์เสมอ — CONVERT TO CHARACTER SET เลื่อนชนิด TEXT
    // เป็น MEDIUMTEXT ถ้าแปลงทีหลังชนิดจะไม่ตรงกับที่ติดตั้งใหม่
    if (convertToInnoDB($db, $_table)) {
        $content[] = '<li class="correct">'.$_name.': แปลงเป็น InnoDB</li>';
    }
    if (convertToUtf8mb4($db, $_table)) {
        $content[] = '<li class="correct">'.$_name.': แปลงเป็น utf8mb4</li>';
    }
}

// activities — PRIMARY KEY และ AUTO_INCREMENT
//
// ⚠️ ตัวติดตั้งรุ่นเก่าประกาศคอลัมน์ id เป็น NOT NULL เฉย ๆ แล้วค่อยเติม
// PRIMARY KEY / AUTO_INCREMENT ด้วย ALTER TABLE ท้าย database.sql ซึ่ง
// ตัวปรับรุ่นไม่เคยรัน ไซต์ที่อัปเกรดจึงเพิ่มข้อมูลใหม่ไม่ได้เลย
if (!$db->indexExists($prefix.'_activities', 'PRIMARY')) {
    // ⚠️ ถ้าไซต์มีค่าซ้ำอยู่ก่อน (เช่น id เป็น 0 ทุกแถวเพราะไม่เคยมี AUTO_INCREMENT)
    // การเพิ่ม PRIMARY KEY จะล้มกลางคัน ต้องตรวจแล้วบอกให้ผู้ดูแลแก้เอง
    $_dup = $db->customQuery(
        "SELECT COUNT(*) AS `c` FROM (SELECT 1 FROM `".$prefix."_activities`
         GROUP BY `id` HAVING COUNT(*) > 1) `x`"
    );
    if (!empty($_dup) && (int) $_dup[0]->c > 0) {
        $content[] = '<li class="warning">activities: มีค่าซ้ำใน (id) อยู่ '
            .number_format((int) $_dup[0]->c).' ชุด จึงยังเพิ่ม PRIMARY KEY ไม่ได้ '
            .'กรุณาแก้ให้ไม่ซ้ำแล้วกดปรับรุ่นอีกครั้ง — ตัวปรับรุ่นจะไม่ลบให้เอง</li>';
    } else {
        $db->query("ALTER TABLE `".$prefix."_activities` ADD PRIMARY KEY (`id`)");
        $content[] = '<li class="correct">activities: เพิ่ม PRIMARY KEY</li>';
    }
}
if (ensureAutoIncrement($db, $prefix.'_activities', 'id', 'int(10) UNSIGNED')) {
    $content[] = '<li class="correct">activities: กำหนด id เป็น AUTO_INCREMENT</li>';
}
// activities
foreach ([
    'type' => ['enum(\'call\',\'meeting\',\'email\',\'task\',\'note\',\'lunch\',\'demo\',\'follow_up\')', false, null, '', ''],
    'subject' => ['varchar(255)', false, null, 'type', ''],
    'description' => ['mediumtext', true, null, 'subject', ''],
    'customer_id' => ['int(10) UNSIGNED', true, null, 'description', ''],
    'contact_id' => ['int(10) UNSIGNED', true, null, 'customer_id', ''],
    'deal_id' => ['int(10) UNSIGNED', true, null, 'contact_id', ''],
    'owner_id' => ['int(10) UNSIGNED', true, null, 'deal_id', ''],
    'start_time' => ['datetime', true, null, 'owner_id', ''],
    'end_time' => ['datetime', true, null, 'start_time', ''],
    'duration_minutes' => ['int(11)', true, null, 'end_time', ''],
    'location' => ['varchar(255)', true, null, 'duration_minutes', ''],
    'status' => ['enum(\'scheduled\',\'completed\',\'cancelled\',\'no_show\')', false, 'scheduled', 'location', ''],
    'outcome' => ['mediumtext', true, null, 'status', ''],
    'priority' => ['enum(\'low\',\'medium\',\'high\')', false, 'medium', 'outcome', ''],
    'reminder_at' => ['datetime', true, null, 'priority', '']
] as $_col => $_def) {
    if (ensureColumn($db, $prefix.'_activities', $_col, $_def[0], $_def[1], $_def[2], $_def[4], $_def[3])) {
        $content[] = '<li class="correct">activities: ปรับคอลัมน์ '.$_col.'</li>';
    }
}
// activities — คอลัมน์ที่ค่าปริยายเป็นฟังก์ชัน ใช้ addColumn (นิยามดิบ)
if (addColumn($db, $prefix.'_activities', 'created_at', "timestamp NOT NULL DEFAULT current_timestamp()", 'reminder_at')) {
    $content[] = '<li class="correct">activities: เพิ่มคอลัมน์ created_at</li>';
}
if (addColumn($db, $prefix.'_activities', 'updated_at', "timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()", 'created_at')) {
    $content[] = '<li class="correct">activities: เพิ่มคอลัมน์ updated_at</li>';
}
if (ensureIndexes($db, $prefix.'_activities', [
    'idx_type' => '`type`',
    'idx_customer' => '`customer_id`',
    'idx_contact' => '`contact_id`',
    'idx_deal' => '`deal_id`',
    'idx_owner' => '`owner_id`',
    'idx_status' => '`status`',
    'idx_start_time' => '`start_time`',
    'idx_created' => '`created_at`'
])) {
    $content[] = '<li class="correct">activities: ปรับดัชนี</li>';
}

// campaigns — PRIMARY KEY และ AUTO_INCREMENT
//
// ⚠️ ตัวติดตั้งรุ่นเก่าประกาศคอลัมน์ id เป็น NOT NULL เฉย ๆ แล้วค่อยเติม
// PRIMARY KEY / AUTO_INCREMENT ด้วย ALTER TABLE ท้าย database.sql ซึ่ง
// ตัวปรับรุ่นไม่เคยรัน ไซต์ที่อัปเกรดจึงเพิ่มข้อมูลใหม่ไม่ได้เลย
if (!$db->indexExists($prefix.'_campaigns', 'PRIMARY')) {
    // ⚠️ ถ้าไซต์มีค่าซ้ำอยู่ก่อน (เช่น id เป็น 0 ทุกแถวเพราะไม่เคยมี AUTO_INCREMENT)
    // การเพิ่ม PRIMARY KEY จะล้มกลางคัน ต้องตรวจแล้วบอกให้ผู้ดูแลแก้เอง
    $_dup = $db->customQuery(
        "SELECT COUNT(*) AS `c` FROM (SELECT 1 FROM `".$prefix."_campaigns`
         GROUP BY `id` HAVING COUNT(*) > 1) `x`"
    );
    if (!empty($_dup) && (int) $_dup[0]->c > 0) {
        $content[] = '<li class="warning">campaigns: มีค่าซ้ำใน (id) อยู่ '
            .number_format((int) $_dup[0]->c).' ชุด จึงยังเพิ่ม PRIMARY KEY ไม่ได้ '
            .'กรุณาแก้ให้ไม่ซ้ำแล้วกดปรับรุ่นอีกครั้ง — ตัวปรับรุ่นจะไม่ลบให้เอง</li>';
    } else {
        $db->query("ALTER TABLE `".$prefix."_campaigns` ADD PRIMARY KEY (`id`)");
        $content[] = '<li class="correct">campaigns: เพิ่ม PRIMARY KEY</li>';
    }
}
if (ensureAutoIncrement($db, $prefix.'_campaigns', 'id', 'int(10) UNSIGNED')) {
    $content[] = '<li class="correct">campaigns: กำหนด id เป็น AUTO_INCREMENT</li>';
}
// campaigns
foreach ([
    'name' => ['varchar(255)', false, null, '', ''],
    'description' => ['mediumtext', true, null, 'name', ''],
    'type' => ['enum(\'email\',\'social\',\'event\',\'webinar\',\'advertisement\',\'other\')', false, 'email', 'description', ''],
    'status' => ['enum(\'draft\',\'scheduled\',\'active\',\'paused\',\'completed\',\'cancelled\')', false, 'draft', 'type', ''],
    'budget' => ['decimal(15,2)', true, '0.00', 'status', ''],
    'actual_cost' => ['decimal(15,2)', true, '0.00', 'budget', ''],
    'start_date' => ['date', true, null, 'actual_cost', ''],
    'end_date' => ['date', true, null, 'start_date', ''],
    'target_leads' => ['int(11)', true, '0', 'end_date', ''],
    'actual_leads' => ['int(11)', true, '0', 'target_leads', ''],
    'target_revenue' => ['decimal(15,2)', true, '0.00', 'actual_leads', ''],
    'actual_revenue' => ['decimal(15,2)', true, '0.00', 'target_revenue', ''],
    'owner_id' => ['int(10) UNSIGNED', true, null, 'actual_revenue', '']
] as $_col => $_def) {
    if (ensureColumn($db, $prefix.'_campaigns', $_col, $_def[0], $_def[1], $_def[2], $_def[4], $_def[3])) {
        $content[] = '<li class="correct">campaigns: ปรับคอลัมน์ '.$_col.'</li>';
    }
}
// campaigns — คอลัมน์ที่ค่าปริยายเป็นฟังก์ชัน ใช้ addColumn (นิยามดิบ)
if (addColumn($db, $prefix.'_campaigns', 'created_at', "timestamp NOT NULL DEFAULT current_timestamp()", 'owner_id')) {
    $content[] = '<li class="correct">campaigns: เพิ่มคอลัมน์ created_at</li>';
}
if (addColumn($db, $prefix.'_campaigns', 'updated_at', "timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()", 'created_at')) {
    $content[] = '<li class="correct">campaigns: เพิ่มคอลัมน์ updated_at</li>';
}
if (ensureIndexes($db, $prefix.'_campaigns', [
    'idx_type' => '`type`',
    'idx_status' => '`status`',
    'idx_owner' => '`owner_id`',
    'idx_dates' => '`start_date`, `end_date`'
])) {
    $content[] = '<li class="correct">campaigns: ปรับดัชนี</li>';
}

// contacts — PRIMARY KEY และ AUTO_INCREMENT
//
// ⚠️ ตัวติดตั้งรุ่นเก่าประกาศคอลัมน์ id เป็น NOT NULL เฉย ๆ แล้วค่อยเติม
// PRIMARY KEY / AUTO_INCREMENT ด้วย ALTER TABLE ท้าย database.sql ซึ่ง
// ตัวปรับรุ่นไม่เคยรัน ไซต์ที่อัปเกรดจึงเพิ่มข้อมูลใหม่ไม่ได้เลย
if (!$db->indexExists($prefix.'_contacts', 'PRIMARY')) {
    // ⚠️ ถ้าไซต์มีค่าซ้ำอยู่ก่อน (เช่น id เป็น 0 ทุกแถวเพราะไม่เคยมี AUTO_INCREMENT)
    // การเพิ่ม PRIMARY KEY จะล้มกลางคัน ต้องตรวจแล้วบอกให้ผู้ดูแลแก้เอง
    $_dup = $db->customQuery(
        "SELECT COUNT(*) AS `c` FROM (SELECT 1 FROM `".$prefix."_contacts`
         GROUP BY `id` HAVING COUNT(*) > 1) `x`"
    );
    if (!empty($_dup) && (int) $_dup[0]->c > 0) {
        $content[] = '<li class="warning">contacts: มีค่าซ้ำใน (id) อยู่ '
            .number_format((int) $_dup[0]->c).' ชุด จึงยังเพิ่ม PRIMARY KEY ไม่ได้ '
            .'กรุณาแก้ให้ไม่ซ้ำแล้วกดปรับรุ่นอีกครั้ง — ตัวปรับรุ่นจะไม่ลบให้เอง</li>';
    } else {
        $db->query("ALTER TABLE `".$prefix."_contacts` ADD PRIMARY KEY (`id`)");
        $content[] = '<li class="correct">contacts: เพิ่ม PRIMARY KEY</li>';
    }
}
if (ensureAutoIncrement($db, $prefix.'_contacts', 'id', 'int(10) UNSIGNED')) {
    $content[] = '<li class="correct">contacts: กำหนด id เป็น AUTO_INCREMENT</li>';
}
// contacts
foreach ([
    'customer_id' => ['int(10) UNSIGNED', true, null, '', ''],
    'first_name' => ['varchar(100)', false, null, 'customer_id', ''],
    'last_name' => ['varchar(100)', true, null, 'first_name', ''],
    'email' => ['varchar(255)', true, null, 'last_name', ''],
    'phone' => ['varchar(50)', true, null, 'email', ''],
    'mobile' => ['varchar(50)', true, null, 'phone', ''],
    'job_title' => ['varchar(100)', true, null, 'mobile', ''],
    'department' => ['varchar(100)', true, null, 'job_title', ''],
    'is_primary' => ['tinyint(1)', false, '0', 'department', ''],
    'is_decision_maker' => ['tinyint(1)', false, '0', 'is_primary', ''],
    'linkedin' => ['varchar(255)', true, null, 'is_decision_maker', ''],
    'notes' => ['mediumtext', true, null, 'linkedin', ''],
    'status' => ['enum(\'active\',\'inactive\')', false, 'active', 'notes', ''],
    'owner_id' => ['int(10) UNSIGNED', true, null, 'status', '']
] as $_col => $_def) {
    if (ensureColumn($db, $prefix.'_contacts', $_col, $_def[0], $_def[1], $_def[2], $_def[4], $_def[3])) {
        $content[] = '<li class="correct">contacts: ปรับคอลัมน์ '.$_col.'</li>';
    }
}
// contacts — คอลัมน์ที่ค่าปริยายเป็นฟังก์ชัน ใช้ addColumn (นิยามดิบ)
if (addColumn($db, $prefix.'_contacts', 'created_at', "timestamp NOT NULL DEFAULT current_timestamp()", 'owner_id')) {
    $content[] = '<li class="correct">contacts: เพิ่มคอลัมน์ created_at</li>';
}
if (addColumn($db, $prefix.'_contacts', 'updated_at', "timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()", 'created_at')) {
    $content[] = '<li class="correct">contacts: เพิ่มคอลัมน์ updated_at</li>';
}
if (ensureIndexes($db, $prefix.'_contacts', [
    'idx_customer' => '`customer_id`',
    'idx_email' => '`email`',
    'idx_owner' => '`owner_id`',
    'idx_status' => '`status`'
])) {
    $content[] = '<li class="correct">contacts: ปรับดัชนี</li>';
}

// customers — PRIMARY KEY และ AUTO_INCREMENT
//
// ⚠️ ตัวติดตั้งรุ่นเก่าประกาศคอลัมน์ id เป็น NOT NULL เฉย ๆ แล้วค่อยเติม
// PRIMARY KEY / AUTO_INCREMENT ด้วย ALTER TABLE ท้าย database.sql ซึ่ง
// ตัวปรับรุ่นไม่เคยรัน ไซต์ที่อัปเกรดจึงเพิ่มข้อมูลใหม่ไม่ได้เลย
if (!$db->indexExists($prefix.'_customers', 'PRIMARY')) {
    // ⚠️ ถ้าไซต์มีค่าซ้ำอยู่ก่อน (เช่น id เป็น 0 ทุกแถวเพราะไม่เคยมี AUTO_INCREMENT)
    // การเพิ่ม PRIMARY KEY จะล้มกลางคัน ต้องตรวจแล้วบอกให้ผู้ดูแลแก้เอง
    $_dup = $db->customQuery(
        "SELECT COUNT(*) AS `c` FROM (SELECT 1 FROM `".$prefix."_customers`
         GROUP BY `id` HAVING COUNT(*) > 1) `x`"
    );
    if (!empty($_dup) && (int) $_dup[0]->c > 0) {
        $content[] = '<li class="warning">customers: มีค่าซ้ำใน (id) อยู่ '
            .number_format((int) $_dup[0]->c).' ชุด จึงยังเพิ่ม PRIMARY KEY ไม่ได้ '
            .'กรุณาแก้ให้ไม่ซ้ำแล้วกดปรับรุ่นอีกครั้ง — ตัวปรับรุ่นจะไม่ลบให้เอง</li>';
    } else {
        $db->query("ALTER TABLE `".$prefix."_customers` ADD PRIMARY KEY (`id`)");
        $content[] = '<li class="correct">customers: เพิ่ม PRIMARY KEY</li>';
    }
}
if (ensureAutoIncrement($db, $prefix.'_customers', 'id', 'int(11) UNSIGNED')) {
    $content[] = '<li class="correct">customers: กำหนด id เป็น AUTO_INCREMENT</li>';
}
// customers
foreach ([
    'name' => ['varchar(255)', false, null, '', ''],
    'company_type' => ['enum(\'company\',\'individual\')', false, 'company', 'name', ''],
    'industry' => ['varchar(100)', true, null, 'company_type', ''],
    'website' => ['varchar(255)', true, null, 'industry', ''],
    'email' => ['varchar(255)', true, null, 'website', ''],
    'phone' => ['varchar(10)', true, null, 'email', ''],
    'fax' => ['varchar(10)', true, null, 'phone', ''],
    'address' => ['mediumtext', true, null, 'fax', ''],
    'provinceID' => ['int(2)', true, null, 'address', ''],
    'zipcode' => ['varchar(5)', true, null, 'provinceID', ''],
    'tax_id' => ['varchar(13)', true, null, 'zipcode', ''],
    'status' => ['enum(\'lead\',\'prospect\',\'customer\',\'inactive\',\'churned\')', false, 'lead', 'tax_id', ''],
    'source' => ['enum(\'website\',\'referral\',\'cold_call\',\'advertisement\',\'trade_show\',\'social_media\',\'other\')', true, 'website', 'status', ''],
    'annual_revenue' => ['decimal(15,2)', true, null, 'source', ''],
    'employee_count' => ['int(11)', true, null, 'annual_revenue', ''],
    'rating' => ['tinyint(3) UNSIGNED', true, null, 'employee_count', '1-5 stars'],
    'owner_id' => ['int(11) UNSIGNED', true, null, 'rating', ''],
    'notes' => ['mediumtext', true, null, 'owner_id', '']
] as $_col => $_def) {
    if (ensureColumn($db, $prefix.'_customers', $_col, $_def[0], $_def[1], $_def[2], $_def[4], $_def[3])) {
        $content[] = '<li class="correct">customers: ปรับคอลัมน์ '.$_col.'</li>';
    }
}
// customers — คอลัมน์ที่ค่าปริยายเป็นฟังก์ชัน ใช้ addColumn (นิยามดิบ)
if (addColumn($db, $prefix.'_customers', 'created_at', "datetime NOT NULL DEFAULT current_timestamp()", 'notes')) {
    $content[] = '<li class="correct">customers: เพิ่มคอลัมน์ created_at</li>';
}
if (addColumn($db, $prefix.'_customers', 'updated_at', "datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()", 'created_at')) {
    $content[] = '<li class="correct">customers: เพิ่มคอลัมน์ updated_at</li>';
}
if (ensureIndexes($db, $prefix.'_customers', [
    'idx_status' => '`status`',
    'idx_owner' => '`owner_id`',
    'idx_industry' => '`industry`',
    'idx_source' => '`source`',
    'idx_created' => '`created_at`'
])) {
    $content[] = '<li class="correct">customers: ปรับดัชนี</li>';
}

// deals — PRIMARY KEY และ AUTO_INCREMENT
//
// ⚠️ ตัวติดตั้งรุ่นเก่าประกาศคอลัมน์ id เป็น NOT NULL เฉย ๆ แล้วค่อยเติม
// PRIMARY KEY / AUTO_INCREMENT ด้วย ALTER TABLE ท้าย database.sql ซึ่ง
// ตัวปรับรุ่นไม่เคยรัน ไซต์ที่อัปเกรดจึงเพิ่มข้อมูลใหม่ไม่ได้เลย
if (!$db->indexExists($prefix.'_deals', 'PRIMARY')) {
    // ⚠️ ถ้าไซต์มีค่าซ้ำอยู่ก่อน (เช่น id เป็น 0 ทุกแถวเพราะไม่เคยมี AUTO_INCREMENT)
    // การเพิ่ม PRIMARY KEY จะล้มกลางคัน ต้องตรวจแล้วบอกให้ผู้ดูแลแก้เอง
    $_dup = $db->customQuery(
        "SELECT COUNT(*) AS `c` FROM (SELECT 1 FROM `".$prefix."_deals`
         GROUP BY `id` HAVING COUNT(*) > 1) `x`"
    );
    if (!empty($_dup) && (int) $_dup[0]->c > 0) {
        $content[] = '<li class="warning">deals: มีค่าซ้ำใน (id) อยู่ '
            .number_format((int) $_dup[0]->c).' ชุด จึงยังเพิ่ม PRIMARY KEY ไม่ได้ '
            .'กรุณาแก้ให้ไม่ซ้ำแล้วกดปรับรุ่นอีกครั้ง — ตัวปรับรุ่นจะไม่ลบให้เอง</li>';
    } else {
        $db->query("ALTER TABLE `".$prefix."_deals` ADD PRIMARY KEY (`id`)");
        $content[] = '<li class="correct">deals: เพิ่ม PRIMARY KEY</li>';
    }
}
if (ensureAutoIncrement($db, $prefix.'_deals', 'id', 'int(10) UNSIGNED')) {
    $content[] = '<li class="correct">deals: กำหนด id เป็น AUTO_INCREMENT</li>';
}
// deals
foreach ([
    'title' => ['varchar(255)', false, null, '', ''],
    'customer_id' => ['int(10) UNSIGNED', false, null, 'title', ''],
    'contact_id' => ['int(10) UNSIGNED', true, null, 'customer_id', ''],
    'pipeline_id' => ['int(10) UNSIGNED', false, null, 'contact_id', ''],
    'stage_id' => ['int(10) UNSIGNED', false, null, 'pipeline_id', ''],
    'stage' => ['enum(\'lead\',\'qualified\',\'proposal\',\'negotiation\',\'won\',\'lost\')', false, 'lead', 'stage_id', ''],
    'value' => ['decimal(15,2)', false, '0.00', 'stage', ''],
    'currency' => ['varchar(3)', false, 'THB', 'value', ''],
    'probability' => ['tinyint(3) UNSIGNED', true, '0', 'currency', ''],
    'expected_close_date' => ['date', true, null, 'probability', ''],
    'actual_close_date' => ['date', true, null, 'expected_close_date', ''],
    'lost_reason' => ['varchar(255)', true, null, 'actual_close_date', ''],
    'owner_id' => ['int(10) UNSIGNED', true, null, 'lost_reason', ''],
    'source' => ['enum(\'website\',\'referral\',\'cold_call\',\'upsell\',\'cross_sell\',\'other\')', true, 'website', 'owner_id', ''],
    'priority' => ['enum(\'low\',\'medium\',\'high\',\'urgent\')', false, 'medium', 'source', ''],
    'notes' => ['mediumtext', true, null, 'priority', '']
] as $_col => $_def) {
    if (ensureColumn($db, $prefix.'_deals', $_col, $_def[0], $_def[1], $_def[2], $_def[4], $_def[3])) {
        $content[] = '<li class="correct">deals: ปรับคอลัมน์ '.$_col.'</li>';
    }
}
// deals — คอลัมน์ที่ค่าปริยายเป็นฟังก์ชัน ใช้ addColumn (นิยามดิบ)
if (addColumn($db, $prefix.'_deals', 'created_at', "timestamp NOT NULL DEFAULT current_timestamp()", 'notes')) {
    $content[] = '<li class="correct">deals: เพิ่มคอลัมน์ created_at</li>';
}
if (addColumn($db, $prefix.'_deals', 'updated_at', "timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()", 'created_at')) {
    $content[] = '<li class="correct">deals: เพิ่มคอลัมน์ updated_at</li>';
}
if (ensureIndexes($db, $prefix.'_deals', [
    'idx_customer' => '`customer_id`',
    'idx_contact' => '`contact_id`',
    'idx_pipeline' => '`pipeline_id`',
    'idx_stage' => '`stage_id`',
    'idx_stage_enum' => '`stage`',
    'idx_owner' => '`owner_id`',
    'idx_expected_close' => '`expected_close_date`',
    'idx_created' => '`created_at`',
    'idx_value' => '`value`'
])) {
    $content[] = '<li class="correct">deals: ปรับดัชนี</li>';
}

// tasks — PRIMARY KEY และ AUTO_INCREMENT
//
// ⚠️ ตัวติดตั้งรุ่นเก่าประกาศคอลัมน์ id เป็น NOT NULL เฉย ๆ แล้วค่อยเติม
// PRIMARY KEY / AUTO_INCREMENT ด้วย ALTER TABLE ท้าย database.sql ซึ่ง
// ตัวปรับรุ่นไม่เคยรัน ไซต์ที่อัปเกรดจึงเพิ่มข้อมูลใหม่ไม่ได้เลย
if (!$db->indexExists($prefix.'_tasks', 'PRIMARY')) {
    // ⚠️ ถ้าไซต์มีค่าซ้ำอยู่ก่อน (เช่น id เป็น 0 ทุกแถวเพราะไม่เคยมี AUTO_INCREMENT)
    // การเพิ่ม PRIMARY KEY จะล้มกลางคัน ต้องตรวจแล้วบอกให้ผู้ดูแลแก้เอง
    $_dup = $db->customQuery(
        "SELECT COUNT(*) AS `c` FROM (SELECT 1 FROM `".$prefix."_tasks`
         GROUP BY `id` HAVING COUNT(*) > 1) `x`"
    );
    if (!empty($_dup) && (int) $_dup[0]->c > 0) {
        $content[] = '<li class="warning">tasks: มีค่าซ้ำใน (id) อยู่ '
            .number_format((int) $_dup[0]->c).' ชุด จึงยังเพิ่ม PRIMARY KEY ไม่ได้ '
            .'กรุณาแก้ให้ไม่ซ้ำแล้วกดปรับรุ่นอีกครั้ง — ตัวปรับรุ่นจะไม่ลบให้เอง</li>';
    } else {
        $db->query("ALTER TABLE `".$prefix."_tasks` ADD PRIMARY KEY (`id`)");
        $content[] = '<li class="correct">tasks: เพิ่ม PRIMARY KEY</li>';
    }
}
if (ensureAutoIncrement($db, $prefix.'_tasks', 'id', 'int(10) UNSIGNED')) {
    $content[] = '<li class="correct">tasks: กำหนด id เป็น AUTO_INCREMENT</li>';
}
// tasks
foreach ([
    'title' => ['varchar(255)', false, null, '', ''],
    'description' => ['mediumtext', true, null, 'title', ''],
    'customer_id' => ['int(10) UNSIGNED', true, null, 'description', ''],
    'contact_id' => ['int(10) UNSIGNED', true, null, 'customer_id', ''],
    'deal_id' => ['int(10) UNSIGNED', true, null, 'contact_id', ''],
    'owner_id' => ['int(10) UNSIGNED', true, null, 'deal_id', ''],
    'assigned_to' => ['int(10) UNSIGNED', true, null, 'owner_id', ''],
    'due_date' => ['date', true, null, 'assigned_to', ''],
    'due_time' => ['time', true, null, 'due_date', ''],
    'priority' => ['enum(\'low\',\'medium\',\'high\',\'urgent\')', false, 'medium', 'due_time', ''],
    'status' => ['enum(\'pending\',\'in_progress\',\'completed\',\'cancelled\')', false, 'pending', 'priority', ''],
    'completed_at' => ['timestamp', true, null, 'status', ''],
    'reminder_at' => ['datetime', true, null, 'completed_at', '']
] as $_col => $_def) {
    if (ensureColumn($db, $prefix.'_tasks', $_col, $_def[0], $_def[1], $_def[2], $_def[4], $_def[3])) {
        $content[] = '<li class="correct">tasks: ปรับคอลัมน์ '.$_col.'</li>';
    }
}
// tasks — คอลัมน์ที่ค่าปริยายเป็นฟังก์ชัน ใช้ addColumn (นิยามดิบ)
if (addColumn($db, $prefix.'_tasks', 'created_at', "timestamp NOT NULL DEFAULT current_timestamp()", 'reminder_at')) {
    $content[] = '<li class="correct">tasks: เพิ่มคอลัมน์ created_at</li>';
}
if (addColumn($db, $prefix.'_tasks', 'updated_at', "timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()", 'created_at')) {
    $content[] = '<li class="correct">tasks: เพิ่มคอลัมน์ updated_at</li>';
}
if (ensureIndexes($db, $prefix.'_tasks', [
    'idx_customer' => '`customer_id`',
    'idx_deal' => '`deal_id`',
    'idx_owner' => '`owner_id`',
    'idx_assigned' => '`assigned_to`',
    'idx_due_date' => '`due_date`',
    'idx_status' => '`status`',
    'idx_priority' => '`priority`'
])) {
    $content[] = '<li class="correct">tasks: ปรับดัชนี</li>';
}

// teams — PRIMARY KEY และ AUTO_INCREMENT
//
// ⚠️ ตัวติดตั้งรุ่นเก่าประกาศคอลัมน์ id เป็น NOT NULL เฉย ๆ แล้วค่อยเติม
// PRIMARY KEY / AUTO_INCREMENT ด้วย ALTER TABLE ท้าย database.sql ซึ่ง
// ตัวปรับรุ่นไม่เคยรัน ไซต์ที่อัปเกรดจึงเพิ่มข้อมูลใหม่ไม่ได้เลย
if (!$db->indexExists($prefix.'_teams', 'PRIMARY')) {
    // ⚠️ ถ้าไซต์มีค่าซ้ำอยู่ก่อน (เช่น id เป็น 0 ทุกแถวเพราะไม่เคยมี AUTO_INCREMENT)
    // การเพิ่ม PRIMARY KEY จะล้มกลางคัน ต้องตรวจแล้วบอกให้ผู้ดูแลแก้เอง
    $_dup = $db->customQuery(
        "SELECT COUNT(*) AS `c` FROM (SELECT 1 FROM `".$prefix."_teams`
         GROUP BY `id` HAVING COUNT(*) > 1) `x`"
    );
    if (!empty($_dup) && (int) $_dup[0]->c > 0) {
        $content[] = '<li class="warning">teams: มีค่าซ้ำใน (id) อยู่ '
            .number_format((int) $_dup[0]->c).' ชุด จึงยังเพิ่ม PRIMARY KEY ไม่ได้ '
            .'กรุณาแก้ให้ไม่ซ้ำแล้วกดปรับรุ่นอีกครั้ง — ตัวปรับรุ่นจะไม่ลบให้เอง</li>';
    } else {
        $db->query("ALTER TABLE `".$prefix."_teams` ADD PRIMARY KEY (`id`)");
        $content[] = '<li class="correct">teams: เพิ่ม PRIMARY KEY</li>';
    }
}
if (ensureAutoIncrement($db, $prefix.'_teams', 'id', 'int(10) UNSIGNED')) {
    $content[] = '<li class="correct">teams: กำหนด id เป็น AUTO_INCREMENT</li>';
}
// teams
foreach ([
    'name' => ['varchar(100)', false, null, '', ''],
    'description' => ['mediumtext', true, null, 'name', ''],
    'manager_id' => ['int(10) UNSIGNED', true, null, 'description', ''],
    'target_monthly' => ['decimal(15,2)', true, '0.00', 'manager_id', ''],
    'target_quarterly' => ['decimal(15,2)', true, '0.00', 'target_monthly', ''],
    'target_yearly' => ['decimal(15,2)', true, '0.00', 'target_quarterly', ''],
    'status' => ['enum(\'active\',\'inactive\')', false, 'active', 'target_yearly', '']
] as $_col => $_def) {
    if (ensureColumn($db, $prefix.'_teams', $_col, $_def[0], $_def[1], $_def[2], $_def[4], $_def[3])) {
        $content[] = '<li class="correct">teams: ปรับคอลัมน์ '.$_col.'</li>';
    }
}
// teams — คอลัมน์ที่ค่าปริยายเป็นฟังก์ชัน ใช้ addColumn (นิยามดิบ)
if (addColumn($db, $prefix.'_teams', 'created_at', "timestamp NOT NULL DEFAULT current_timestamp()", 'status')) {
    $content[] = '<li class="correct">teams: เพิ่มคอลัมน์ created_at</li>';
}
if (addColumn($db, $prefix.'_teams', 'updated_at', "timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()", 'created_at')) {
    $content[] = '<li class="correct">teams: เพิ่มคอลัมน์ updated_at</li>';
}
if (ensureIndexes($db, $prefix.'_teams', [
    'idx_manager' => '`manager_id`'
])) {
    $content[] = '<li class="correct">teams: ปรับดัชนี</li>';
}

// login_attempts — ตารางกันล็อกอินซ้ำรุ่นแรกของ crm ที่เลิกใช้แล้ว
// ถูกแทนด้วยตารางแกน {prefix}_login_attempt (เอกพจน์) ไม่มีโค้ดไหนอ้างแล้ว
// ⚠️ ลบทิ้งได้เฉพาะตอนที่ว่างจริง ถ้ายังมีข้อมูลให้เก็บเป็น _bak
$_old_attempts = $prefix.'_login_attempts';
if ($db->tableExists($_old_attempts)) {
    $_rows = $db->customQuery("SELECT COUNT(*) AS `c` FROM `$_old_attempts`");
    $_count = empty($_rows) ? 0 : (int) $_rows[0]->c;
    if ($_count === 0) {
        $db->query("DROP TABLE `$_old_attempts`");
        noteTableDropped($_old_attempts);
        $content[] = '<li class="correct">login_attempts: ลบตารางที่เลิกใช้แล้ว (ว่าง)</li>';
    } elseif (!$db->tableExists($_old_attempts.'_bak')) {
        $db->query("RENAME TABLE `$_old_attempts` TO `".$_old_attempts."_bak`");
        noteRowsMoved($_old_attempts, $_old_attempts.'_bak', $_count);
        $content[] = '<li class="warning">login_attempts: เลิกใช้แล้วแต่ยังมีข้อมูล '
            .number_format($_count).' แถว จึงเก็บไว้เป็น '.$_old_attempts.'_bak</li>';
    }
}

$content[] = '<li class="correct">crm อัปเกรดสำเร็จ</li>';
