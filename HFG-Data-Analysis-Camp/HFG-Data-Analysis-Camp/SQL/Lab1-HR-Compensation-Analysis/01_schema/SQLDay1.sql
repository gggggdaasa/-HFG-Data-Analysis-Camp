/*
02 Create Tables
This script creates the tables needed for the HR schema in SQL Server (T-SQL).
*/

-- Disable foreign key constraints to allow dropping tables in any order
-- Note: SQL Server does not have a simple CASCADE CONSTRAINTS on DROP,
-- so we drop in reverse dependency order and use IF EXISTS.
-- It's common practice to use dynamic SQL to drop foreign keys if a cleaner
-- reverse-order drop is not possible/desired. For this script, we'll use
-- the reverse order.

IF OBJECT_ID('dbo.job_history', 'U') IS NOT NULL DROP TABLE dbo.job_history;
IF OBJECT_ID('dbo.employees', 'U') IS NOT NULL DROP TABLE dbo.employees;
IF OBJECT_ID('dbo.departments', 'U') IS NOT NULL DROP TABLE dbo.departments;
IF OBJECT_ID('dbo.jobs', 'U') IS NOT NULL DROP TABLE dbo.jobs;
IF OBJECT_ID('dbo.locations', 'U') IS NOT NULL DROP TABLE dbo.locations;
IF OBJECT_ID('dbo.countries', 'U') IS NOT NULL DROP TABLE dbo.countries;
IF OBJECT_ID('dbo.regions', 'U') IS NOT NULL DROP TABLE dbo.regions;
-- Drop the view *before* the tables it depends on
IF OBJECT_ID('dbo.emp_details_view', 'V') IS NOT NULL DROP VIEW dbo.emp_details_view;
GO

-- SQL Server equivalent to Oracle's NLS_LANGUAGE/NLS_TERRITORY
SET LANGUAGE us_english;
GO

----------------------------------------------------------------------
-- Regions
----------------------------------------------------------------------

CREATE TABLE regions (
  region_id   INT           CONSTRAINT regions_id_nn NOT NULL,
  region_name VARCHAR(25)
);

ALTER TABLE regions
ADD CONSTRAINT reg_id_pk
PRIMARY KEY CLUSTERED (region_id);
GO

----------------------------------------------------------------------
-- Countries
----------------------------------------------------------------------

CREATE TABLE countries (
  country_id   CHAR(2)      CONSTRAINT country_id_nn NOT NULL,
  country_name VARCHAR(40),
  region_id    INT,
  CONSTRAINT country_c_id_pk PRIMARY KEY CLUSTERED (country_id)
);

ALTER TABLE countries
ADD CONSTRAINT countr_reg_fk
FOREIGN KEY (region_id)
REFERENCES regions(region_id);
GO

----------------------------------------------------------------------
-- Locations
----------------------------------------------------------------------

-- Replace Oracle SEQUENCE with SQL Server IDENTITY for auto-incrementing PK.
CREATE TABLE locations (
  location_id    SMALLINT     IDENTITY(3300, 100) NOT NULL, -- Starts at 3300, increments by 100
  street_address VARCHAR(40),
  postal_code    VARCHAR(12),
  city           VARCHAR(30)  CONSTRAINT loc_city_nn NOT NULL,
  state_province VARCHAR(25),
  country_id     CHAR(2)
);

-- FIX: Changed Oracle-style multiple constraint ADD to separate T-SQL ADDs
ALTER TABLE locations
ADD CONSTRAINT loc_id_pk PRIMARY KEY CLUSTERED (location_id);
--
ALTER TABLE locations
ADD CONSTRAINT loc_c_id_fk FOREIGN KEY (country_id) REFERENCES countries(country_id);
GO

----------------------------------------------------------------------
-- Departments
----------------------------------------------------------------------

CREATE TABLE departments (
  department_id   SMALLINT     IDENTITY(280, 10) NOT NULL, -- Starts at 280, increments by 10
  department_name VARCHAR(30)  CONSTRAINT dept_name_nn NOT NULL,
  manager_id      INT,
  location_id     SMALLINT
);

-- FIX: Changed Oracle-style multiple constraint ADD to separate T-SQL ADDs
ALTER TABLE departments
ADD CONSTRAINT dept_id_pk PRIMARY KEY CLUSTERED (department_id);
--
ALTER TABLE departments
ADD CONSTRAINT dept_loc_fk FOREIGN KEY (location_id) REFERENCES locations (location_id);
GO

----------------------------------------------------------------------
-- Jobs
----------------------------------------------------------------------

CREATE TABLE jobs (
  job_id      VARCHAR(10)   CONSTRAINT job_id_pk PRIMARY KEY CLUSTERED NOT NULL,
  job_title   VARCHAR(35)   CONSTRAINT job_title_nn NOT NULL,
  min_salary  DECIMAL(6, 0),
  max_salary  DECIMAL(6, 0)
);
GO

----------------------------------------------------------------------
-- Employees
----------------------------------------------------------------------

CREATE TABLE employees (
  employee_id    INT           IDENTITY(207, 1) NOT NULL, -- Starts at 207, increments by 1
  first_name     VARCHAR(20),
  last_name      VARCHAR(25)   CONSTRAINT emp_last_name_nn NOT NULL,
  email          VARCHAR(25)   CONSTRAINT emp_email_nn NOT NULL,
  phone_number   VARCHAR(20),
  hire_date      DATETIME2(0)  CONSTRAINT emp_hire_date_nn NOT NULL,
  job_id         VARCHAR(10)   CONSTRAINT emp_job_nn NOT NULL,
  salary         DECIMAL(8,2),
  commission_pct DECIMAL(2,2),
  manager_id     INT,
  department_id  SMALLINT,
  CONSTRAINT emp_salary_min CHECK (salary > 0),
  CONSTRAINT emp_email_uk UNIQUE (email),
  CONSTRAINT emp_emp_id_pk PRIMARY KEY CLUSTERED (employee_id)
);
GO

-- Foreign Keys for Employees
ALTER TABLE employees
ADD CONSTRAINT emp_dept_fk
  FOREIGN KEY (department_id) REFERENCES departments (department_id);

ALTER TABLE employees
ADD CONSTRAINT emp_job_fk
  FOREIGN KEY (job_id) REFERENCES jobs (job_id);

-- This FK references the same table (employees) so it is safe to add here.
ALTER TABLE employees
ADD CONSTRAINT emp_manager_fk
  FOREIGN KEY (manager_id) REFERENCES employees (employee_id);
GO

----------------------------------------------------------------------
-- Alter Departments (Add FK back, since employees now exists)
----------------------------------------------------------------------

ALTER TABLE departments
ADD CONSTRAINT dept_mgr_fk
  FOREIGN KEY (manager_id)
  REFERENCES employees (employee_id);
GO

----------------------------------------------------------------------
-- Job History
----------------------------------------------------------------------

CREATE TABLE job_history (
  employee_id   INT           CONSTRAINT jhist_employee_nn NOT NULL,
  start_date    DATETIME2(0)  CONSTRAINT jhist_start_date_nn NOT NULL,
  end_date      DATETIME2(0)  CONSTRAINT jhist_end_date_nn NOT NULL,
  job_id        VARCHAR(10)   CONSTRAINT jhist_job_nn NOT NULL,
  department_id SMALLINT,
  CONSTRAINT jhist_date_interval CHECK (end_date > start_date),
  CONSTRAINT jhist_emp_id_st_date_pk PRIMARY KEY CLUSTERED (employee_id, start_date)
);

-- Foreign Keys for Job History
ALTER TABLE job_history
ADD CONSTRAINT jhist_job_fk
  FOREIGN KEY (job_id) REFERENCES jobs (job_id);

ALTER TABLE job_history
ADD CONSTRAINT jhist_emp_fk
  FOREIGN KEY (employee_id) REFERENCES employees (employee_id);

ALTER TABLE job_history
ADD CONSTRAINT jhist_dept_fk
  FOREIGN KEY (department_id) REFERENCES departments (department_id);
GO

----------------------------------------------------------------------
-- View Creation
----------------------------------------------------------------------

-- FIX: View must be dropped at the beginning of the script to avoid object existence errors.
-- IF OBJECT_ID('dbo.emp_details_view', 'V') IS NOT NULL DROP VIEW dbo.emp_details_view; -- Moved to the top of the script.

CREATE VIEW emp_details_view
  (employee_id,
   job_id,
   manager_id,
   department_id,
   location_id,
   country_id,
   first_name,
   last_name,
   salary,
   commission_pct,
   department_name,
   job_title,
   city,
   state_province,
   country_name,
   region_name)
AS
SELECT
  e.employee_id,
  e.job_id,
  e.manager_id,
  e.department_id,
  d.location_id,
  l.country_id,
  e.first_name,
  e.last_name,
  e.salary,
  e.commission_pct,
  d.department_name,
  j.job_title,
  l.city,
  l.state_province,
  c.country_name,
  r.region_name
FROM
  employees e
  INNER JOIN departments d ON e.department_id = d.department_id
  INNER JOIN jobs j ON j.job_id = e.job_id
  INNER JOIN locations l ON d.location_id = l.location_id
  INNER JOIN countries c ON l.country_id = c.country_id
  INNER JOIN regions r ON c.region_id = r.region_id;
GO




--Insert Data
/*
03 Populate Tables
This script populates the tables for the HR schema in SQL Server (T-SQL).
Conversion Notes:
- Oracle's TO_DATE('DD-MM-YYYY', 'dd-MM-yyyy') is converted to T-SQL's CONVERT(datetime2, 'DD-MM-YYYY', 105).
- Oracle's ALTER TABLE DISABLE/ENABLE CONSTRAINT is converted to T-SQL's NOCHECK/CHECK CONSTRAINT.
- Oracle's COMMIT is replaced by the GO batch separator.
*/

-- Set the date format for the session to match 'dd-MM-yyyy' (105 is the style code for DD-MM-YYYY)
SET DATEFORMAT dmy;
GO

-- ----------------------------------------------------------------------
-- Regions
-- ----------------------------------------------------------------------

INSERT INTO regions (region_id, region_name) VALUES (1, 'Europe');
INSERT INTO regions (region_id, region_name) VALUES (2, 'Americas');
INSERT INTO regions (region_id, region_name) VALUES (3, 'Asia');
INSERT INTO regions (region_id, region_name) VALUES (4, 'Middle East and Africa');
GO

-- ----------------------------------------------------------------------
-- Countries
-- ----------------------------------------------------------------------

INSERT INTO countries (country_id, country_name, region_id) VALUES ('IT', 'Italy', 1);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('JP', 'Japan', 3);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('US', 'United States of America', 2);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('CA', 'Canada', 2);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('CN', 'China', 3);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('IN', 'India', 3);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('AU', 'Australia', 3);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('ZW', 'Zimbabwe', 4);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('SG', 'Singapore', 3);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('UK', 'United Kingdom', 1);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('FR', 'France', 1);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('DE', 'Germany', 1);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('ZM', 'Zambia', 4);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('EG', 'Egypt', 4);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('BR', 'Brazil', 2);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('CH', 'Switzerland', 1);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('NL', 'Netherlands', 1);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('MX', 'Mexico', 2);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('KW', 'Kuwait', 4);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('IL', 'Israel', 4);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('DK', 'Denmark', 1);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('ML', 'Malaysia', 3);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('NG', 'Nigeria', 4);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('AR', 'Argentina', 2);
INSERT INTO countries (country_id, country_name, region_id) VALUES ('BE', 'Belgium', 1);
GO

-- ----------------------------------------------------------------------
-- Locations (Need to use SET IDENTITY_INSERT ON/OFF because of IDENTITY property)
-- ----------------------------------------------------------------------

SET IDENTITY_INSERT locations ON;
GO

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
(1000 , '1297 Via Cola di Rie', '00989', 'Roma', NULL, 'IT');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
(1100, '93091 Calle della Testa', '10934', 'Venice', NULL, 'IT');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
(1200, '2017 Shinjuku-ku', '1689', 'Tokyo', 'Tokyo Prefecture', 'JP');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
(1300, '9450 Kamiya-cho', '6823', 'Hiroshima', NULL, 'JP');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
(1400, '2014 Jabberwocky Rd', '26192', 'Southlake', 'Texas', 'US');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 1500, '2011 Interiors Blvd', '99236', 'South San Francisco', 'California', 'US');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 1600, '2007 Zagora St', '50090', 'South Brunswick', 'New Jersey', 'US');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 1700, '2004 Charade Rd', '98199', 'Seattle', 'Washington', 'US');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 1800, '147 Spadina Ave', 'M5V 2L7', 'Toronto', 'Ontario', 'CA');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 1900, '6092 Boxwood St', 'YSW 9T2', 'Whitehorse', 'Yukon', 'CA');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 2000, '40-5-12 Laogianggen', '190518', 'Beijing', NULL, 'CN');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 2100, '1298 Vileparle (E)', '490231', 'Bombay', 'Maharashtra', 'IN');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 2200, '12-98 Victoria Street', '2901', 'Sydney', 'New South Wales', 'AU');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 2300, '198 Clementi North', '540198', 'Singapore', NULL, 'SG');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 2400, '8204 Arthur St', NULL, 'London', NULL, 'UK');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 2500, 'Magdalen Centre, The Oxford Science Park', 'OX9 9ZB', 'Oxford', 'Oxford', 'UK');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 2600, '9702 Chester Road', '09629850293', 'Stretford', 'Manchester', 'UK');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 2700, 'Schwanthalerstr. 7031', '80925', 'Munich', 'Bavaria', 'DE');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 2800, 'Rua Frei Caneca 1360 ', '01307-002', 'Sao Paulo', 'Sao Paulo', 'BR');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 2900, '20 Rue des Corps-Saints', '1730', 'Geneva', 'Geneve', 'CH');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 3000, 'Murtenstrasse 921', '3095', 'Bern', 'BE', 'CH');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 3100, 'Pieter Breughelstraat 837', '3029SK', 'Utrecht', 'Utrecht', 'NL');

INSERT INTO locations (location_id, street_address, postal_code, city, state_province, country_id) VALUES
( 3200, 'Mariano Escobedo 9991', '11932', 'Mexico City', 'Distrito Federal,', 'MX');

SET IDENTITY_INSERT locations OFF;
GO

-- ----------------------------------------------------------------------
-- Departments (Need to use SET IDENTITY_INSERT ON/OFF because of IDENTITY property)
-- The foreign key dept_mgr_fk references employees, which is not populated yet.
-- To allow insertion, we disable the FK check temporarily.
-- ----------------------------------------------------------------------

SET IDENTITY_INSERT departments ON;
GO

-- T-SQL equivalent of ALTER TABLE departments DISABLE CONSTRAINT dept_mgr_fk;
ALTER TABLE departments NOCHECK CONSTRAINT dept_mgr_fk;
GO

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 10, 'Administration', 200, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 20, 'Marketing', 201, 1800);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 30, 'Purchasing', 114, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 40, 'Human Resources', 203, 2400);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 50, 'Shipping', 121, 1500);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 60, 'IT', 103, 1400);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 70, 'Public Relations', 204, 2700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 80, 'Sales', 145, 2500);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 90, 'Executive', 100, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 100, 'Finance', 108, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 110, 'Accounting', 205, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 120, 'Treasury', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 130, 'Corporate Tax', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 140, 'Control And Credit', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 150, 'Shareholder Services', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 160, 'Benefits', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 170, 'Manufacturing', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 180, 'Construction', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 190, 'Contracting', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 200, 'Operations', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 210, 'IT Support', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 220, 'NOC', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 230, 'IT Helpdesk', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 240, 'Government Sales', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 250, 'Retail Sales', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 260, 'Recruiting', NULL, 1700);

INSERT INTO departments (department_id, department_name, manager_id, location_id) VALUES
( 270, 'Payroll', NULL, 1700);

SET IDENTITY_INSERT departments OFF;
GO

-- ----------------------------------------------------------------------
-- Jobs
-- ----------------------------------------------------------------------

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'AD_PRES', 'President', 20080, 40000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'AD_VP', 'Administration Vice President', 15000, 30000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'AD_ASST', 'Administration Assistant', 3000, 6000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'FI_MGR', 'Finance Manager', 8200, 16000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'FI_ACCOUNT', 'Accountant', 4200, 9000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'AC_MGR', 'Accounting Manager', 8200, 16000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'AC_ACCOUNT', 'Public Accountant', 4200, 9000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'SA_MAN', 'Sales Manager', 10000, 20080);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'SA_REP', 'Sales Representative', 6000, 12008);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'PU_MAN', 'Purchasing Manager', 8000, 15000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'PU_CLERK', 'Purchasing Clerk', 2500, 5500);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'ST_MAN', 'Stock Manager', 5500, 8500);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'ST_CLERK', 'Stock Clerk', 2008, 5000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'SH_CLERK', 'Shipping Clerk', 2500, 5500);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'IT_PROG', 'Programmer', 4000, 10000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'MK_MAN', 'Marketing Manager', 9000, 15000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'MK_REP', 'Marketing Representative', 4000, 9000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'HR_REP', 'Human Resources Representative', 4000, 9000);

INSERT INTO jobs (job_id, job_title, min_salary, max_salary) VALUES
( 'PR_REP', 'Public Relations Representative', 4500, 10500);
GO

-- ----------------------------------------------------------------------
-- Employees (Need to use SET IDENTITY_INSERT ON/OFF because of IDENTITY property)
-- T-SQL CONVERT(datetime2, 'DD-MM-YYYY', 105) used for Oracle TO_DATE.
-- ----------------------------------------------------------------------

SET IDENTITY_INSERT employees ON;
GO

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 100, 'Steven', 'King', 'SKING', '515.123.4567', CONVERT(datetime2, '17-06-2003', 105), 'AD_PRES', 24000, NULL, NULL, 90);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 101, 'Neena', 'Kochhar', 'NKOCHHAR', '515.123.4568', CONVERT(datetime2, '21-09-2005', 105), 'AD_VP', 17000, NULL, 100, 90);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 102, 'Lex', 'De Haan', 'LDEHAAN', '515.123.4569', CONVERT(datetime2, '13-01-2001', 105), 'AD_VP', 17000, NULL, 100, 90);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 103, 'Alexander', 'Hunold', 'AHUNOLD', '590.423.4567', CONVERT(datetime2, '03-01-2006', 105), 'IT_PROG', 9000, NULL, 102, 60);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 104, 'Bruce', 'Ernst', 'BERNST', '590.423.4568', CONVERT(datetime2, '21-05-2007', 105), 'IT_PROG', 6000, NULL, 103, 60);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 105, 'David', 'Austin', 'DAUSTIN', '590.423.4569', CONVERT(datetime2, '25-06-2005', 105), 'IT_PROG', 4800, NULL, 103, 60);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 106, 'Valli', 'Pataballa', 'VPATABAL', '590.423.4560', CONVERT(datetime2, '05-02-2006', 105), 'IT_PROG', 4800, NULL, 103, 60);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 107, 'Diana', 'Lorentz', 'DLORENTZ', '590.423.5567', CONVERT(datetime2, '07-02-2007', 105), 'IT_PROG', 4200, NULL, 103, 60);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 108, 'Nancy', 'Greenberg', 'NGREENBE', '515.124.4569', CONVERT(datetime2, '17-08-2002', 105), 'FI_MGR', 12008, NULL, 101, 100);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 109, 'Daniel', 'Faviet', 'DFAVIET', '515.124.4169', CONVERT(datetime2, '16-08-2002', 105), 'FI_ACCOUNT', 9000, NULL, 108, 100);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 110, 'John', 'Chen', 'JCHEN', '515.124.4269', CONVERT(datetime2, '28-09-2005', 105), 'FI_ACCOUNT', 8200, NULL, 108, 100);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 111, 'Ismael', 'Sciarra', 'ISCIARRA', '515.124.4369', CONVERT(datetime2, '30-09-2005', 105), 'FI_ACCOUNT', 7700, NULL, 108, 100);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 112, 'Jose Manuel', 'Urman', 'JMURMAN', '515.124.4469', CONVERT(datetime2, '07-03-2006', 105), 'FI_ACCOUNT', 7800, NULL, 108, 100);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 113, 'Luis', 'Popp', 'LPOPP', '515.124.4567', CONVERT(datetime2, '07-12-2007', 105), 'FI_ACCOUNT', 6900, NULL, 108, 100);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 114, 'Den', 'Raphaely', 'DRAPHEAL', '515.127.4561', CONVERT(datetime2, '07-12-2002', 105), 'PU_MAN', 11000, NULL, 100, 30);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 115, 'Alexander', 'Khoo', 'AKHOO', '515.127.4562', CONVERT(datetime2, '18-05-2003', 105), 'PU_CLERK', 3100, NULL, 114, 30);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 116, 'Shelli', 'Baida', 'SBAIDA', '515.127.4563', CONVERT(datetime2, '24-12-2005', 105), 'PU_CLERK', 2900, NULL, 114, 30);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 117, 'Sigal', 'Tobias', 'STOBIAS', '515.127.4564', CONVERT(datetime2, '24-07-2005', 105), 'PU_CLERK', 2800, NULL, 114, 30);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 118, 'Guy', 'Himuro', 'GHIMURO', '515.127.4565', CONVERT(datetime2, '15-11-2006', 105), 'PU_CLERK', 2600, NULL, 114, 30);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 119, 'Karen', 'Colmenares', 'KCOLMENA', '515.127.4566', CONVERT(datetime2, '10-08-2007', 105), 'PU_CLERK', 2500, NULL, 114, 30);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 120, 'Matthew', 'Weiss', 'MWEISS', '650.123.1234', CONVERT(datetime2, '18-07-2004', 105), 'ST_MAN', 8000, NULL, 100, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 121, 'Adam', 'Fripp', 'AFRIPP', '650.123.2234', CONVERT(datetime2, '10-04-2005', 105), 'ST_MAN', 8200, NULL, 100, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 122, 'Payam', 'Kaufling', 'PKAUFLIN', '650.123.3234', CONVERT(datetime2, '01-05-2003', 105), 'ST_MAN', 7900, NULL, 100, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 123, 'Shanta', 'Vollman', 'SVOLLMAN', '650.123.4234', CONVERT(datetime2, '10-10-2005', 105), 'ST_MAN', 6500, NULL, 100, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 124, 'Kevin', 'Mourgos', 'KMOURGOS', '650.123.5234', CONVERT(datetime2, '16-11-2007', 105), 'ST_MAN', 5800, NULL, 100, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 125, 'Julia', 'Nayer', 'JNAYER', '650.124.1214', CONVERT(datetime2, '16-07-2005', 105), 'ST_CLERK', 3200, NULL, 120, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 126, 'Irene', 'Mikkilineni', 'IMIKKILI', '650.124.1224', CONVERT(datetime2, '28-09-2006', 105), 'ST_CLERK', 2700, NULL, 120, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 127, 'James', 'Landry', 'JLANDRY', '650.124.1334', CONVERT(datetime2, '14-01-2007', 105), 'ST_CLERK', 2400, NULL, 120, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 128, 'Steven', 'Markle', 'SMARKLE', '650.124.1434', CONVERT(datetime2, '08-03-2008', 105), 'ST_CLERK', 2200, NULL, 120, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 129, 'Laura', 'Bissot', 'LBISSOT', '650.124.5234', CONVERT(datetime2, '20-08-2005', 105), 'ST_CLERK', 3300, NULL, 121, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 130, 'Mozhe', 'Atkinson', 'MATKINSO', '650.124.6234', CONVERT(datetime2, '30-10-2005', 105), 'ST_CLERK', 2800, NULL, 121, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 131, 'James', 'Marlow', 'JAMRLOW', '650.124.7234', CONVERT(datetime2, '16-02-2005', 105), 'ST_CLERK', 2500, NULL, 121, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 132, 'TJ', 'Olson', 'TJOLSON', '650.124.8234', CONVERT(datetime2, '10-04-2007', 105), 'ST_CLERK', 2100, NULL, 121, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 133, 'Jason', 'Mallin', 'JMALLIN', '650.127.1934', CONVERT(datetime2, '14-06-2004', 105), 'ST_CLERK', 3300, NULL, 122, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 134, 'Michael', 'Rogers', 'MROGERS', '650.127.1834', CONVERT(datetime2, '26-08-2006', 105), 'ST_CLERK', 2900, NULL, 122, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 135, 'Ki', 'Gee', 'KGEE', '650.127.1734', CONVERT(datetime2, '12-12-2007', 105), 'ST_CLERK', 2400, NULL, 122, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 136, 'Hazel', 'Philtanker', 'HPHILTAN', '650.127.1634', CONVERT(datetime2, '06-02-2008', 105), 'ST_CLERK', 2200, NULL, 122, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 137, 'Renske', 'Ladwig', 'RLADWIG', '650.121.1234', CONVERT(datetime2, '14-07-2003', 105), 'ST_CLERK', 3600, NULL, 123, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 138, 'Stephen', 'Stiles', 'SSTILES', '650.121.2034', CONVERT(datetime2, '26-10-2005', 105), 'ST_CLERK', 3200, NULL, 123, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 139, 'John', 'Seo', 'JSEO', '650.121.2019', CONVERT(datetime2, '12-02-2006', 105), 'ST_CLERK', 2700, NULL, 123, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 140, 'Joshua', 'Patel', 'JPATEL', '650.121.1834', CONVERT(datetime2, '06-04-2006', 105), 'ST_CLERK', 2500, NULL, 123, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 141, 'Trenna', 'Rajs', 'TRAJS', '650.121.8009', CONVERT(datetime2, '17-10-2003', 105), 'ST_CLERK', 3500, NULL, 124, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 142, 'Curtis', 'Davies', 'CDAVIES', '650.121.2994', CONVERT(datetime2, '29-01-2005', 105), 'ST_CLERK', 3100, NULL, 124, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 143, 'Randall', 'Matos', 'RMATOS', '650.121.2874', CONVERT(datetime2, '15-03-2006', 105), 'ST_CLERK', 2600, NULL, 124, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 144, 'Peter', 'Vargas', 'PVARGAS', '650.121.2004', CONVERT(datetime2, '09-07-2006', 105), 'ST_CLERK', 2500, NULL, 124, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 145, 'John', 'Russell', 'JRUSSEL', '011.44.1344.429268', CONVERT(datetime2, '01-10-2004', 105), 'SA_MAN', 14000, .4, 100, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 146, 'Karen', 'Partners', 'KPARTNER', '011.44.1344.467268', CONVERT(datetime2, '05-01-2005', 105), 'SA_MAN', 13500, .3, 100, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 147, 'Alberto', 'Errazuriz', 'AERRAZUR', '011.44.1344.429278', CONVERT(datetime2, '10-03-2005', 105), 'SA_MAN', 12000, .3, 100, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 148, 'Gerald', 'Cambrault', 'GCAMBRAU', '011.44.1344.619268', CONVERT(datetime2, '15-10-2007', 105), 'SA_MAN', 11000, .3, 100, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 149, 'Eleni', 'Zlotkey', 'EZLOTKEY', '011.44.1344.429018', CONVERT(datetime2, '29-01-2008', 105), 'SA_MAN', 10500, .2, 100, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 150, 'Peter', 'Tucker', 'PTUCKER', '011.44.1344.129268', CONVERT(datetime2, '30-01-2005', 105), 'SA_REP', 10000, .3, 145, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 151, 'David', 'Bernstein', 'DBERNSTE', '011.44.1344.345268', CONVERT(datetime2, '24-03-2005', 105), 'SA_REP', 9500, .25, 145, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 152, 'Peter', 'Hall', 'PHALL', '011.44.1344.478968', CONVERT(datetime2, '20-08-2005', 105), 'SA_REP', 9000, .25, 145, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 153, 'Christopher', 'Olsen', 'COLSEN', '011.44.1344.498718', CONVERT(datetime2, '30-03-2006', 105), 'SA_REP', 8000, .2, 145, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 154, 'Nanette', 'Cambrault', 'NCAMBRAU', '011.44.1344.987668', CONVERT(datetime2, '09-12-2006', 105), 'SA_REP', 7500, .2, 145, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 155, 'Oliver', 'Tuvault', 'OTUVAULT', '011.44.1344.486508', CONVERT(datetime2, '23-11-2007', 105), 'SA_REP', 7000, .15, 145, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 156, 'Janette', 'King', 'JKING', '011.44.1345.429268', CONVERT(datetime2, '30-01-2004', 105), 'SA_REP', 10000, .35, 146, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 157, 'Patrick', 'Sully', 'PSULLY', '011.44.1345.929268', CONVERT(datetime2, '04-03-2004', 105), 'SA_REP', 9500, .35, 146, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 158, 'Allan', 'McEwen', 'AMCEWEN', '011.44.1345.829268', CONVERT(datetime2, '01-08-2004', 105), 'SA_REP', 9000, .35, 146, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 159, 'Lindsey', 'Smith', 'LSMITH', '011.44.1345.729268', CONVERT(datetime2, '10-03-2005', 105), 'SA_REP', 8000, .3, 146, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 160, 'Louise', 'Doran', 'LDORAN', '011.44.1345.629268', CONVERT(datetime2, '15-12-2005', 105), 'SA_REP', 7500, .3, 146, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 161, 'Sarath', 'Sewall', 'SSEWALL', '011.44.1345.529268', CONVERT(datetime2, '03-11-2006', 105), 'SA_REP', 7000, .25, 146, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 162, 'Clara', 'Vishney', 'CVISHNEY', '011.44.1346.129268', CONVERT(datetime2, '11-11-2005', 105), 'SA_REP', 10500, .25, 147, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 163, 'Danielle', 'Greene', 'DGREENE', '011.44.1346.229268', CONVERT(datetime2, '19-03-2007', 105), 'SA_REP', 9500, .15, 147, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 164, 'Mattea', 'Marvins', 'MMARVINS', '011.44.1346.329268', CONVERT(datetime2, '24-01-2008', 105), 'SA_REP', 7200, .10, 147, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 165, 'David', 'Lee', 'DLEE', '011.44.1346.529268', CONVERT(datetime2, '23-02-2008', 105), 'SA_REP', 6800, .1, 147, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 166, 'Sundar', 'Ande', 'SANDE', '011.44.1346.629268', CONVERT(datetime2, '24-03-2008', 105), 'SA_REP', 6400, .10, 147, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 167, 'Amit', 'Banda', 'ABANDA', '011.44.1346.729268', CONVERT(datetime2, '21-04-2008', 105), 'SA_REP', 6200, .10, 147, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 168, 'Lisa', 'Ozer', 'LOZER', '011.44.1343.929268', CONVERT(datetime2, '11-03-2005', 105), 'SA_REP', 11500, .25, 148, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 169, 'Harrison', 'Bloom', 'HBLOOM', '011.44.1343.829268', CONVERT(datetime2, '23-03-2006', 105), 'SA_REP', 10000, .20, 148, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 170, 'Tayler', 'Fox', 'TFOX', '011.44.1343.729268', CONVERT(datetime2, '24-01-2006', 105), 'SA_REP', 9600, .20, 148, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 171, 'William', 'Smith', 'WSMITH', '011.44.1343.629268', CONVERT(datetime2, '23-02-2007', 105), 'SA_REP', 7400, .15, 148, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 172, 'Elizabeth', 'Bates', 'EBATES', '011.44.1343.529268', CONVERT(datetime2, '24-03-2007', 105), 'SA_REP', 7300, .15, 148, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 173, 'Sundita', 'Kumar', 'SKUMAR', '011.44.1343.329268', CONVERT(datetime2, '21-04-2008', 105), 'SA_REP', 6100, .10, 148, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 174, 'Ellen', 'Abel', 'EABEL', '011.44.1644.429267', CONVERT(datetime2, '11-05-2004', 105), 'SA_REP', 11000, .30, 149, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 175, 'Alyssa', 'Hutton', 'AHUTTON', '011.44.1644.429266', CONVERT(datetime2, '19-03-2005', 105), 'SA_REP', 8800, .25, 149, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 176, 'Jonathon', 'Taylor', 'JTAYLOR', '011.44.1644.429265', CONVERT(datetime2, '24-03-2006', 105), 'SA_REP', 8600, .20, 149, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 177, 'Jack', 'Livingston', 'JLIVINGS', '011.44.1644.429264', CONVERT(datetime2, '23-04-2006', 105), 'SA_REP', 8400, .20, 149, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 178, 'Kimberely', 'Grant', 'KGRANT', '011.44.1644.429263', CONVERT(datetime2, '24-05-2007', 105), 'SA_REP', 7000, .15, 149, NULL);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 179, 'Charles', 'Johnson', 'CJOHNSON', '011.44.1644.429262', CONVERT(datetime2, '04-01-2008', 105), 'SA_REP', 6200, .10, 149, 80);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 180, 'Winston', 'Taylor', 'WTAYLOR', '650.507.9876', CONVERT(datetime2, '24-01-2006', 105), 'SH_CLERK', 3200, NULL, 120, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 181, 'Jean', 'Fleaur', 'JFLEAUR', '650.507.9877', CONVERT(datetime2, '23-02-2006', 105), 'SH_CLERK', 3100, NULL, 120, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 182, 'Martha', 'Sullivan', 'MSULLIVA', '650.507.9878', CONVERT(datetime2, '21-06-2007', 105), 'SH_CLERK', 2500, NULL, 120, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 183, 'Girard', 'Geoni', 'GGEONI', '650.507.9879', CONVERT(datetime2, '03-02-2008', 105), 'SH_CLERK', 2800, NULL, 120, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 184, 'Nandita', 'Sarchand', 'NSARCHAN', '650.509.1876', CONVERT(datetime2, '27-01-2004', 105), 'SH_CLERK', 4200, NULL, 121, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 185, 'Alexis', 'Bull', 'ABULL', '650.509.2876', CONVERT(datetime2, '20-02-2005', 105), 'SH_CLERK', 4100, NULL, 121, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 186, 'Julia', 'Dellinger', 'JDELLING', '650.509.3876', CONVERT(datetime2, '24-06-2006', 105), 'SH_CLERK', 3400, NULL, 121, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 187, 'Anthony', 'Cabrio', 'ACABRIO', '650.509.4876', CONVERT(datetime2, '07-02-2007', 105), 'SH_CLERK', 3000, NULL, 121, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 188, 'Kelly', 'Chung', 'KCHUNG', '650.505.1876', CONVERT(datetime2, '14-06-2005', 105), 'SH_CLERK', 3800, NULL, 122, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 189, 'Jennifer', 'Dilly', 'JDILLY', '650.505.2876', CONVERT(datetime2, '13-08-2005', 105), 'SH_CLERK', 3600, NULL, 122, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 190, 'Timothy', 'Gates', 'TGATES', '650.505.3876', CONVERT(datetime2, '11-07-2006', 105), 'SH_CLERK', 2900, NULL, 122, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 191, 'Randall', 'Perkins', 'RPERKINS', '650.505.4876', CONVERT(datetime2, '19-12-2007', 105), 'SH_CLERK', 2500, NULL, 122, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 192, 'Sarah', 'Bell', 'SBELL', '650.501.1876', CONVERT(datetime2, '04-02-2004', 105), 'SH_CLERK', 4000, NULL, 123, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 193, 'Britney', 'Everett', 'BEVERETT', '650.501.2876', CONVERT(datetime2, '03-03-2005', 105), 'SH_CLERK', 3900, NULL, 123, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 194, 'Samuel', 'McCain', 'SMCCAIN', '650.501.3876', CONVERT(datetime2, '01-07-2006', 105), 'SH_CLERK', 3200, NULL, 123, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 195, 'Vance', 'Jones', 'VJONES', '650.501.4876', CONVERT(datetime2, '17-03-2007', 105), 'SH_CLERK', 2800, NULL, 123, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 196, 'Alana', 'Walsh', 'AWALSH', '650.507.9811', CONVERT(datetime2, '24-04-2006', 105), 'SH_CLERK', 3100, NULL, 124, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 197, 'Kevin', 'Feeney', 'KFEENEY', '650.507.9822', CONVERT(datetime2, '23-05-2006', 105), 'SH_CLERK', 3000, NULL, 124, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 198, 'Donald', 'OConnell', 'DOCONNEL', '650.507.9833', CONVERT(datetime2, '21-06-2007', 105), 'SH_CLERK', 2600, NULL, 124, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 199, 'Douglas', 'Grant', 'DGRANT', '650.507.9844', CONVERT(datetime2, '13-01-2008', 105), 'SH_CLERK', 2600, NULL, 124, 50);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 200, 'Jennifer', 'Whalen', 'JWHALEN', '515.123.4444', CONVERT(datetime2, '17-09-2003', 105), 'AD_ASST', 4400, NULL, 101, 10);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 201, 'Michael', 'Hartstein', 'MHARTSTE', '515.123.5555', CONVERT(datetime2, '17-02-2004', 105), 'MK_MAN', 13000, NULL, 100, 20);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 202, 'Pat', 'Fay', 'PFAY', '603.123.6666', CONVERT(datetime2, '17-08-2005', 105), 'MK_REP', 6000, NULL, 201, 20);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 203, 'Susan', 'Mavris', 'SMAVRIS', '515.123.7777', CONVERT(datetime2, '07-06-2002', 105), 'HR_REP', 6500, NULL, 101, 40);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 204, 'Hermann', 'Baer', 'HBAER', '515.123.8888', CONVERT(datetime2, '07-06-2002', 105), 'PR_REP', 10000, NULL, 101, 70);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 205, 'Shelley', 'Higgins', 'SHIGGINS', '515.123.8080', CONVERT(datetime2, '07-06-2002', 105), 'AC_MGR', 12008, NULL, 101, 110);

INSERT INTO employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id) VALUES
( 206, 'William', 'Gietz', 'WGIETZ', '515.123.8181', CONVERT(datetime2, '07-06-2002', 105), 'AC_ACCOUNT', 8300, NULL, 205, 110);

SET IDENTITY_INSERT employees OFF;
GO

-- Re-enable the Foreign Key check on the departments table
-- T-SQL equivalent of ALTER TABLE departments ENABLE CONSTRAINT dept_mgr_fk;
ALTER TABLE departments CHECK CONSTRAINT dept_mgr_fk;
GO

-- ----------------------------------------------------------------------
-- Job History
-- T-SQL CONVERT(datetime2, 'DD-MM-YYYY', 105) used for Oracle TO_DATE.
-- ----------------------------------------------------------------------

INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
VALUES (102, CONVERT(datetime2, '13-01-2001', 105), CONVERT(datetime2, '24-07-2006', 105), 'IT_PROG', 60);

INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
VALUES (101, CONVERT(datetime2, '21-09-1997', 105), CONVERT(datetime2, '27-10-2001', 105), 'AC_ACCOUNT', 110);

INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
VALUES (101, CONVERT(datetime2, '28-10-2001', 105), CONVERT(datetime2, '15-03-2005', 105), 'AC_MGR', 110);

INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
VALUES (201, CONVERT(datetime2, '17-02-2004', 105), CONVERT(datetime2, '19-12-2007', 105), 'MK_REP', 20);

INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
VALUES  (114, CONVERT(datetime2, '24-03-2006', 105), CONVERT(datetime2, '31-12-2007', 105), 'ST_CLERK', 50);

INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
VALUES  (122, CONVERT(datetime2, '01-01-2007', 105), CONVERT(datetime2, '31-12-2007', 105), 'ST_CLERK', 50);

INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
VALUES  (200, CONVERT(datetime2, '17-09-1995', 105), CONVERT(datetime2, '17-06-2001', 105), 'AD_ASST', 90);

INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
VALUES  (176, CONVERT(datetime2, '24-03-2006', 105), CONVERT(datetime2, '31-12-2006', 105), 'SA_REP', 80);

INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
VALUES  (176, CONVERT(datetime2, '01-01-2007', 105), CONVERT(datetime2, '31-12-2007', 105), 'SA_MAN', 80);

INSERT INTO job_history (employee_id, start_date, end_date, job_id, department_id)
VALUES  (200, CONVERT(datetime2, '01-07-2002', 105), CONVERT(datetime2, '31-12-2006', 105), 'AC_ACCOUNT', 90);
GO




