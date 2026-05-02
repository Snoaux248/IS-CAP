drop database if exists project;
create database project;
use project;

create table User_(
	user_id bigint not null auto_increment,
    user_name varchar(30) not null,
    user_start_date date not null DEFAULT(current_date),
    user_email varchar(30) not null, 
    user_account_status int not null DEFAULT(1), # 0 = unactive, 1 = active, 2 = pending deletion
    user_type int not null, # 0 influencer, 1 brand
    
constraint Users_pk primary key(user_id)
);

create table Influencer(
	user_id bigint not null,
    handle varchar(20) not null,
    payment_info bigint not null,
    niche varchar(20) not null,
    platform varchar(15) not null,
    
constraint Influencer_pk primary key(user_id),
constraint Influencer_fk foreign key(user_id) references User_(user_id)
);

create table Brand(
	user_id bigint not null,
    company_name varchar(30) not null,
    account_routing_number bigint not null,
    industry varchar(30) not null,
constraint Brand_pk primary key(user_id),
constraint Brand_fk foreign key(user_id) references User_(user_id)
);

create table Category(
	category_id bigint not null auto_increment,
    category_name varchar(20) not null,
    
constraint Category_pk primary key(category_id)
);

create table Campaign(
	campaign_id bigint not null auto_increment,
    campaign_title varchar(20) not null,
    campaign_budget double not null,
    campaign_start_date date not null,
    campaign_end_date date not null,
    campaign_status int not null,
    campaign_objective linestring,
    brand_id bigint not null,

constraint Campaign_pk primary key(campaign_id),
constraint CampaignBrand_fk foreign key(brand_id) references User_(user_id)
);

create table Application(
	user_id bigint,
	campaign_id bigint not null,
	application_pitch linestring not null,
	application_proposed_rate double not null,
	application_status int not null,
	application_date date not null,
    
constraint Application_pk primary key(user_id, campaign_id),
constraint ApplicationUser_fk foreign key(user_id) references User_(user_id),
constraint ApplicationCampaign_fk foreign key(campaign_id) references Campaign(campaign_id)
);

create table Contract(
	contract_id bigint not null auto_increment,
	contract_terms linestring not null,
	contract_agreed_rate double not null,
	contract_start_date date not null,
	contract_end_date date not null,
	contract_status int not null,
	influencer_user_id bigint not null,
	brand_user_id bigint not null,
    
constraint Contract_pk primary key(contract_id),
constraint ContractInfluencer_fk foreign key(influencer_user_id) references User_(user_id),
constraint ContractBrand_fk foreign key(brand_user_id) references User_(user_id)
);

create table Payment(
	payment_id bigint not null auto_increment,
    payment_amount double not null,
    paid_at date,
    payment_method varchar(30) not null,
    payment_status int not null,
    contract_id bigint not null,
    
constraint Payment_pk primary key(payment_id),
constraint PaymentContract_fk foreign key(contract_id) references Contract(contract_id)
);

create table Deliverable(
	deliverable_id bigint not null auto_increment,
    deliverable_type int not null,
    deliverable_platform varchar(15) not null,
    deliverable_due_date date not null,
    deliverable_status int not null,
    submission_url linestring not null,
    contract_id bigint not null,
    
constraint Deliverable_pk primary key(deliverable_id),
constraint DeliverableContract_fk foreign key(contract_id) references Contract(contract_id)
);

create table MetricSnapshots(
	deliverable_id bigint not null auto_increment,
    snapshot_time time not null,
    snapshot_views int not null,
    snapshot_likes int not null,
    snapshot_comments int not null,
    snapshot_clicks int not null,
    
constraint MetricSnapshots_pk primary key(deliverable_id, snapshot_time),
constraint MetricSnapshotDeliverable_fk foreign key(deliverable_id) references Deliverable(deliverable_id)
);

create table InfluencerTags(
	influencer_id bigint not null,
    category_id bigint not null,

constraint InfluencerTags_pk primary key(influencer_id, category_id),
constraint InfluencerTagsUser_fk foreign key(influencer_id) references Influencer(user_id),
constraint InfluencerTagsCategory_fk foreign key(category_id) references Category(category_id)
);

create table BrandTags(
	campaign_id bigint not null,
    category_id bigint not null,
    
constraint BrandTags_pk primary key(campaign_id, category_id),
constraint BrandTagsCampaign_fk foreign key(campaign_id) references Campaign(campaign_id),
constraint BrandTagsCategory_fk foreign key(category_id) references Category(category_id)
);









DELIMITER //
CREATE PROCEDURE User_insert(New_user_name varchar(30), New_user_email varchar(30), New_user_type int)
BEGIN
	INSERT INTO User_ (user_name, user_email, user_type)
    VALUES (New_user_name, New_user_email, New_user_type);
END //
DELIMITER ;

DELIMITER //

CREATE PROCEDURE Influencer_insert( IN New_user_name varchar(30), IN New_user_email varchar(30), IN New_user_type int,
								    IN New_handle varchar(20), IN New_payment_info bigint, IN New_niche varchar(20), IN New_platform varchar(15))
BEGIN
	CALL User_insert(New_user_name, New_user_email, New_user_type);
    
	INSERT INTO Influencer(user_id, handle, payment_info, niche, platform)
    SELECT user_id, New_handle, New_payment_info, New_niche, New_platform
    FROM User_
    WHERE User_.user_name = New_user_name
    AND User_.user_email = New_user_email
    AND User_.user_type = 0;
END //
DELIMITER;

DELIMITER //
CREATE PROCEDURE Brand_insert(IN New_user_name varchar(30), IN New_user_email varchar(30), IN New_user_type int,
							  IN New_company_name varchar(30), IN New_account_routing_number bigint, IN New_industry varchar(30))
BEGIN
	CALL User_insert(New_user_name, New_user_email, New_user_type);
    
	INSERT INTO Brand(user_id, company_name, account_routing_number, industry)
	SELECT user_id, New_company_name, New_account_routing_number, New_industry
    FROM User_
    WHERE User_.user_name = New_user_name
    AND User_.user_email = New_user_email
    AND User_.user_type = 1;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Category_insert(New_category_name varchar(20))
BEGIN
	INSERT INTO Category(category_name)
    VALUES (New_category);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Campaign_insert(title varchar(20), budget double, start_date date, end_date date, status_ int, objective linestring, New_brand_id bigint)
BEGIN
	INSERT INTO Campaign(campaign_title, campaign_budget, campaign_start_date, campaign_end_date, campaign_status, campaign_objective, brand_id)
    VALUES (title, budget, start_date, end_date, status_, objective, New_brand_id);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Application_insert(user_id bigint, New_campaign_id bigint, pitch linestring, proposed_rate double, status_ int, date_ date)
BEGIN 
	INSERT INTO Application(user_id, campaign_id, application_pitch, application_proposed_rate, application_status, application_date)
    VALUES (user_id, New_campaign_id, pitch, proposed_rate, status_, date_);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Application_copy(New_user_id bigint, New_campaign_id bigint, pitch linestring, proposed_rate double, status_ int, date_ date)
BEGIN 
	INSERT INTO Application(user_id, campaign_id, application_pitch, application_proposed_rate, application_status, application_date)
    VALUES (New_user_id, New_campaign_id, pitch, proposed_rate, status_, date_);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Contract_insert(New_contract_id bigint, terms linestring, agreed_rate double, start_date date, end_date date, status_ int, New_influencer_user_id bigint, New_brand_user_id bigint)
BEGIN
	INSERT INTO Contract(contract_id, contract_terms, contract_agreed_rate, contract_start_date, contract_end_date, status_, New_influencer_user_id, New_brand_user_id)
    VALUES (New_contract_id, terms, agreed_rate, start_date, end_date, status_, New_influencer_user_id, New_brand_user_id);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Payment_insert(New_amount double, New_paid_at date, method varchar(30), status_ int, New_contract_id bigint)
BEGIN
	INSERT INTO Payment(payment_amount, paid_at, payment_method, payment_status, contract_id)
    VALUES (New_amount, New_paid_at, method, status_, New_contract_id);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Deliverable_insert(type int, platform varchar(15), due_date date, status_ int, New_submission_url linestring, New_contract_id bigint)
BEGIN
	INSERT INTO Deliverable(deliverable_type, deliverable_platform, deliverable_due_date, deliverable_status, submission_url, contract_id)
    VALUES (type_, platform, due_date, status_, New_submission_url, New_contract_id)
END
DELIMITER ;


DELIMITER //
CREATE PROCEDURE MetricSnapshots_insert(time time, views int, likes int, comments int, clicks int)
BEGIN
	INSERT INTO MetricSnapshots(snapshot_time, snapshot_views, snapshot_likes, snapshot_comments, snapshot_clicks)
    VALUES (time_, views, likes, comments, clicks);
END //
DELIMITER

DELIMITER //
CREATE PROCEDURE InfluencerTags_insert(New_influencer_id bigint, New_category_id bigint)
BEGIN
	INSERT INTO InfluencerTags(influencer_id, category_id)
    VALUES (New_influencer_id, New_category_id);
END //
DELIMITER

DELIMITER //
CREATE PROCEDURE BrandTags_insert(New_campaign_id bigint, New_category_id bigint)
BEGIN
	INSERT INTO BrandTags(campaign_id, category_id)
    VALUES (New_campaign_id, New_category_id);
END //
DELIMITER







DELIMITER //
CREATE PROCEDURE Users_show()
BEGIN
	SELECT * FROM User_;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Influencers_show()
BEGIN
	SELECT * FROM User_
    JOIN Influencer ON User_.user_id = Influencer.user_id;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Brands_show()
BEGIN
	SELECT * FROM User_
    JOIN Brand ON User_.user_id = Brand.user_id;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Categories_show()
BEGIN
	SELECT * FROM Categories;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Campaigns_show()
BEGIN
	SELECT * FROM Campaign;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Applications_show_user(Find_user_id bigint)
BEGIN
	SELECT * FROM Application
    WHERE user_id = COALESCE(Find_user_id, user_id);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Applications_show_brand(Find_influencer_id bigint, Find_campaign_id bigint)
BEGIN
	SELECT * FROM Application 
    WHERE campaign_id = COALESCE(Find_campaign_id, campaign_id)
    AND user_id = COALESCE(Find_influencer_id, user_id);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Contracts_show_brand(Find_influencer_id bigint, Find_brand_id bigint)
BEGIN
	SELECT * FROM Contract
    WHERE brand_user_id = COALESCE(Find_brand_id, brand_user_id)
    AND influencer_user_id = COALESCE(Find_user_id, influencer_user_id);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Payments_show(Find_contract_id bigint, Find_influencer_id bigint, Find_brand_id bigint)
BEGIN
	SELECT * FROM Payment AS P
    JOIN Contract AS C ON p.contract_id = C.contract_id
    WHERE C.contract_id = COALESCE(Find_contract_id, C.contract_id)
    AND C.influencer_id = COALESCE(Find_influencer_id, C.influencer_id)
    AND C.brand_id = COALESCE(Find_brand_id, C.brand_id);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE Delivarables_show(Find_contract_id bigint)
BEGIN
	SELECT * FROM Delivarable
    WHERE contract_id = COALESCE(Find_contract_id, contract_id);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE MetricSnapshots_show(Find_contract_id bigint, Find_deliverable_id bigint, Find_influencer_id bigint, Find_brand_id bigint)
BEGIN
	SELECT * FROM MetricSnapshots AS M
    JOIN Deliverable AS D ON M.deliverable_id = D.deliverable_id
    JOIN Contract AS C ON D.contract_id = C.contract_id
    WHERE C.contract_id = COALESCE(Find_contract_id, C.contract_id)
    AND C.deliverable_id = COALESCE(Find_deliverable_id, C.deliverable_id)
    AND C.influencer_id = COALESCE(Find_influencer_id, C.influencer_id)
    AND C.brand_id = COALESCE(Find_brand_id, C.brand_id);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE InfluencerTags_show(Find_influencer_id bigint)
BEGIN
	SELECT * FROM InfluencerTags
    WHERE influencer_id = COALESCE(Find_influencer_id, influencer_id);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE BrandTags_show(Find_category_id bigint)
BEGIN
	SELECT * FROM BrandTags
    WHERE category_id = COALESCE(Find_category_id, category_id);
END //
DELIMITER ;













# create template application rows for campaigns (user_id is NULL for templates)
DELIMITER //
CREATE PROCEDURE ApplicationTemplate_insert(New_user_id bigint, New_campaign_id bigint, Template_pitch linestring, Template_proposed_rate double, Template_status int, Template_date date)
BEGIN
	INSERT INTO Application(user_id, campaign_id, application_pitch, application_proposed_rate, application_status, application_date)
    VALUES (New_user_id, New_campaign_id, Template_pitch, Template_proposed_rate, Template_status, Template_date);
END //
DELIMITER ;

# create direct submitted application rows by influencer users
DELIMITER //
CREATE PROCEDURE ApplicationSubmit_insert(New_user_id bigint, New_campaign_id bigint, New_pitch linestring, New_proposed_rate double, New_status int, New_date date)
BEGIN
	INSERT INTO Application(user_id, campaign_id, application_pitch, application_proposed_rate, application_status, application_date)
    VALUES (New_user_id, New_campaign_id, New_pitch, New_proposed_rate, New_status, New_date);
END //
DELIMITER ;

# create submitted applications from a campaign template with optional overrides using COALESCE
DELIMITER //
CREATE PROCEDURE ApplicationSubmitFromTemplate_insert(New_user_id bigint, New_campaign_id bigint, New_pitch linestring, New_proposed_rate double, New_status int, New_date date)
BEGIN
	INSERT INTO Application(user_id, campaign_id, application_pitch, application_proposed_rate, application_status, application_date)
    SELECT New_user_id, New_campaign_id,
		   COALESCE(New_pitch, A.application_pitch),
           COALESCE(New_proposed_rate, A.application_proposed_rate),
           COALESCE(New_status, A.application_status),
           COALESCE(New_date, A.application_date)
    FROM Application AS A
    WHERE A.user_id IS NULL
    AND A.campaign_id = New_campaign_id
    LIMIT 1;
END //
DELIMITER ;

--

# show only template rows
CREATE VIEW applicationtemplates_view AS
SELECT * FROM Application
WHERE user_id IN (SELECT user_id FROM Brand);
 
# show only submitted application rows
CREATE VIEW SubmittedApplications_view AS
SELECT *
FROM Application
WHERE user_id IN (SELECT user_id FROM Influencer);

# show detailed application records with user and campaign context
CREATE VIEW ApplicationDetails_view AS
SELECT A.user_id, A.campaign_id, A.application_pitch, A.application_proposed_rate, A.application_status, A.application_date,
	   U.user_name, U.user_email, C.campaign_title, C.brand_id
FROM Application AS A
LEFT JOIN User_ AS U ON A.user_id = U.user_id
JOIN Campaign AS C ON A.campaign_id = C.campaign_id;

# show each campaign and how many submitted applications it has
CREATE VIEW CampaignApplicationCounts_view AS
SELECT C.campaign_id, C.campaign_title, C.brand_id, COUNT(A.user_id) AS submitted_application_count
FROM Campaign AS C
LEFT JOIN Application AS A ON C.campaign_id = A.campaign_id AND A.user_id IN (SELECT user_id FROM Influencer)
GROUP BY C.campaign_id, C.campaign_title, C.brand_id;

# show pending submitted applications only
CREATE VIEW PendingApplications_view AS
SELECT *
FROM Application
WHERE user_id IN (SELECT user_id FROM Influencer)
AND application_status = 0;

# brand-facing view: brand campaigns and submitted applications to those campaigns
CREATE VIEW BrandUser_CampaignApplications_view AS
SELECT C.brand_id,
	   BUSER.user_name AS brand_name,
       C.campaign_id,
       C.campaign_title,
       A.user_id AS applicant_user_id,
       AUSER.user_name AS applicant_name,
       AUSER.user_email AS applicant_email,
       A.application_proposed_rate,
       A.application_status,
       A.application_date
FROM Campaign AS C
JOIN Application AS A ON C.campaign_id = A.campaign_id
JOIN User_ AS BUSER ON C.brand_id = BUSER.user_id
LEFT JOIN User_ AS AUSER ON A.user_id = AUSER.user_id
WHERE A.user_id IN (SELECT user_id FROM Influencer);

# influencer-facing view: each influencer's submitted applications and brand context
CREATE VIEW InfluencerUser_MyApplications_view AS
SELECT A.user_id AS influencer_user_id,
	   IUSER.user_name AS influencer_name,
       IUSER.user_email AS influencer_email,
       A.campaign_id,
       C.campaign_title,
       C.brand_id,
       BUSER.user_name AS brand_name,
       A.application_proposed_rate,
       A.application_status,
       A.application_date
FROM Application AS A
JOIN User_ AS IUSER ON A.user_id = IUSER.user_id
JOIN Campaign AS C ON A.campaign_id = C.campaign_id
JOIN User_ AS BUSER ON C.brand_id = BUSER.user_id
WHERE A.user_id IN (SELECT user_id FROM Influencer);

# admin/global view: include templates and submitted rows with explicit type label
CREATE VIEW AdminUser_AllApplications_view AS
SELECT A.user_id, A.campaign_id, A.application_pitch, A.application_proposed_rate, A.application_status, A.application_date,
       C.campaign_title, C.brand_id, BUSER.user_name AS brand_name,
       U.user_name AS applicant_name, U.user_email AS applicant_email,
       CASE WHEN A.user_id IS NULL THEN 'template' ELSE 'submitted' END AS application_type
FROM Application AS A
JOIN Campaign AS C ON A.campaign_id = C.campaign_id
JOIN User_ AS BUSER ON C.brand_id = BUSER.user_id
LEFT JOIN User_ AS U ON A.user_id = U.user_id;

# public view: open campaign templates available for applicants
CREATE VIEW PublicUser_OpenCampaignTemplates_view AS
SELECT C.campaign_id, C.campaign_title, C.brand_id, BUSER.user_name AS brand_name,
	   A.application_pitch AS template_pitch,
       A.application_proposed_rate,
       A.application_status,
       A.application_date
FROM Application AS A
JOIN Campaign AS C ON A.campaign_id = C.campaign_id
JOIN User_ AS BUSER ON C.brand_id = BUSER.user_id
WHERE A.user_id IS NULL;

# brand-focused pending queue view with campaign and applicant details
CREATE VIEW PendingApplicationsByBrand_view AS
SELECT C.brand_id,
	   BUSER.user_name AS brand_name,
       C.campaign_id,
       C.campaign_title,
       A.user_id AS applicant_user_id,
       AUSER.user_name AS applicant_name,
       AUSER.user_email AS applicant_email,
       A.application_proposed_rate,
       A.application_status,
       A.application_date
FROM Application AS A
JOIN Campaign AS C ON A.campaign_id = C.campaign_id
JOIN User_ AS BUSER ON C.brand_id = BUSER.user_id
LEFT JOIN User_ AS AUSER ON A.user_id = AUSER.user_id
WHERE A.user_id IN (SELECT user_id FROM Influencer)
AND A.application_status = 0;

--

# show templates view
DELIMITER //
CREATE PROCEDURE ApplicationTemplates_show()
BEGIN
	SELECT * FROM ApplicationTemplates_view;
END //
DELIMITER ;

# show submitted applications view
DELIMITER //
CREATE PROCEDURE SubmittedApplications_show()
BEGIN
	SELECT * FROM SubmittedApplications_view;
END //
DELIMITER ;

# show full application details view
DELIMITER //
CREATE PROCEDURE ApplicationDetails_show()
BEGIN
	SELECT * FROM ApplicationDetails_view;
END //
DELIMITER ;

# show campaign application counts view
DELIMITER //
CREATE PROCEDURE CampaignApplicationCounts_show()
BEGIN
	SELECT * FROM CampaignApplicationCounts_view;
END //
DELIMITER ;

# show pending submitted applications view
DELIMITER //
CREATE PROCEDURE PendingApplications_show()
BEGIN
	SELECT * FROM PendingApplications_view;
END //
DELIMITER ;

# show brand user campaign applications view
DELIMITER //
CREATE PROCEDURE BrandUser_CampaignApplications_show()
BEGIN
	SELECT * FROM BrandUser_CampaignApplications_view;
END //
DELIMITER ;

# show influencer user submitted applications view
DELIMITER //
CREATE PROCEDURE InfluencerUser_MyApplications_show()
BEGIN
	SELECT * FROM InfluencerUser_MyApplications_view;
END //
DELIMITER ;

# show admin/global application records view
DELIMITER //
CREATE PROCEDURE AdminUser_AllApplications_show()
BEGIN
	SELECT * FROM AdminUser_AllApplications_view;
END //
DELIMITER ;

# show public template discovery view
DELIMITER //
CREATE PROCEDURE PublicUser_OpenCampaignTemplates_show()
BEGIN
	SELECT * FROM PublicUser_OpenCampaignTemplates_view;
END //
DELIMITER ;

# show pending applications grouped by brand context view
DELIMITER //
CREATE PROCEDURE PendingApplicationsByBrand_show()
BEGIN
	SELECT * FROM PendingApplicationsByBrand_view;
END //
DELIMITER ;

/* ============================================================
   AI CODE: CHECK QUALITY - ROLE BASED ACCESS CONTROL
   ============================================================ */

# role definitions used to enforce different SQL access levels by user type (rubric: different views for different users)
CREATE ROLE IF NOT EXISTS 'admin_role', 'brand_role', 'influencer_role', 'public_role';

# admin role: full read access to all reporting views and execute on all project procedures for complete oversight
GRANT SELECT ON project.applicationtemplates_view TO 'admin_role';
GRANT SELECT ON project.SubmittedApplications_view TO 'admin_role';
GRANT SELECT ON project.ApplicationDetails_view TO 'admin_role';
GRANT SELECT ON project.CampaignApplicationCounts_view TO 'admin_role';
GRANT SELECT ON project.PendingApplications_view TO 'admin_role';
GRANT SELECT ON project.BrandUser_CampaignApplications_view TO 'admin_role';
GRANT SELECT ON project.InfluencerUser_MyApplications_view TO 'admin_role';
GRANT SELECT ON project.AdminUser_AllApplications_view TO 'admin_role';
GRANT SELECT ON project.PublicUser_OpenCampaignTemplates_view TO 'admin_role';
GRANT SELECT ON project.PendingApplicationsByBrand_view TO 'admin_role';
GRANT EXECUTE ON project.* TO 'admin_role';

# brand role: can see campaign/application views for brand decisions and run brand-facing show procedures
GRANT SELECT ON project.BrandUser_CampaignApplications_view TO 'brand_role';
GRANT SELECT ON project.PendingApplicationsByBrand_view TO 'brand_role';
GRANT SELECT ON project.CampaignApplicationCounts_view TO 'brand_role';
GRANT SELECT ON project.ApplicationDetails_view TO 'brand_role';
GRANT EXECUTE ON PROCEDURE project.BrandUser_CampaignApplications_show TO 'brand_role';
GRANT EXECUTE ON PROCEDURE project.PendingApplicationsByBrand_show TO 'brand_role';
GRANT EXECUTE ON PROCEDURE project.CampaignApplicationCounts_show TO 'brand_role';
GRANT EXECUTE ON PROCEDURE project.ApplicationDetails_show TO 'brand_role';

# influencer role: can see own/application-discovery views and run submission/show procedures needed for application workflow
GRANT SELECT ON project.InfluencerUser_MyApplications_view TO 'influencer_role';
GRANT SELECT ON project.PublicUser_OpenCampaignTemplates_view TO 'influencer_role';
GRANT SELECT ON project.SubmittedApplications_view TO 'influencer_role';
GRANT EXECUTE ON PROCEDURE project.InfluencerUser_MyApplications_show TO 'influencer_role';
GRANT EXECUTE ON PROCEDURE project.SubmittedApplications_show TO 'influencer_role';
GRANT EXECUTE ON PROCEDURE project.PublicUser_OpenCampaignTemplates_show TO 'influencer_role';
GRANT EXECUTE ON PROCEDURE project.ApplicationSubmit_insert TO 'influencer_role';
GRANT EXECUTE ON PROCEDURE project.ApplicationSubmitFromTemplate_insert TO 'influencer_role';

# public role: read-only discovery of open campaign templates (no private application data)
GRANT SELECT ON project.PublicUser_OpenCampaignTemplates_view TO 'public_role';
GRANT EXECUTE ON PROCEDURE project.PublicUser_OpenCampaignTemplates_show TO 'public_role';

# demo users for rubric/testing validation in a school environment
CREATE USER IF NOT EXISTS 'admin_demo'@'localhost' IDENTIFIED BY 'password123';
CREATE USER IF NOT EXISTS 'brand_demo'@'localhost' IDENTIFIED BY 'password123';
CREATE USER IF NOT EXISTS 'influencer_demo'@'localhost' IDENTIFIED BY 'password123';
CREATE USER IF NOT EXISTS 'public_demo'@'localhost' IDENTIFIED BY 'password123';

GRANT 'admin_role' TO 'admin_demo'@'localhost';
GRANT 'brand_role' TO 'brand_demo'@'localhost';
GRANT 'influencer_role' TO 'influencer_demo'@'localhost';
GRANT 'public_role' TO 'public_demo'@'localhost';

SET DEFAULT ROLE 'admin_role' TO 'admin_demo'@'localhost';
SET DEFAULT ROLE 'brand_role' TO 'brand_demo'@'localhost';
SET DEFAULT ROLE 'influencer_role' TO 'influencer_demo'@'localhost';
SET DEFAULT ROLE 'public_role' TO 'public_demo'@'localhost';

/* ============================================================
   AI CODE: CHECK QUALITY - ROLE BASED ACCESS CONTROL
   ============================================================ */


# add more brands to support broad test cases
CALL Brand_insert('Puma Team', 'puma@brand.com', 1, 'Puma', 3333000011, 'Apparel');
CALL Brand_insert('Brew Bros', 'brew@brand.com', 1, 'Brew Bros', 3333000022, 'Beverages');
CALL Brand_insert('Glow Labs', 'glow@brand.com', 1, 'Glow Labs', 3333000033, 'Skincare');
CALL Brand_insert('Trail Gear', 'trail@brand.com', 1, 'Trail Gear', 3333000044, 'Outdoors');

# add more influencers to support multi-campaign and pending workflow tests
CALL Influencer_insert('Ava Stone', 'ava@influ.com', 0, 'avafit', 8888000011, 'Fitness', 'Instagram');
CALL Influencer_insert('Leo Park', 'leo@influ.com', 0, 'leotech', 8888000022, 'Tech', 'Youtube');
CALL Influencer_insert('Mia Chen', 'mia@influ.com', 0, 'miastyle', 8888000033, 'Fashion', 'TikTok');
CALL Influencer_insert('Noah Reed', 'noah@influ.com', 0, 'noahtravels', 8888000044, 'Travel', 'Instagram');
CALL Influencer_insert('Iris Hall', 'iris@influ.com', 0, 'iriswell', 8888000055, 'Wellness', 'Youtube');
CALL Influencer_insert('Evan Cole', 'evan@influ.com', 0, 'evancode', 8888000066, 'Tech', 'Instagram');

# add campaigns for existing and new brands
CALL Campaign_insert('Summer Run', 12000, '2026-05-03', '2026-06-05', 1, ST_GeomFromText('LINESTRING(1 0, 2 1)'), 1);
CALL Campaign_insert('Sneaker Weekend', 9000, '2026-05-20', '2026-06-01', 1, ST_GeomFromText('LINESTRING(4 0, 5 1)'), 1);
CALL Campaign_insert('Cold Brew Push', 18000, '2026-05-10', '2026-06-15', 1, ST_GeomFromText('LINESTRING(2 0, 3 1)'), 2);
CALL Campaign_insert('Glow Serum', 22000, '2026-05-15', '2026-06-20', 1, ST_GeomFromText('LINESTRING(3 0, 4 1)'), 3);
CALL Campaign_insert('Trail Challenge', 16000, '2026-05-22', '2026-06-25', 1, ST_GeomFromText('LINESTRING(5 0, 6 1)'), 4);

# create template rows for many campaigns
CALL Application_insert(1, 1, ST_GeomFromText('LINESTRING(10 10, 20 20)'), 2000, 0, '2026-05-01');
CALL Application_insert(1, 2, ST_GeomFromText('LINESTRING(11 10, 21 20)'), 1500, 0, '2026-05-03');
CALL Application_insert(2, 3, ST_GeomFromText('LINESTRING(12 10, 22 20)'), 2500, 0, '2026-05-10');
CALL Application_insert(3, 4, ST_GeomFromText('LINESTRING(13 10, 23 20)'), 3000, 0, '2026-05-15');
CALL Application_insert(4, 5, ST_GeomFromText('LINESTRING(14 10, 24 20)'), 1200, 0, '2026-05-20');

# create submitted rows directly for varied status testing
CALL Application_copy(5, 1, ST_GeomFromText('LINESTRING(30 30, 40 40)'), 2100, 0, '2026-05-02');
CALL Application_copy(6, 1, ST_GeomFromText('LINESTRING(31 30, 41 40)'), 1950, 1, '2026-05-03');
CALL Application_copy(7, 2, ST_GeomFromText('LINESTRING(32 30, 42 40)'), 1400, 0, '2026-05-04');
CALL Application_copy(8, 3, ST_GeomFromText('LINESTRING(33 30, 43 40)'), 2600, 1, '2026-05-11');
CALL Application_copy(9, 4, ST_GeomFromText('LINESTRING(34 30, 44 40)'), 2800, 0, '2026-05-16');
CALL Application_copy(10, 4, ST_GeomFromText('LINESTRING(35 30, 45 40)'), 1300, 0, '2026-05-21');
CALL Application_copy(5, 5, ST_GeomFromText('LINESTRING(36 30, 46 40)'), 2900, 1, '2026-05-23');

# create submitted rows from templates, with and without parameter overrides
CALL ApplicationSubmitFromTemplate_insert(5, 1, NULL, NULL, NULL, NULL);
CALL ApplicationSubmitFromTemplate_insert(6,1, ST_GeomFromText('LINESTRING(50 50, 60 60)'), NULL, NULL, NULL);
CALL ApplicationSubmitFromTemplate_insert(7, 2, NULL, 3200, NULL, NULL);
CALL ApplicationSubmitFromTemplate_insert(8, 3, NULL, NULL, 1, '2026-05-22');
CALL ApplicationSubmitFromTemplate_insert(9, 4, ST_GeomFromText('LINESTRING(51 50, 61 60)'), 2700, 0, '2026-05-12');
CALL ApplicationSubmitFromTemplate_insert(10, 4, NULL, 2050, 0, '2026-05-05');
CALL ApplicationSubmitFromTemplate_insert(5, 5, ST_GeomFromText('LINESTRING(52 50, 62 60)'), 1750, 0, '2026-05-06');

# run show procedures for both core and role-based views (basic DML retrieval demo)
CALL ApplicationTemplates_show();
CALL SubmittedApplications_show();
CALL ApplicationDetails_show();
CALL CampaignApplicationCounts_show();
CALL PendingApplications_show();
CALL BrandUser_CampaignApplications_show();
CALL InfluencerUser_MyApplications_show();
CALL AdminUser_AllApplications_show();
CALL PublicUser_OpenCampaignTemplates_show();
CALL PendingApplicationsByBrand_show();


# find all open campaigns with templates (join + filter)
SELECT DISTINCT C.campaign_id, C.campaign_title, C.brand_id, C.campaign_status
FROM Campaign AS C
JOIN Application AS A ON C.campaign_id = A.campaign_id
WHERE C.campaign_status = 1
AND A.user_id IS NULL;

# find all applications for a campaign (basic filtered retrieval)
SELECT *
FROM Application
WHERE campaign_id = 3;

# find all applications submitted by one influencer (basic filtered retrieval)
SELECT *
FROM Application
WHERE user_id = 7;

# find all pending applications for a brand (join across campaign + users)
SELECT C.brand_id, BUSER.user_name AS brand_name, C.campaign_id, C.campaign_title,
	   A.user_id AS applicant_user_id, AUSER.user_name AS applicant_name, A.application_status, A.application_date
FROM Application AS A
JOIN Campaign AS C ON A.campaign_id = C.campaign_id
JOIN User_ AS BUSER ON C.brand_id = BUSER.user_id
LEFT JOIN User_ AS AUSER ON A.user_id = AUSER.user_id
WHERE A.user_id IS NOT NULL
AND A.application_status = 0
AND C.brand_id = 3;

# count applications per campaign (aggregation with group by)
SELECT C.campaign_id, C.campaign_title, COUNT(A.user_id) AS submitted_application_count
FROM Campaign AS C
LEFT JOIN Application AS A ON C.campaign_id = A.campaign_id AND A.user_id IN (SELECT user_id FROM Influencer)
GROUP BY C.campaign_id, C.campaign_title
ORDER BY submitted_application_count DESC, C.campaign_id ASC;

# find campaigns with no submitted applications (left join + null check)
SELECT C.campaign_id, C.campaign_title, C.brand_id
FROM Campaign AS C
LEFT JOIN Application AS A ON C.campaign_id = A.campaign_id AND A.user_id IS NOT NULL
WHERE A.user_id IS NULL;

# find influencers who applied to more than one campaign (aggregation + having)
SELECT A.user_id, U.user_name, COUNT(DISTINCT A.campaign_id) AS campaign_count
FROM Application AS A
JOIN User_ AS U ON A.user_id = U.user_id
WHERE A.user_id IN (SELECT user_id FROM Influencer)
GROUP BY A.user_id, U.user_name
HAVING campaign_count > 1;

# find average proposed rate per campaign (aggregation example)
SELECT A.campaign_id, AVG(A.application_proposed_rate) AS avg_proposed_rate
FROM Application AS A
WHERE A.user_id IN (SELECT user_id FROM Influencer)
GROUP BY A.campaign_id;

# find applications above campaign budget (join + comparison query)
SELECT A.user_id, A.campaign_id, A.application_proposed_rate, C.campaign_budget
FROM Application AS A
JOIN Campaign AS C ON A.campaign_id = C.campaign_id
WHERE A.user_id IN (SELECT user_id FROM Influencer)
AND A.application_proposed_rate > C.campaign_budget;

# nested query: campaigns whose submitted application count is above global submitted average per campaign
SELECT X.campaign_id, X.submitted_count
FROM (
    SELECT A.campaign_id, COUNT(*) AS submitted_count
    FROM Application A
    WHERE A.user_id IN (SELECT user_id FROM Influencer)
    GROUP BY A.campaign_id
) AS X
WHERE X.submitted_count > (
    SELECT AVG(Y.submitted_count)
    FROM (
        SELECT A2.campaign_id, COUNT(*) AS submitted_count
        FROM Application A2
        WHERE A2.user_id IN (SELECT user_id FROM Influencer)
        GROUP BY A2.campaign_id
    ) AS Y
);
