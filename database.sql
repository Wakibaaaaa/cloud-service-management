-- CLOUD SERVICE (SaaS, PaaS, IaaS)USER AND RESOURCE MANAGEMENT SYSTEM
-- LOOKUP TABLES
CREATE TABLE UserRoles (
 role_id INT PRIMARY KEY AUTO_INCREMENT,
 role_name VARCHAR(50) NOT NULL UNIQUE,
 role_description VARCHAR(255)
);
CREATE TABLE AccountStatuses (
 status_id INT PRIMARY KEY AUTO_INCREMENT,
 status_name VARCHAR(20) NOT NULL UNIQUE
);
CREATE TABLE ResourceTypes (
 resource_type_id INT PRIMARY KEY AUTO_INCREMENT,
 type_name VARCHAR(50) NOT NULL UNIQUE,
 type_category VARCHAR(50) NOT NULL
);
CREATE TABLE TicketCategories (
 category_id INT PRIMARY KEY AUTO_INCREMENT,
 category_name VARCHAR(50) NOT NULL UNIQUE
);
CREATE TABLE PriorityLevels (
 priority_id INT PRIMARY KEY AUTO_INCREMENT,
 priority_name VARCHAR(20) NOT NULL UNIQUE,
 priority_rank INT NOT NULL
);
CREATE TABLE BillingCycles (
 cycle_id INT PRIMARY KEY AUTO_INCREMENT,
 cycle_name VARCHAR(10) NOT NULL UNIQUE,
 months_count INT NOT NULL
);
CREATE TABLE SupportLevels (
 support_level_id INT PRIMARY KEY AUTO_INCREMENT,
 level_name VARCHAR(50) NOT NULL UNIQUE,
 response_time_hrs INT,
 level_description VARCHAR(255)
);
CREATE TABLE PlanTiers (
 tier_id INT PRIMARY KEY AUTO_INCREMENT,
 tier_name VARCHAR(20) NOT NULL UNIQUE,
 max_discount DECIMAL(5,2) DEFAULT 0.00
);
CREATE TABLE PaymentMethods (
 method_id INT PRIMARY KEY AUTO_INCREMENT,
 method_name VARCHAR(50) NOT NULL UNIQUE
);
CREATE TABLE InvoiceStatuses (
 invoice_status_id INT PRIMARY KEY AUTO_INCREMENT,
 status_name VARCHAR(20) NOT NULL UNIQUE
);
CREATE TABLE SubscriptionStatuses (
 sub_status_id INT PRIMARY KEY AUTO_INCREMENT,
 status_name VARCHAR(20) NOT NULL UNIQUE
);
CREATE TABLE PaymentStatuses (
 pay_status_id INT PRIMARY KEY AUTO_INCREMENT,
 status_name VARCHAR(20) NOT NULL UNIQUE
);
CREATE TABLE ResourceStatuses (
 res_status_id INT PRIMARY KEY AUTO_INCREMENT,
 status_name VARCHAR(20) NOT NULL UNIQUE
);
CREATE TABLE TicketStatuses (
 ticket_status_id INT PRIMARY KEY AUTO_INCREMENT,
 status_name VARCHAR(20) NOT NULL UNIQUE
);
CREATE TABLE CompanySizes (
 size_id INT PRIMARY KEY AUTO_INCREMENT,
 size_name VARCHAR(20) NOT NULL UNIQUE,
 employee_min INT,
 employee_max INT
);
CREATE TABLE Currencies (
 currency_id INT PRIMARY KEY AUTO_INCREMENT,
 currency_code VARCHAR(10) NOT NULL UNIQUE,
 currency_symbol VARCHAR(5),
 exchange_to_usd DECIMAL(10,6) DEFAULT 1.000000
);
-- CORE TABLES
CREATE TABLE ServiceTypes (
 service_type_id INT PRIMARY KEY AUTO_INCREMENT,
 type_name VARCHAR(10) NOT NULL UNIQUE,
 type_description TEXT
);
CREATE TABLE SubscriptionPlans (
 plan_id INT PRIMARY KEY AUTO_INCREMENT,
 service_type_id INT NOT NULL,
 tier_id INT NOT NULL,
 support_level_id INT NOT NULL,
 plan_name VARCHAR(100) NOT NULL,
 monthly_price DECIMAL(10,2) DEFAULT 0.00,
 annual_price DECIMAL(10,2) DEFAULT 0.00,
 max_users INT DEFAULT 1,
 FOREIGN KEY (service_type_id) REFERENCES
ServiceTypes(service_type_id),
 FOREIGN KEY (tier_id) REFERENCES
PlanTiers(tier_id),
 FOREIGN KEY (support_level_id) REFERENCES
SupportLevels(support_level_id)
);
CREATE TABLE Organizations (
 org_id INT PRIMARY KEY AUTO_INCREMENT,
 size_id INT,
 org_name VARCHAR(200) NOT NULL,
 industry VARCHAR(100),
 country VARCHAR(100),
 email VARCHAR(150) UNIQUE,
 FOREIGN KEY (size_id) REFERENCES CompanySizes(size_id)
);
CREATE TABLE Users (
 user_id INT PRIMARY KEY AUTO_INCREMENT,
 org_id INT,
 role_id INT NOT NULL,
 status_id INT NOT NULL,
 username VARCHAR(100) NOT NULL UNIQUE,
 email VARCHAR(150) NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,
 full_name VARCHAR(200),
 mfa_enabled TINYINT(1) DEFAULT 0,
 created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (org_id) REFERENCES Organizations(org_id),
 FOREIGN KEY (role_id) REFERENCES UserRoles(role_id),
 FOREIGN KEY (status_id) REFERENCES
AccountStatuses(status_id)
);
CREATE TABLE UserSubscriptions (
 subscription_id INT PRIMARY KEY AUTO_INCREMENT,
 user_id INT NOT NULL,
 plan_id INT NOT NULL,
 cycle_id INT NOT NULL,
 sub_status_id INT NOT NULL,
 start_date DATE NOT NULL,
 end_date DATE,
 discount_percent DECIMAL(5,2) DEFAULT 0.00,
 FOREIGN KEY (user_id) REFERENCES Users(user_id),
 FOREIGN KEY (plan_id) REFERENCES
SubscriptionPlans(plan_id),
 FOREIGN KEY (cycle_id) REFERENCES
BillingCycles(cycle_id),
 FOREIGN KEY (sub_status_id) REFERENCES
SubscriptionStatuses(sub_status_id)
);
CREATE TABLE Resources (
 resource_id INT PRIMARY KEY AUTO_INCREMENT,
 subscription_id INT NOT NULL,
 user_id INT NOT NULL,
 resource_type_id INT NOT NULL,
 res_status_id INT NOT NULL,
 resource_name VARCHAR(200) NOT NULL,
 region VARCHAR(100),
 ip_address VARCHAR(50),
 allocated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (subscription_id) REFERENCES
UserSubscriptions(subscription_id),
 FOREIGN KEY (user_id) REFERENCES Users(user_id),
 FOREIGN KEY (resource_type_id) REFERENCES
ResourceTypes(resource_type_id),
 FOREIGN KEY (res_status_id) REFERENCES
ResourceStatuses(res_status_id)
);
CREATE TABLE ResourceUsage (
 usage_id INT PRIMARY KEY AUTO_INCREMENT,
 resource_id INT NOT NULL,
 recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
 cpu_usage_pct DECIMAL(5,2) CHECK (cpu_usage_pct BETWEEN
0 AND 100),
 memory_usage_pct DECIMAL(5,2) CHECK (memory_usage_pct
BETWEEN 0 AND 100),
 storage_used_gb DECIMAL(10,2) CHECK (storage_used_gb >= 0),
 uptime_hours DECIMAL(8,2) CHECK (uptime_hours >= 0),
 error_count INT DEFAULT 0 CHECK (error_count
>= 0),
 FOREIGN KEY (resource_id) REFERENCES Resources(resource_id)
);
CREATE TABLE Invoices (
 invoice_id INT PRIMARY KEY AUTO_INCREMENT,
 user_id INT NOT NULL,
 subscription_id INT NOT NULL,
 invoice_status_id INT NOT NULL,
 currency_id INT NOT NULL,
 invoice_number VARCHAR(50) NOT NULL UNIQUE,
 invoice_date DATE NOT NULL,
 due_date DATE NOT NULL,
 subtotal_amount DECIMAL(12,2) DEFAULT 0.00 CHECK
(subtotal_amount >= 0),
 tax_rate DECIMAL(5,2) DEFAULT 0.00 CHECK (tax_rate
>= 0),
 total_amount DECIMAL(12,2) DEFAULT 0.00 CHECK
(total_amount >= 0),
 FOREIGN KEY (user_id) REFERENCES Users(user_id),
 FOREIGN KEY (subscription_id) REFERENCES
UserSubscriptions(subscription_id),
 FOREIGN KEY (invoice_status_id) REFERENCES
InvoiceStatuses(invoice_status_id),
 FOREIGN KEY (currency_id) REFERENCES
Currencies(currency_id)
);
CREATE TABLE Payments (
 payment_id INT PRIMARY KEY AUTO_INCREMENT,
 invoice_id INT NOT NULL,
 user_id INT NOT NULL,
 method_id INT NOT NULL,
 pay_status_id INT NOT NULL,
 amount_paid DECIMAL(12,2) NOT NULL CHECK (amount_paid >=
0),
 payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
 transaction_id VARCHAR(200) UNIQUE,
 FOREIGN KEY (invoice_id) REFERENCES Invoices(invoice_id),
 FOREIGN KEY (user_id) REFERENCES Users(user_id),
 FOREIGN KEY (method_id) REFERENCES
PaymentMethods(method_id),
 FOREIGN KEY (pay_status_id) REFERENCES
PaymentStatuses(pay_status_id)
);
CREATE TABLE SupportTickets (
 ticket_id INT PRIMARY KEY AUTO_INCREMENT,
 user_id INT NOT NULL,
 resource_id INT,
 category_id INT NOT NULL,
 priority_id INT NOT NULL,
 ticket_status_id INT NOT NULL,
 ticket_number VARCHAR(50) NOT NULL UNIQUE,
 subject VARCHAR(255) NOT NULL,
 created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
 resolved_at DATETIME NULL,
 FOREIGN KEY (user_id) REFERENCES Users(user_id),
 FOREIGN KEY (resource_id) REFERENCES
Resources(resource_id),
 FOREIGN KEY (category_id) REFERENCES
TicketCategories(category_id),
 FOREIGN KEY (priority_id) REFERENCES
PriorityLevels(priority_id),
 FOREIGN KEY (ticket_status_id) REFERENCES
TicketStatuses(ticket_status_id)
);
-- INSERT SAMPLE DATA
INSERT INTO UserRoles (role_name, role_description) VALUES
('SuperAdmin', 'Full system access and control'),
('Admin', 'Organization level admin access'),
('Developer', 'Development resource access'),
('User', 'Standard end user access');
INSERT INTO AccountStatuses (status_name) VALUES
('Active'), ('Suspended'), ('Inactive');
INSERT INTO ResourceTypes (type_name, type_category) VALUES
('VM', 'Compute'),
('Storage', 'Storage'),
('Container', 'Compute'),
('Database', 'Database'),
('App', 'Business'),
('API', 'Network'),
('Network', 'Network');
INSERT INTO TicketCategories (category_name) VALUES
('Billing'), ('Technical'), ('Account'), ('General');
INSERT INTO PriorityLevels (priority_name, priority_rank)
VALUES
('Low', 1), ('Medium', 2), ('High', 3), ('Critical', 4);
INSERT INTO BillingCycles (cycle_name, months_count) VALUES
('Monthly', 1), ('Annual', 12);
INSERT INTO SupportLevels (level_name, response_time_hrs,
level_description) VALUES
('Basic', 72, 'Email support only'),
('Standard', 24, 'Email and chat support'),
('Premium', 4, 'Email chat and phone with dedicated
manager');
INSERT INTO PlanTiers (tier_name, max_discount) VALUES
('Free', 0.00), ('Basic', 5.00), ('Pro', 15.00), ('Enterprise',
25.00);
INSERT INTO PaymentMethods (method_name) VALUES
('CreditCard'), ('BankTransfer'), ('PayPal');
INSERT INTO InvoiceStatuses (status_name) VALUES
('Pending'), ('Paid'), ('Overdue'), ('Cancelled');
INSERT INTO SubscriptionStatuses (status_name) VALUES
('Active'), ('Expired'), ('Cancelled'), ('Suspended');
INSERT INTO PaymentStatuses (status_name) VALUES
('Completed'), ('Failed'), ('Pending');
INSERT INTO ResourceStatuses (status_name) VALUES
('Running'), ('Stopped'), ('Terminated'), ('Pending'),
('Error');
INSERT INTO TicketStatuses (status_name) VALUES
('Open'), ('InProgress'), ('Resolved'), ('Closed');
INSERT INTO CompanySizes (size_name, employee_min,
employee_max) VALUES
('Small', 1, 50),
('Medium', 51, 500),
('Large', 501, 5000),
('Enterprise', 5001, NULL);
INSERT INTO Currencies (currency_code, currency_symbol,
exchange_to_usd) VALUES
('USD', '$', 1.000000),
('EUR', 'EUR', 1.080000),
('GBP', 'GBP', 1.270000);
INSERT INTO ServiceTypes (type_name, type_description) VALUES
('SaaS', 'Software as a Service - Managed software over the
internet'),
('PaaS', 'Platform as a Service - Platform for app
development'),
('IaaS', 'Infrastructure as a Service - Virtual computing
infrastructure');
INSERT INTO SubscriptionPlans
 (service_type_id, tier_id, support_level_id,
 plan_name, monthly_price, annual_price, max_users)
VALUES
(1, 2, 2, 'SaaS Basic', 29.99, 299.99, 5),
(1, 3, 3, 'SaaS Pro', 79.99, 799.99, 25),
(1, 4, 3, 'SaaS Enterprise', 299.99, 2999.99, 999),
(2, 2, 2, 'PaaS Starter', 49.99, 499.99, 3),
(2, 3, 3, 'PaaS Developer', 149.99, 1499.99, 10),
(2, 4, 3, 'PaaS Business', 499.99, 4999.99, 50),
(3, 2, 2, 'IaaS Basic', 39.99, 399.99, 2),
(3, 3, 3, 'IaaS Advanced', 199.99, 1999.99, 10),
(3, 4, 3, 'IaaS Enterprise', 999.99, 9999.99, 999);
INSERT INTO Organizations (org_name, industry, country, email,
size_id) VALUES
('TechNova Solutions', 'Technology', 'United States',
'admin@technova.com', 2),
('DataSphere Analytics', 'Data Analytics', 'United
Kingdom','contact@datasphere.co', 1),
('CloudBridge Corp', 'Finance', 'Germany', 
'info@cloudbridge.de', 3),
('InnoStart Inc', 'Startup', 'India', 
'hello@innostart.in', 1),
('GlobalRetail Ltd', 'Retail', 'Australia', 
'tech@globalretail.com', 4);
INSERT INTO Users
 (org_id, role_id, status_id, username,
 email, password_hash, full_name, mfa_enabled)
VALUES
(1, 2, 1, 'john.smith', 'john.smith@technova.com', 
'hash_001', 'John Smith', 1),
(1, 3, 1, 'sarah.jones', 'sarah.jones@technova.com', 
'hash_002', 'Sarah Jones', 0),
(2, 2, 1, 'emma.wilson', 'emma.wilson@datasphere.co', 
'hash_003', 'Emma Wilson', 1),
(2, 3, 1, 'liam.taylor', 'liam.taylor@datasphere.co', 
'hash_004', 'Liam Taylor', 0),
(3, 2, 1, 'anna.mueller', 'anna.mueller@cloudbridge.de', 
'hash_005', 'Anna Mueller', 1),
(3, 4, 2, 'hans.becker', 'hans.becker@cloudbridge.de', 
'hash_006', 'Hans Becker', 0),
(4, 2, 1, 'priya.sharma', 'priya.sharma@innostart.in', 
'hash_007', 'Priya Sharma', 1),
(5, 2, 1, 'james.brown', 'james.brown@globalretail.com', 
'hash_008', 'James Brown', 1),
(5, 3, 1, 'olivia.davis', 'olivia.davis@globalretail.com',
'hash_009', 'Olivia Davis', 1),
(NULL, 1, 1, 'super.admin', 'superadmin@cloudsvc.com', 
'hash_000', 'Super Admin', 1);
INSERT INTO UserSubscriptions
 (user_id, plan_id, cycle_id, sub_status_id,
 start_date, end_date, discount_percent)
VALUES
(1, 2, 2, 1, '2024-01-01', '2024-12-31', 10.00),
(2, 1, 1, 1, '2024-03-01', NULL, 0.00),
(3, 5, 2, 1, '2024-02-01', '2025-01-31', 5.00),
(4, 4, 1, 1, '2024-04-01', NULL, 0.00),
(5, 9, 2, 1, '2023-06-01', '2024-05-31', 15.00),
(6, 7, 1, 4, '2024-01-01', NULL, 0.00),
(7, 1, 1, 1, '2024-05-01', NULL, 0.00),
(8, 3, 2, 1, '2024-01-15', '2025-01-14', 20.00),
(9, 8, 1, 1, '2024-03-15', NULL, 0.00);
INSERT INTO Resources
 (subscription_id, user_id, resource_type_id, res_status_id,
 resource_name, region, ip_address)
VALUES
(1, 1, 1, 1, 'TechNova-WebServer-01', 'US East', 
'54.23.12.100'),
(1, 1, 2, 1, 'TechNova-SSD-Storage-01', 'US East', 
NULL),
(2, 2, 3, 1, 'TechNova-AppContainer-01', 'US East', 
NULL),
(3, 3, 4, 1, 'DataSphere-PostgresDB-01', 'EU West', 
'10.0.1.50'),
(4, 4, 6, 1, 'DataSphere-API-Gateway-01', 'EU West', 
NULL),
(5, 5, 1, 1, 'CloudBridge-VM-Large-01', 'EU Central', 
'34.89.45.22'),
(5, 5, 7, 1, 'CloudBridge-LoadBal-01', 'EU Central', 
'34.89.45.1'),
(6, 6, 1, 2, 'CloudBridge-VM-Small-01', 'EU Central', 
'34.89.45.88'),
(7, 7, 5, 1, 'InnoStart-CRM-App-01', 'Asia Pacific', 
NULL),
(8, 8, 5, 1, 'GlobalRetail-Analytics-01', 'Asia Tokyo', 
NULL),
(9, 9, 1, 1, 'GlobalRetail-VM-Med-01', 'Asia Tokyo', 
'13.115.23.44');
INSERT INTO ResourceUsage
 (resource_id, cpu_usage_pct, memory_usage_pct,
 storage_used_gb, uptime_hours, error_count)
VALUES
(1, 65.20, 72.50, 80.00, 720, 2),
(2, NULL, NULL, 420.00, 720, 0),
(3, 45.00, 55.00, 30.00, 720, 5),
(4, 30.00, 45.00, 85.00, 720, 1),
(5, NULL, NULL, NULL, 720, 3),
(6, 78.00, 85.00, 500.00, 720, 8),
(7, 15.00, 20.00, NULL, 720, 0),
(8, 0.00, 0.00, 10.00, 0, 0),
(9, NULL, NULL, NULL, 720, 0),
(10, NULL, NULL, 850.00, 720, 2),
(11, 55.00, 62.00, 200.00, 720, 4);
INSERT INTO Invoices
 (user_id, subscription_id, invoice_status_id, currency_id,
 invoice_number, invoice_date, due_date,
 subtotal_amount, tax_rate, total_amount)
VALUES
(1, 1, 2, 1, 'INV-2024-001', '2024-01-01', '2024-01-15', 
719.99, 8.00, 777.59),
(2, 2, 2, 1, 'INV-2024-002', '2024-03-01', '2024-03-15', 
29.99, 8.00, 32.39),
(3, 3, 2, 1, 'INV-2024-003', '2024-02-01', '2024-02-15',
1424.99, 8.00, 1709.98),
(5, 5, 2, 1, 'INV-2024-004', '2024-01-01', '2024-01-15',
8499.99, 8.00,10114.99),
(7, 7, 2, 1, 'INV-2024-005', '2024-05-01', '2024-05-15', 
0.00, 0.00, 0.00),
(8, 8, 2, 1, 'INV-2024-006', '2024-01-15', '2024-01-30', 
239.99, 8.00, 263.99),
(9, 9, 2, 1, 'INV-2024-007', '2024-03-15', '2024-03-30', 
199.99, 8.00, 219.99),
(2, 2, 1, 1, 'INV-2024-008', '2024-04-01', '2024-04-15', 
29.99, 8.00, 32.39),
(9, 9, 3, 1, 'INV-2024-009', '2024-04-15', '2024-04-30', 
199.99, 8.00, 219.99);
INSERT INTO Payments
 (invoice_id, user_id, method_id, pay_status_id,
 amount_paid, transaction_id)
VALUES
(1, 1, 1, 1, 777.59, 'TXN-001'),
(2, 2, 3, 1, 32.39, 'TXN-002'),
(3, 3, 2, 1, 1709.98, 'TXN-003'),
(4, 5, 1, 1, 10114.99, 'TXN-004'),
(5, 7, 1, 1, 0.00, 'TXN-005'),
(6, 8, 1, 1, 263.99, 'TXN-006'),
(7, 9, 1, 1, 219.99, 'TXN-007');
INSERT INTO SupportTickets
 (user_id, resource_id, category_id, priority_id, ticket_status_id, ticket_number, subject)
VALUES
(1, 1, 2, 3, 3, 'TKT-001', 'VM running slow during peak
hours'),
(3, 4, 2, 4, 3, 'TKT-002', 'Database connection timeouts'),
(5, 6, 2, 2, 4, 'TKT-003', 'Request to increase VM resource
quota'),
(7, 9, 2, 3, 2, 'TKT-004', 'CRM app not loading for some
users'),
(8, 10, 1, 2, 1, 'TKT-005', 'Invoice billing discrepancy'),
(2, 3, 2, 3, 3, 'TKT-006', 'Container deployment failed'),
(9, 11, 2, 3, 2, 'TKT-007', 'Auto-scaling not working');
-- VIEWS
CREATE VIEW vw_ActiveSubscriptions AS
SELECT
 us.subscription_id,
 u.username,
 u.email,
 o.org_name,
 st.type_name AS service_type,
 sp.plan_name,
 pt.tier_name AS plan_tier,
 bc.cycle_name AS billing_cycle,
 us.start_date,
 us.end_date,
 ss.status_name AS status,
 ROUND(
 CASE
 WHEN bc.months_count = 1 THEN sp.monthly_price
 ELSE sp.annual_price / 12
 END, 2 ) AS monthly_cost
FROM UserSubscriptions us
JOIN Users u ON us.user_id =
u.user_id
JOIN SubscriptionPlans sp ON us.plan_id =
sp.plan_id
JOIN ServiceTypes st ON sp.service_type_id =
st.service_type_id
JOIN PlanTiers pt ON sp.tier_id =
pt.tier_id
JOIN BillingCycles bc ON us.cycle_id =
bc.cycle_id
JOIN SubscriptionStatuses ss ON us.sub_status_id =
ss.sub_status_id
LEFT JOIN Organizations o ON u.org_id =
o.org_id
WHERE ss.status_name = 'Active';
CREATE VIEW vw_ResourceHealth AS
SELECT
 r.resource_id,
 r.resource_name,
 rt.type_name AS resource_type,
 rt.type_category AS resource_category,
 rs.status_name AS status,
 r.region,
 u.username,
 o.org_name,
 ru.cpu_usage_pct,
 ru.memory_usage_pct,
 ru.storage_used_gb,
 ru.error_count,
 CASE WHEN ru.cpu_usage_pct >= 90
 OR ru.memory_usage_pct >= 90 THEN 'CRITICAL'
 WHEN ru.cpu_usage_pct >= 70
 OR ru.memory_usage_pct >= 70 THEN 'WARNING'
 WHEN rs.status_name = 'Running' THEN 'HEALTHY'
 WHEN rs.status_name = 'Stopped' THEN 'STOPPED'
 ELSE 'UNKNOWN'
 END AS health_status
FROM Resources r
JOIN ResourceTypes rt ON r.resource_type_id =
rt.resource_type_id
JOIN ResourceStatuses rs ON r.res_status_id =
rs.res_status_id
JOIN Users u ON r.user_id =
u.user_id
LEFT JOIN Organizations o ON u.org_id =
o.org_id
LEFT JOIN ResourceUsage ru ON r.resource_id =
ru.resource_id;
CREATE VIEW vw_BillingDashboard AS
SELECT
 u.username,
 o.org_name,
 i.invoice_number,
 i.invoice_date,
 i.due_date,
 i.total_amount,
 ins.status_name AS invoice_status,
 pm.method_name AS payment_method,
 ps.status_name AS payment_status,
 CASE
 WHEN ins.status_name = 'Overdue' THEN DATEDIFF(CURDATE(), i.due_date)
 ELSE 0
 END AS days_overdue
FROM Invoices i
JOIN Users u ON i.user_id =
u.user_id
JOIN InvoiceStatuses ins ON i.invoice_status_id =
ins.invoice_status_id
LEFT JOIN Organizations o ON u.org_id =
o.org_id
LEFT JOIN Payments p ON i.invoice_id =
p.invoice_id
LEFT JOIN PaymentMethods pm ON p.method_id =
pm.method_id
LEFT JOIN PaymentStatuses ps ON p.pay_status_id =
ps.pay_status_id;
-- STORED PROCEDURES
DELIMITER $$
CREATE PROCEDURE sp_CreateSubscription(
 IN p_user_id INT,
 IN p_plan_id INT,
 IN p_cycle_id INT,
 IN p_discount_pct DECIMAL(5,2),
 OUT p_subscription_id INT,
 OUT p_message VARCHAR(255)
)
BEGIN
 DECLARE v_user_exists INT DEFAULT 0;
 DECLARE v_plan_exists INT DEFAULT 0;
 DECLARE v_active_sid INT;
 DECLARE v_active_sub_sid INT;
 SELECT status_id INTO v_active_sid
 FROM AccountStatuses WHERE status_name = 'Active' LIMIT 1;
 SELECT sub_status_id INTO v_active_sub_sid
 FROM SubscriptionStatuses WHERE status_name = 'Active' LIMIT
1;
 SELECT COUNT(*) INTO v_user_exists
 FROM Users WHERE user_id = p_user_id AND status_id =
v_active_sid;
 SELECT COUNT(*) INTO v_plan_exists
 FROM SubscriptionPlans WHERE plan_id = p_plan_id;
 IF v_user_exists = 0 THEN
 SET p_subscription_id = NULL;
 SET p_message = 'ERROR: User not found or inactive';
 ELSEIF v_plan_exists = 0 THEN
 SET p_subscription_id = NULL;
 SET p_message = 'ERROR: Plan not found';
 ELSE
 INSERT INTO UserSubscriptions
 (user_id, plan_id, cycle_id, sub_status_id,
 start_date, discount_percent)
 VALUES
 (p_user_id, p_plan_id, p_cycle_id,
 v_active_sub_sid, CURDATE(), p_discount_pct);
 SET p_subscription_id = LAST_INSERT_ID();
 SET p_message = CONCAT('SUCCESS: Subscription ID: ',
 p_subscription_id);
 END IF;
END$$
CREATE PROCEDURE sp_GetUserProfile(IN p_user_id INT)
BEGIN
 SELECT
 u.user_id, u.username, u.email, u.full_name,
 ur.role_name AS user_role,
 ast.status_name AS account_status,
 o.org_name, o.industry
 FROM Users u
 JOIN UserRoles ur ON u.role_id = ur.role_id
 JOIN AccountStatuses ast ON u.status_id = ast.status_id
 LEFT JOIN Organizations o ON u.org_id = o.org_id
 WHERE u.user_id = p_user_id;
 SELECT
 us.subscription_id, sp.plan_name,
 st.type_name AS service_type,
 bc.cycle_name AS billing_cycle,
 ss.status_name AS status,
 us.start_date, us.end_date
 FROM UserSubscriptions us
 JOIN SubscriptionPlans sp ON us.plan_id =
sp.plan_id
 JOIN ServiceTypes st ON sp.service_type_id =
st.service_type_id
 JOIN BillingCycles bc ON us.cycle_id =
bc.cycle_id
 JOIN SubscriptionStatuses ss ON us.sub_status_id =
ss.sub_status_id
 WHERE us.user_id = p_user_id;
 SELECT r.resource_id, r.resource_name,
 rt.type_name AS resource_type,
 rs.status_name AS status,
 r.region
 FROM Resources r
 JOIN ResourceTypes rt ON r.resource_type_id =
rt.resource_type_id
 JOIN ResourceStatuses rs ON r.res_status_id =
rs.res_status_id
 WHERE r.user_id = p_user_id
 AND rs.status_name != 'Terminated';
 SELECT
 i.invoice_number, i.invoice_date, i.total_amount,
 ins.status_name AS invoice_status,
 ps.status_name AS payment_status
 FROM Invoices i
 JOIN InvoiceStatuses ins ON i.invoice_status_id =
ins.invoice_status_id
 LEFT JOIN Payments p ON i.invoice_id =
p.invoice_id
 LEFT JOIN PaymentStatuses ps ON p.pay_status_id =
ps.pay_status_id
 WHERE i.user_id = p_user_id
 ORDER BY i.invoice_date DESC;
END$$
CREATE PROCEDURE sp_ToggleUserStatus(
 IN p_target_user_id INT,
 IN p_admin_user_id INT,
 IN p_new_status VARCHAR(20),
 OUT p_message VARCHAR(255)
)
BEGIN
 DECLARE v_current_status VARCHAR(20);
 DECLARE v_admin_role VARCHAR(50);
 DECLARE v_new_status_id INT;
 SELECT ast.status_name INTO v_current_status
 FROM Users u JOIN AccountStatuses ast ON u.status_id =
ast.status_id
 WHERE u.user_id = p_target_user_id LIMIT 1;
 SELECT ur.role_name INTO v_admin_role
 FROM Users u JOIN UserRoles ur ON u.role_id = ur.role_id
 WHERE u.user_id = p_admin_user_id LIMIT 1;
 SELECT status_id INTO v_new_status_id
 FROM AccountStatuses WHERE status_name = p_new_status LIMIT
1;
 IF v_admin_role NOT IN ('SuperAdmin','Admin') THEN
 SET p_message = 'ERROR: Insufficient permissions';
 ELSEIF v_current_status IS NULL THEN
 SET p_message = 'ERROR: Target user not found';
 ELSEIF v_new_status_id IS NULL THEN
 SET p_message = CONCAT('ERROR: Invalid status: ',
p_new_status);
 ELSEIF v_current_status = p_new_status THEN
 SET p_message = CONCAT('INFO: Already ', p_new_status);
 ELSE
 UPDATE Users SET status_id = v_new_status_id
 WHERE user_id = p_target_user_id;
 SET p_message = CONCAT('SUCCESS: Changed from ',
 v_current_status, ' to ',
p_new_status);
 END IF;
END$$
CREATE PROCEDURE sp_GenerateInvoice(
 IN p_subscription_id INT,
 IN p_tax_rate DECIMAL(5,2),
 OUT p_invoice_id INT,
 OUT p_message VARCHAR(255)
)
BEGIN
 DECLARE v_user_id INT;
 DECLARE v_plan_id INT;
 DECLARE v_months INT;
 DECLARE v_discount_pct DECIMAL(5,2);
 DECLARE v_base_price DECIMAL(12,2);
 DECLARE v_subtotal DECIMAL(12,2);
 DECLARE v_total DECIMAL(12,2);
 DECLARE v_invoice_number VARCHAR(50);
 DECLARE v_inv_count INT;
 DECLARE v_usd_id INT;
 DECLARE v_pending_id INT;
 SELECT us.user_id, us.plan_id, bc.months_count,
us.discount_percent
 INTO v_user_id, v_plan_id, v_months, v_discount_pct
 FROM UserSubscriptions us
 JOIN BillingCycles bc ON us.cycle_id =
bc.cycle_id
 JOIN SubscriptionStatuses ss ON us.sub_status_id =
ss.sub_status_id
 WHERE us.subscription_id = p_subscription_id
 AND ss.status_name = 'Active'
 LIMIT 1;
 IF v_user_id IS NULL THEN
 SET p_invoice_id = NULL;
 SET p_message = 'ERROR: Active subscription not
found';
 ELSE
 SELECT CASE WHEN v_months = 1 THEN monthly_price
 ELSE annual_price END
 INTO v_base_price
 FROM SubscriptionPlans WHERE plan_id = v_plan_id LIMIT
1;
 SET v_subtotal = ROUND(v_base_price * (1 -
v_discount_pct / 100), 2);
 SET v_total = ROUND(v_subtotal * (1 + p_tax_rate 
/ 100), 2);
 SELECT COUNT(*) + 1 INTO v_inv_count FROM Invoices;
 SET v_invoice_number = CONCAT('INV-', YEAR(CURDATE()),
 '-', LPAD(v_inv_count, 5,
'0'));
 SELECT currency_id INTO v_usd_id
 FROM Currencies WHERE currency_code = 'USD' LIMIT 1;
 SELECT invoice_status_id INTO v_pending_id
 FROM InvoiceStatuses WHERE status_name = 'Pending' LIMIT
1;
 INSERT INTO Invoices
 (user_id, subscription_id, invoice_status_id,
currency_id,
 invoice_number, invoice_date, due_date, subtotal_amount, tax_rate, total_amount)
 VALUES
 (v_user_id, p_subscription_id, v_pending_id,
v_usd_id,
 v_invoice_number, CURDATE(),
 DATE_ADD(CURDATE(), INTERVAL 15 DAY),
 v_subtotal, p_tax_rate, v_total);
 SET p_invoice_id = LAST_INSERT_ID();
 SET p_message = CONCAT('SUCCESS: Invoice ',
v_invoice_number,
 ' | Sub: $', v_subtotal,
 ' | Tax: ', p_tax_rate,
'%',
 ' | Total: $', v_total);
 END IF;
END$$
DELIMITER ;
-- TRIGGERS
DELIMITER $$
CREATE TRIGGER trg_HighCPUAlert
AFTER INSERT ON ResourceUsage
FOR EACH ROW
BEGIN
 DECLARE v_resource_name VARCHAR(200);
 DECLARE v_user_id INT;
 DECLARE v_tech_cat_id INT;
 DECLARE v_high_pri_id INT;
 DECLARE v_open_status_id INT;
 IF NEW.cpu_usage_pct >= 85.00 THEN
 SELECT resource_name, user_id
 INTO v_resource_name, v_user_id
 FROM Resources WHERE resource_id = NEW.resource_id
LIMIT 1;
 SELECT category_id INTO v_tech_cat_id
 FROM TicketCategories WHERE category_name = 'Technical'
LIMIT 1;
 SELECT priority_id INTO v_high_pri_id
 FROM PriorityLevels WHERE priority_name = 'High' LIMIT
1;
 SELECT ticket_status_id INTO v_open_status_id
 FROM TicketStatuses WHERE status_name = 'Open' LIMIT 1;
 INSERT INTO SupportTickets
 (user_id, resource_id, category_id, priority_id,
 ticket_status_id, ticket_number, subject)
 VALUES
 (v_user_id, NEW.resource_id,
 v_tech_cat_id, v_high_pri_id, v_open_status_id,
 CONCAT('AUTO-', NEW.resource_id, '-',
UNIX_TIMESTAMP()),
 CONCAT('High CPU Alert: ', v_resource_name,
 ' at ', NEW.cpu_usage_pct, '%'));
 END IF;
END$$
CREATE TRIGGER trg_UpdateInvoiceOnPayment
AFTER INSERT ON Payments
FOR EACH ROW
BEGIN
 DECLARE v_completed_id INT;
 DECLARE v_paid_id INT;
 SELECT pay_status_id INTO v_completed_id
 FROM PaymentStatuses WHERE status_name = 'Completed' LIMIT
1;
 SELECT invoice_status_id INTO v_paid_id
 FROM InvoiceStatuses WHERE status_name = 'Paid' LIMIT 1;
 IF NEW.pay_status_id = v_completed_id THEN
 UPDATE Invoices SET invoice_status_id = v_paid_id
 WHERE invoice_id = NEW.invoice_id;
 END IF;
END$$
CREATE TRIGGER trg_AdminMFAAlert
AFTER UPDATE ON Users
FOR EACH ROW
BEGIN
 DECLARE v_active_status_id INT;
 DECLARE v_admin_role_id INT;
 DECLARE v_tech_cat_id INT;
 DECLARE v_critical_pri_id INT;
 DECLARE v_open_status_id INT;
 SELECT status_id INTO v_active_status_id
 FROM AccountStatuses WHERE status_name = 'Active' LIMIT 1;
 SELECT role_id INTO v_admin_role_id
 FROM UserRoles WHERE role_name = 'Admin' LIMIT 1;
 IF NEW.status_id = v_active_status_id
 AND NEW.mfa_enabled = 0
 AND NEW.role_id = v_admin_role_id THEN
 SELECT category_id INTO v_tech_cat_id
 FROM TicketCategories WHERE category_name = 'Technical'
LIMIT 1;
 SELECT priority_id INTO v_critical_pri_id
 FROM PriorityLevels WHERE priority_name = 'Critical'
LIMIT 1;
 SELECT ticket_status_id INTO v_open_status_id
 FROM TicketStatuses WHERE status_name = 'Open' LIMIT 1;
 INSERT INTO SupportTickets
 (user_id, resource_id, category_id, priority_id,
 ticket_status_id, ticket_number, subject)
 VALUES
 (NEW.user_id, NULL,
 v_tech_cat_id, v_critical_pri_id, v_open_status_id,
 CONCAT('SEC-', NEW.user_id, '-', UNIX_TIMESTAMP()),
 CONCAT('Security Alert: Admin ',
 NEW.username, ' has no MFA enabled'));
 END IF;
END$$
DELIMITER ;