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






CREATE OR REPLACE VIEW campaigns_view AS
SELECT 
    c.campaign_id,
    c.campaign_title,
    c.campaign_budget,
    c.campaign_start_date,
    c.campaign_end_date,
    c.campaign_status,
    c.campaign_objective,
    c.brand_id,
    u.user_name AS brand_name
FROM Campaign c
JOIN User_ u ON c.brand_id = u.user_id;

CREATE OR REPLACE VIEW brandApplications_view AS
SELECT  a.user_id AS influencer_id,
u.user_name AS influencer_name,
    a.campaign_id,
    c.campaign_title,
    a.application_pitch,
    a.application_proposed_rate,
    a.application_status,
    a.application_date,
    cu.user_id AS brand_id
FROM Application a
JOIN Campaign c ON a.campaign_id = c.campaign_id
JOIN User_ cu ON c.brand_id = cu.user_id
JOIN User_ u ON a.user_id = u.user_id;

CREATE OR REPLACE VIEW influencersApplications_view AS
SELECT 
    a.user_id AS influencer_id,
    a.campaign_id,
    c.campaign_title,
    c.campaign_budget,
    c.campaign_start_date,
    c.campaign_end_date,
    a.application_status,
    a.application_date
FROM Application a
JOIN Campaign c ON a.campaign_id = c.campaign_id
WHERE user_id NOT IN (SELECT user_id
					  FROM Brand);

CREATE OR REPLACE VIEW contracts_view AS
SELECT 
    ct.contract_id,
    ct.contract_terms,
    ct.contract_agreed_rate,
    ct.contract_start_date,
    ct.contract_end_date,
    ct.contract_status,
    ct.influencer_user_id,
    iu.user_name AS influencer_name,
    ct.brand_user_id,
    bu.user_name AS brand_name
FROM Contract ct
JOIN User_ iu ON ct.influencer_user_id = iu.user_id
JOIN User_ bu ON ct.brand_user_id = bu.user_id;

CREATE OR REPLACE VIEW payments_view AS
SELECT 
    p.payment_id,
    p.payment_amount,
    p.paid_at,
    p.payment_method,
    p.payment_status,
    p.contract_id,
    ct.influencer_user_id,
    ct.brand_user_id
FROM Payment p
JOIN Contract ct ON p.contract_id = ct.contract_id;

CREATE OR REPLACE VIEW deliverables_view AS
SELECT 
    d.deliverable_id,
    d.deliverable_type,
    d.deliverable_platform,
    d.deliverable_due_date,
    d.deliverable_status,
    d.submission_url,
    d.contract_id
FROM Deliverable d;

CREATE OR REPLACE VIEW metric_snapshots_view AS
SELECT 
    m.deliverable_id,
    m.snapshot_time,
    m.snapshot_views,
    m.snapshot_likes,
    m.snapshot_comments,
    m.snapshot_clicks
FROM MetricSnapshots m;

CREATE OR REPLACE VIEW brandTags_view AS
SELECT 
    bt.campaign_id,
    bt.category_id,
    c.category_name
FROM BrandTags bt
JOIN Category c ON bt.category_id = c.category_id;

CREATE OR REPLACE VIEW influencerTags_view AS
SELECT 
    it.influencer_id,
    it.category_id,
    c.category_name
FROM InfluencerTags it
JOIN Category c ON it.category_id = c.category_id;

CREATE OR REPLACE VIEW applications_search AS
SELECT 
    c.campaign_id,
    c.campaign_title,
    c.campaign_budget,
    c.campaign_start_date,
    c.campaign_end_date,
    c.campaign_status,
    c.brand_id
FROM Campaign c
WHERE c.campaign_status = 1;



DELIMITER $$

CREATE PROCEDURE user_add( IN p_user_name VARCHAR(30), IN p_user_email VARCHAR(30), IN p_user_type INT)
BEGIN
    DECLARE new_user_id BIGINT;

    INSERT INTO User_(user_name, user_email, user_type)
    VALUES (p_user_name, p_user_email, p_user_type);

    SET new_user_id = LAST_INSERT_ID();

    -- influencer
    IF p_user_type = 0 THEN
        INSERT INTO Influencer(user_id, handle, payment_info, niche, platform)
        VALUES (new_user_id, p_user_name, 0, 'general', 'unknown'); -- can be expanded to support params just didnt feel like it
    END IF;
    
    -- brand
    IF p_user_type = 1 THEN 
        INSERT INTO Brand(user_id, company_name, account_routing_number, industry)
        VALUES (new_user_id, p_user_name, 0, 'general'); -- can be expanded to support params just didnt feel like it
    END IF;
END$$

CREATE PROCEDURE categories_add( IN p_category_name VARCHAR(20))
BEGIN
    INSERT INTO Category(category_name)
    VALUES (p_category_name);
END$$

CREATE PROCEDURE contracts_submit( IN p_contract_id BIGINT)
BEGIN
    UPDATE Contract
    SET contract_status = 1
    WHERE contract_id = p_contract_id;
END$$

CREATE PROCEDURE campaigns_add(IN p_title VARCHAR(20), IN p_budget DOUBLE, IN p_start DATE, IN p_end DATE, IN p_status INT, IN p_objective TEXT, IN p_brand_id BIGINT)
BEGIN
    INSERT INTO Campaign(campaign_title, campaign_budget, campaign_start_date, campaign_end_date, campaign_status, campaign_objective, brand_id)
    VALUES (p_title, p_budget, p_start, p_end, p_status,
        ST_GeomFromText(
            CONCAT( 'LINESTRING(', LENGTH(p_objective), ' 0, ', LENGTH(p_objective) + 1, ' 1)' )),
            p_brand_id );
END$$

CREATE PROCEDURE applicationTemplate_add( IN p_user_id BIGINT, IN p_campaign_id BIGINT, IN p_pitch TEXT, IN p_rate DOUBLE)
BEGIN
    INSERT INTO Application( user_id, campaign_id, application_pitch, application_proposed_rate, application_status, application_date)
    VALUES ( p_user_id, p_campaign_id,
        ST_GeomFromText(
            CONCAT( 'LINESTRING(', LENGTH(p_pitch), ' 0, ', LENGTH(p_pitch) + 1, ' 1)' )),
            p_rate, 1, CURRENT_DATE);
END$$

CREATE PROCEDURE applicationTemplate_submit(IN p_user_id BIGINT, IN p_campaign_id BIGINT, IN p_pitch TEXT, IN p_rate DOUBLE)
BEGIN
    INSERT INTO Application(user_id, campaign_id, application_pitch, application_proposed_rate, application_status, application_date)
    VALUES (p_user_id, p_campaign_id,
        ST_GeomFromText(
            CONCAT( 'LINESTRING(', LENGTH(p_pitch), ' 0, ', LENGTH(p_pitch) + 1, ' 1)' )),
            p_rate, 1, CURRENT_DATE);
END$$

CREATE PROCEDURE contracts_add(IN p_terms TEXT, IN p_rate DOUBLE, IN p_start DATE, IN p_end DATE, IN p_status INT, IN p_influencer_id BIGINT, IN p_brand_id BIGINT)
BEGIN
    INSERT INTO Contract( contract_terms, contract_agreed_rate, contract_start_date, contract_end_date, contract_status, influencer_user_id, brand_user_id)
    VALUES (
        ST_GeomFromText(
            CONCAT( 'LINESTRING(', LENGTH(p_terms), ' 0, ', LENGTH(p_terms) + 1, ' 1)' )),
            p_rate, p_start, p_end, p_status, p_influencer_id, p_brand_id);
END$$

CREATE PROCEDURE deliverables_add( IN p_type INT, IN p_platform VARCHAR(15), IN p_due DATE, IN p_status INT, IN p_url TEXT, IN p_contract_id BIGINT)
BEGIN
    INSERT INTO Deliverable( deliverable_type, deliverable_platform, deliverable_due_date, deliverable_status, submission_url, contract_id)
    VALUES (p_type, p_platform, p_due, p_status,
        ST_GeomFromText(
            CONCAT( 'LINESTRING(', LENGTH(p_url), ' 0, ', LENGTH(p_url) + 1, ' 1)' )),
            p_contract_id);
END$$

CREATE PROCEDURE deliverables_submit(IN p_deliverable_id BIGINT, IN p_url TEXT)
BEGIN
    UPDATE Deliverable
    SET submission_url = ST_GeomFromText(
            CONCAT( 'LINESTRING(', LENGTH(p_url), ' 0, ', LENGTH(p_url) + 1, ' 1)' )),
        deliverable_status = 1
    WHERE deliverable_id = p_deliverable_id;
END$$

CREATE PROCEDURE payments_add(IN p_amount DOUBLE, IN p_method VARCHAR(30), IN p_status INT, IN p_contract_id BIGINT)
BEGIN
    INSERT INTO Payment(payment_amount, paid_at, payment_method, payment_status, contract_id)
    VALUES (p_amount, CURRENT_DATE, p_method, p_status, p_contract_id);
END$$

CREATE PROCEDURE campaignTags_select(IN p_campaign_id BIGINT, IN p_category_id BIGINT)
BEGIN
    INSERT INTO BrandTags(campaign_id, category_id)
    VALUES (p_campaign_id, p_category_id);
END$$

CREATE PROCEDURE influencerTags_select(IN p_influencer_id BIGINT, IN p_category_id BIGINT)
BEGIN
    INSERT INTO InfluencerTags(influencer_id, category_id)
    VALUES (p_influencer_id, p_category_id);
END$$

DELIMITER ;

CREATE ROLE IF NOT EXISTS 'brand_role', 'influencer_role', 'system';
# system:
GRANT EXECUTE ON PROCEDURE project.user_add TO 'system';

# brand role: 
GRANT SELECT ON project.campaigns_view TO 'brand_role';
GRANT SELECT ON project.brandApplications_view TO 'brand_role';
GRANT SELECT ON project.contracts_view TO 'brand_role';
GRANT SELECT ON project.payments_view TO 'brand_role';
GRANT SELECT ON project.deliverables_view TO 'brand_role';
GRANT SELECT ON project.metric_snapshots_view TO 'brand_role';
GRANT SELECT ON project.brandTags_view TO 'brand_role';
GRANT SELECT ON project.influencerTags_view TO 'brand_role';


GRANT EXECUTE ON PROCEDURE project.applicationTemplate_add TO 'brand_role';
GRANT EXECUTE ON PROCEDURE project.campaigns_add TO 'brand_role';
GRANT EXECUTE ON PROCEDURE project.contracts_add TO 'brand_role';
GRANT EXECUTE ON PROCEDURE project.deliverables_add TO 'brand_role';
GRANT EXECUTE ON PROCEDURE project.payments_add TO 'brand_role';
GRANT EXECUTE ON PROCEDURE project.categories_add TO 'brand_role';
GRANT EXECUTE ON PROCEDURE project.campaignTags_select TO 'brand_role';

# influencer role:
GRANT SELECT ON project.applications_search TO 'influencer_role';
GRANT SELECT ON project.influencersApplications_view TO 'influencer_role';
GRANT SELECT ON project.contracts_view TO 'influencer_role';
GRANT SELECT ON project.payments_view TO 'influencer_role';
GRANT SELECT ON project.deliverables_view TO 'influencer_role';
GRANT SELECT ON project.metric_snapshots_view TO 'influencer_role';
GRANT SELECT ON project.brandTags_view TO 'influencer_role';
GRANT SELECT ON project.influencerTags_view TO 'influencer_role';

GRANT EXECUTE ON PROCEDURE project.applicationTemplate_submit TO 'influencer_role';
GRANT EXECUTE ON PROCEDURE project.contracts_submit TO 'influencer_role';
GRANT EXECUTE ON PROCEDURE project.deliverables_submit TO 'influencer_role';
GRANT EXECUTE ON PROCEDURE project.categories_add TO 'influencer_role';
GRANT EXECUTE ON PROCEDURE project.influencerTags_select TO 'influencer_role';


-- brands (type = 1)
CALL user_add('Puma Team', 'puma@brand.com', 1);
CALL user_add('Brew Bros', 'brew@brand.com', 1);
CALL user_add('Glow Labs', 'glow@brand.com', 1);
CALL user_add('Trail Gear', 'trail@brand.com', 1);

-- influencer (type = 0)
CALL user_add('Ava Stone', 'ava@influ.com', 0);
CALL user_add('Leo Park', 'leo@influ.com', 0);
CALL user_add('Mia Chen', 'mia@influ.com', 0);
CALL user_add('Noah Reed', 'noah@influ.com', 0);
CALL user_add('Iris Hall', 'iris@influ.com', 0);
CALL user_add('Evan Cole', 'evan@influ.com', 0);


CALL categories_add('Apparel');
CALL categories_add('Beverages');
CALL categories_add('Skincare');
CALL categories_add('Outdoors');

CALL influencerTags_select(5, 1);
CALL influencerTags_select(6, 2);
CALL influencerTags_select(7, 3);

CALL contracts_submit(1);
CALL contracts_submit(2);

CALL campaigns_add('Summer Run', 12000, '2026-05-03', '2026-06-05', 1, 'Run campaign objective', 1);
CALL campaigns_add('Sneaker Weekend', 9000, '2026-05-20', '2026-06-01', 1, 'Sneaker hype objective', 1);
CALL campaigns_add('Cold Brew Push', 18000, '2026-05-10', '2026-06-15', 1, 'Coffee marketing objective', 2);
CALL campaigns_add('Glow Serum', 22000, '2026-05-15', '2026-06-20', 1, 'Skincare boost objective', 3);
CALL campaigns_add('Trail Challenge', 16000, '2026-05-22', '2026-06-25', 1, 'Outdoor challenge objective', 4);
CALL campaigns_add('Trail Challenge test', 0, '2026-05-22', '2026-06-25', 1, 'test null', 4);

CALL campaignTags_select(1, 1);
CALL campaignTags_select(2, 2);
CALL campaignTags_select(3, 3);


CALL applicationTemplate_add(1, 1, 'Pitch A', 2000);
CALL applicationTemplate_add(1, 2, 'Pitch B', 1500);
CALL applicationTemplate_add(2, 3, 'Pitch C', 2500);
CALL applicationTemplate_add(3, 4, 'Pitch D', 3000);
CALL applicationTemplate_add(4, 5, 'Pitch E', 1200);
CALL applicationTemplate_add(4, 6, 'Pitch L', 0000);

CALL applicationTemplate_submit(5, 1, 'Pitch F', 2100);
CALL applicationTemplate_submit(6, 1, 'Pitch G', 1950);
CALL applicationTemplate_submit(7, 2, 'Pitch H', 1400);
CALL applicationTemplate_submit(8, 3, 'Pitch I', 2600);
CALL applicationTemplate_submit(9, 4, 'Pitch J', 2800);
CALL applicationTemplate_submit(10, 4, 'Pitch K', 1300);
CALL applicationTemplate_submit(5, 5, 'Pitch L', 2900);

CALL contracts_add('Standard terms A', 5000, '2026-05-01', '2026-06-01', 0, 5, 1);
CALL contracts_add('Standard terms B', 6000, '2026-05-02', '2026-06-10', 0, 6, 2);
CALL contracts_add('Standard terms C', 7000, '2026-05-03', '2026-06-15', 0, 7, 3);

CALL deliverables_add(1, 'Instagram', '2026-06-01', 0, 'urlA', 1);
CALL deliverables_add(2, 'Youtube', '2026-06-05', 0, 'urlB', 2);
CALL deliverables_add(1, 'TikTok', '2026-06-10', 0, 'urlC', 3);

CALL deliverables_submit(1, 'submitted_url_1');
CALL deliverables_submit(2, 'submitted_url_2');
CALL deliverables_submit(3, 'submitted_url_3');

CALL payments_add(1200, 'Credit Card', 1, 1);
CALL payments_add(2500, 'PayPal', 0, 2);
CALL payments_add(1800, 'Bank Transfer', 1, 3);

SELECT * FROM influencersApplications_view;
SELECT * FROM contracts_view;
SELECT * FROM deliverables_view;
SELECT * FROM payments_view;
SELECT * FROM metric_snapshots_view; -- no insertions this woudl be handled automatically by the system and HTTP server

-- custom queries that never got a procedure


# find all open campaigns with templates (join + filter)
SELECT DISTINCT C.campaign_id, C.campaign_title, C.brand_id, C.campaign_status
FROM Campaign AS C
JOIN Application AS A ON C.campaign_id = A.campaign_id
WHERE C.campaign_status = 1
AND A.user_id IN (SELECT user_id FROM Brand);

# find all applications for a campaign (basic filtered retrieval)
SELECT *
FROM Application
WHERE campaign_id = 3;

# find all applications submitted by one influencer (basic filtered retrieval)
SELECT *
FROM Application
WHERE user_id = 7;

# find all pending applications for a brand (join across campaign + users) and template
SELECT C.brand_id, BUSER.user_name AS brand_name, C.campaign_id, C.campaign_title,
	   A.user_id AS applicant_user_id, AUSER.user_name AS applicant_name, A.application_status, A.application_date
FROM Application AS A
JOIN Campaign AS C ON A.campaign_id = C.campaign_id
JOIN User_ AS BUSER ON C.brand_id = BUSER.user_id
LEFT JOIN User_ AS AUSER ON A.user_id = AUSER.user_id
WHERE A.user_id IS NOT NULL
AND A.application_status = 1
AND C.brand_id = 3;

# count applications per campaign (aggregation with group by)
SELECT 
    C.campaign_title,
    COUNT(A.user_id) AS application_count
FROM Campaign C
LEFT JOIN Application A 
    ON C.campaign_id = A.campaign_id
JOIN Influencer I 
    ON A.user_id = I.user_id
GROUP BY C.campaign_id, C.campaign_title;

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
    WHERE A.user_id IS NOT NULL
    GROUP BY A.campaign_id
) AS X
WHERE X.submitted_count > (
    SELECT AVG(Y.submitted_count)
    FROM (
        SELECT A2.campaign_id, COUNT(*) AS submitted_count
        FROM Application A2
        WHERE A2.user_id IS NOT NULL
        GROUP BY A2.campaign_id
    ) AS Y
);
