-- =================================================================================
-- PROJECT PHASE: PERSONAL FINANCE TRACKER
-- 1. SCHEMA DESIGN (DDL)
-- =================================================================================

-- Set delimiter for routines (necessary for MySQL/MariaDB)
DELIMITER //

CREATE DATABASE IF NOT EXISTS finance_tracker_db;
USE finance_tracker_db;

-- ---------------------------------------------------------------------------------
-- Table 1: Users
-- ---------------------------------------------------------------------------------
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- ---------------------------------------------------------------------------------
-- Table 2: Categories
-- Categories are used for both income and expenses.
-- ---------------------------------------------------------------------------------
CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) UNIQUE NOT NULL,
    -- Type can be 'Income' or 'Expense'
    category_type ENUM('Income', 'Expense') NOT NULL
);

-- ---------------------------------------------------------------------------------
-- Table 3: Income
-- ---------------------------------------------------------------------------------
CREATE TABLE Income (
    income_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    income_date DATE NOT NULL,
    description VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- ---------------------------------------------------------------------------------
-- Table 4: Expenses
-- ---------------------------------------------------------------------------------
CREATE TABLE Expenses (
    expense_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    expense_date DATE NOT NULL,
    description VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- =================================================================================
-- 2. DUMMY DATA INSERTION (DML)
-- Data spanning 3 months (Jan, Feb, Mar 2024)
-- =================================================================================

-- User Insertion
INSERT INTO Users (first_name, last_name, email)
VALUES ('Alex', 'Johnson', 'alex.j@mail.com'); -- User ID 1

-- Category Insertion
INSERT INTO Categories (category_name, category_type) VALUES
('Salary', 'Income'),        -- ID 1
('Investment', 'Income'),    -- ID 2
('Rent', 'Expense'),         -- ID 3
('Groceries', 'Expense'),    -- ID 4
('Utilities', 'Expense'),    -- ID 5
('Entertainment', 'Expense'),-- ID 6
('Transport', 'Expense');    -- ID 7

-- Income Insertion (User Alex Johnson - ID 1)
INSERT INTO Income (user_id, category_id, amount, income_date, description) VALUES
(1, 1, 5000.00, '2024-01-01', 'January Monthly Salary'),
(1, 1, 5000.00, '2024-02-01', 'February Monthly Salary'),
(1, 2, 500.00,  '2024-02-15', 'Stock dividend payout'),
(1, 1, 5000.00, '2024-03-01', 'March Monthly Salary');

-- Expense Insertion (User Alex Johnson - ID 1)
INSERT INTO Expenses (user_id, category_id, amount, expense_date, description) VALUES
-- January Expenses
(1, 3, 1500.00, '2024-01-03', 'Apartment Rent'),
(1, 4, 350.50,  '2024-01-05', 'Weekly Grocery run'),
(1, 5, 120.00,  '2024-01-10', 'Electricity and Water Bill'),
(1, 6, 80.00,   '2024-01-15', 'Movie tickets'),
(1, 7, 50.00,   '2024-01-20', 'Fuel for car'),
-- February Expenses
(1, 3, 1500.00, '2024-02-03', 'Apartment Rent'),
(1, 4, 400.00,  '2024-02-06', 'Supermarket trip'),
(1, 5, 130.00,  '2024-02-10', 'Internet bill'),
(1, 7, 70.00,   '2024-02-22', 'Bus ticket'),
-- March Expenses
(1, 3, 1500.00, '2024-03-03', 'Apartment Rent'),
(1, 4, 380.00,  '2024-03-05', 'Monthly food shopping'),
(1, 6, 150.00,  '2024-03-12', 'Concert ticket');


-- =================================================================================
-- 3. CORE REPORTING AND ANALYSIS (QUERIES)
-- =================================================================================

-- Query 1: Summarize Expenses Monthly (Project Requirement 3)
SELECT
    YEAR(expense_date) AS Expense_Year,
    MONTH(expense_date) AS Expense_Month,
    SUM(amount) AS Total_Monthly_Expense
FROM Expenses
GROUP BY Expense_Year, Expense_Month
ORDER BY Expense_Year, Expense_Month;


-- Query 2: Category-Wise Spending (Project Requirement 4)
SELECT
    C.category_name,
    SUM(E.amount) AS Total_Spending
FROM Expenses E
JOIN Categories C ON E.category_id = C.category_id
WHERE E.user_id = 1 -- Filter for a specific user
GROUP BY C.category_name
ORDER BY Total_Spending DESC;


-- Query 3: Income vs. Expense by Month (Detailed Breakdown)
SELECT
    DATE_FORMAT(I.income_date, '%Y-%m') AS Month_Year,
    SUM(I.amount) AS Total_Income,
    (SELECT SUM(amount) FROM Expenses E WHERE DATE_FORMAT(E.expense_date, '%Y-%m') = DATE_FORMAT(I.income_date, '%Y-%m')) AS Total_Expense,
    SUM(I.amount) - (SELECT SUM(amount) FROM Expenses E WHERE DATE_FORMAT(E.expense_date, '%Y-%m') = DATE_FORMAT(I.income_date, '%Y-%m')) AS Net_Balance
FROM Income I
GROUP BY Month_Year
ORDER BY Month_Year;


-- =================================================================================
-- 4. VIEWS AND STORED ROUTINES (Project Requirement 5 & 6)
-- =================================================================================

-- View 1: Monthly Income Summary
CREATE OR REPLACE VIEW Monthly_Income_Summary AS
SELECT
    user_id,
    YEAR(income_date) AS Year,
    MONTH(income_date) AS Month,
    SUM(amount) AS Total_Income
FROM Income
GROUP BY user_id, Year, Month;

-- View 2: Monthly Expense Summary
CREATE OR REPLACE VIEW Monthly_Expense_Summary AS
SELECT
    user_id,
    YEAR(expense_date) AS Year,
    MONTH(expense_date) AS Month,
    SUM(amount) AS Total_Expenses
FROM Expenses
GROUP BY user_id, Year, Month;

-- View 3 (Project Requirement 5): Final Monthly Net Balance
CREATE OR REPLACE VIEW Monthly_Net_Balance AS
SELECT
    I.user_id,
    I.Year,
    I.Month,
    I.Total_Income,
    COALESCE(E.Total_Expenses, 0) AS Total_Expenses,
    I.Total_Income - COALESCE(E.Total_Expenses, 0) AS Net_Balance
FROM Monthly_Income_Summary I
LEFT JOIN Monthly_Expense_Summary E 
    ON I.user_id = E.user_id AND I.Year = E.Year AND I.Month = E.Month
ORDER BY I.Year, I.Month;

-- Usage of View 3
SELECT * FROM Monthly_Net_Balance;


-- Stored Procedure (Project Requirement 6): Generate Detailed Monthly Report
-- This procedure will output all expenses and the net balance for a specific user and month.
CREATE PROCEDURE Generate_Monthly_Report (
    IN user_id_in INT,
    IN report_month INT,
    IN report_year INT
)
BEGIN
    -- Report 1: Expenses Breakdown for the Month
    SELECT
        'Expense Breakdown' AS Report_Section;
    SELECT
        E.expense_date,
        C.category_name,
        E.amount,
        E.description
    FROM Expenses E
    JOIN Categories C ON E.category_id = C.category_id
    WHERE E.user_id = user_id_in 
      AND MONTH(E.expense_date) = report_month 
      AND YEAR(E.expense_date) = report_year
    ORDER BY E.expense_date;

    -- Report 2: Net Balance Summary for the Month
    SELECT
        'Net Balance Summary' AS Report_Section;
    SELECT
        Net_Balance,
        Total_Income,
        Total_Expenses
    FROM Monthly_Net_Balance
    WHERE user_id = user_id_in 
      AND Month = report_month 
      AND Year = report_year;

END //

-- Reset delimiter
DELIMITER ;

-- USAGE (Call the Stored Procedure for the Jan 2024 report for User 1)
CALL Generate_Monthly_Report(1, 1, 2024);