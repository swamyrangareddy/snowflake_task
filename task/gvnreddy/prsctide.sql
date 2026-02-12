USE  ROLE ACCOUNTADMIN

-- Create database and schema
CREATE DATABASE hr_system;
CREATE SCHEMA hr_system.main;
USE SCHEMA hr_system.main;

-- Employees table (already created above, but here's the complete version)
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    department VARCHAR(50),
    job_title VARCHAR(100),
    salary DECIMAL(10, 2),
    hire_date DATE,
    manager_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Departments table
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) UNIQUE NOT NULL,
    manager_id INT,
    budget DECIMAL(12, 2),
    location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Salary history table (tracks all salary changes)
CREATE TABLE salary_history (
    history_id INT AUTOINCREMENT PRIMARY KEY,
    employee_id INT,
    old_salary DECIMAL(10, 2),
    new_salary DECIMAL(10, 2),
    change_date DATE,
    reason VARCHAR(200),
    approved_by INT
);

-- Attendance table
CREATE TABLE attendance (
    attendance_id INT AUTOINCREMENT PRIMARY KEY,
    employee_id INT,
    attendance_date DATE,
    check_in_time TIME,
    check_out_time TIME,
    hours_worked DECIMAL(4, 2),
    status VARCHAR(20) -- Present, Absent, Leave, Half-day
);
-- Insert departments
INSERT INTO departments (dept_id, dept_name, manager_id, budget, location) VALUES
    (1, 'Engineering', 101, 500000, 'Building A'),
    (2, 'Marketing', 102, 200000, 'Building B'),
    (3, 'Sales', 103, 300000, 'Building B'),
    (4, 'HR', 104, 150000, 'Building C'),
    (5, 'Finance', 105, 250000, 'Building C');

-- Insert employees
INSERT INTO employees VALUES
    (101, 'John', 'Smith', 'john.smith@company.com', '555-0101', 'Engineering', 'Engineering Manager', 120000, '2020-01-15', NULL, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
    (102, 'Sarah', 'Johnson', 'sarah.j@company.com', '555-0102', 'Marketing', 'Marketing Director', 110000, '2020-03-20', NULL, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
    (103, 'Michael', 'Brown', 'mbrown@company.com', '555-0103', 'Sales', 'Sales Director', 115000, '2019-11-10', NULL, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
    (104, 'Emily', 'Davis', 'emily.d@company.com', '555-0104', 'HR', 'HR Director', 105000, '2020-02-05', NULL, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
    (105, 'David', 'Wilson', 'dwilson@company.com', '555-0105', 'Finance', 'Finance Director', 125000, '2019-09-20', NULL, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
    (201, 'Alice', 'Cooper', 'alice.c@company.com', '555-0201', 'Engineering', 'Senior Developer', 95000, '2021-05-12', 101, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
    (202, 'Bob', 'Miller', 'bob.m@company.com', '555-0202', 'Engineering', 'Developer', 75000, '2022-08-18', 101, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
    (203, 'Carol', 'White', 'carol.w@company.com', '555-0203', 'Marketing', 'Marketing Specialist', 70000, '2022-01-10', 102, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
    (204, 'Daniel', 'Clark', 'daniel.c@company.com', '555-0204', 'Sales', 'Sales Representative', 65000, '2022-06-22', 103, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
    (205, 'Emma', 'Taylor', 'emma.t@company.com', '555-0205', 'HR', 'HR Coordinator', 60000, '2023-03-15', 104, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

-- Insert attendance records
INSERT INTO attendance (employee_id, attendance_date, check_in_time, check_out_time, hours_worked, status) VALUES
    (201, '2024-02-01', '09:00:00', '18:00:00', 8.0, 'Present'),
    (201, '2024-02-02', '09:15:00', '17:45:00', 7.5, 'Present'),
    (202, '2024-02-01', '08:45:00', '17:30:00', 7.75, 'Present'),
    (202, '2024-02-02', NULL, NULL, 0, 'Absent');

    -- View 1: Employee Directory (public-facing information)
CREATE VIEW employee_directory AS
SELECT 
    employee_id,
    first_name || ' ' || last_name AS full_name,
    email,
    phone,
    department,
    job_title,
    CASE WHEN is_active THEN 'Active' ELSE 'Inactive' END AS status
FROM employees
WHERE is_active = TRUE
ORDER BY department, last_name;

-- View 2: Department Summary
CREATE VIEW department_summary AS
SELECT 
    d.dept_name,
    d.location,
    d.budget,
    COUNT(e.employee_id) AS employee_count,
    AVG(e.salary) AS avg_salary,
    SUM(e.salary) AS total_salary_cost,
    d.budget - SUM(e.salary) AS remaining_budget,
    m.first_name || ' ' || m.last_name AS manager_name
FROM departments d
LEFT JOIN employees e ON d.dept_name = e.department AND e.is_active = TRUE
LEFT JOIN employees m ON d.manager_id = m.employee_id
GROUP BY d.dept_name, d.location, d.budget, d.manager_id, m.first_name, m.last_name;

-- View 3: Employee Hierarchy
CREATE VIEW employee_hierarchy AS
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.job_title,
    e.department,
    e.salary,
    m.first_name || ' ' || m.last_name AS manager_name,
    m.job_title AS manager_title
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
WHERE e.is_active = TRUE;

-- View 4: Recent Attendance Report
CREATE VIEW recent_attendance AS
SELECT 
    a.attendance_date,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.department,
    a.check_in_time,
    a.check_out_time,
    a.hours_worked,
    a.status,
    CASE 
        WHEN a.check_in_time > '09:00:00' THEN 'Late'
        WHEN a.status = 'Absent' THEN 'Absent'
        ELSE 'On Time'
    END AS punctuality
FROM attendance a
JOIN employees e ON a.employee_id = e.employee_id
WHERE a.attendance_date >= DATEADD(day, -30, CURRENT_DATE())
ORDER BY a.attendance_date DESC, e.last_name;



-- Procedure 1: Give salary raise with history tracking
CREATE OR REPLACE PROCEDURE give_employee_raise(
    emp_id INT,
    raise_percent DECIMAL,
    reason_text VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    old_sal DECIMAL(10, 2);
    new_sal DECIMAL(10, 2);
    emp_name VARCHAR;
BEGIN
    -- Get current salary and name
    SELECT salary, first_name || ' ' || last_name 
    INTO old_sal, emp_name
    FROM employees 
    WHERE employee_id = emp_id;
    
    -- Calculate new salary
    new_sal := old_sal * (1 + raise_percent / 100);
    
    -- Update employee salary
    UPDATE employees
    SET salary = new_sal,
        updated_at = CURRENT_TIMESTAMP()
    WHERE employee_id = emp_id;
    
    -- Record in salary history
    INSERT INTO salary_history (employee_id, old_salary, new_salary, change_date, reason)
    VALUES (emp_id, old_sal, new_sal, CURRENT_DATE(), reason_text);
    
    RETURN emp_name || ' salary increased from $' || old_sal || ' to $' || new_sal ||
           ' (' || raise_percent || '% raise)';
END;
$$;

-- Procedure 2: Bulk department raise
CREATE OR REPLACE PROCEDURE give_department_raise_bulk(
    dept_name VARCHAR,
    raise_percent DECIMAL,
    reason_text VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    affected_count INT;
BEGIN
    -- Update all employees in department
    UPDATE employees
    SET salary = salary * (1 + raise_percent / 100),
        updated_at = CURRENT_TIMESTAMP()
    WHERE department = dept_name AND is_active = TRUE;
    
    affected_count := SQLROWCOUNT;
    
    -- Record in salary history for each affected employee
    INSERT INTO salary_history (employee_id, old_salary, new_salary, change_date, reason)
    SELECT 
        employee_id,
        salary / (1 + raise_percent / 100) AS old_salary,
        salary AS new_salary,
        CURRENT_DATE(),
        reason_text
    FROM employees
    WHERE department = dept_name AND is_active = TRUE;
    
    RETURN 'Gave ' || raise_percent || '% raise to ' || affected_count || 
           ' employees in ' || dept_name || ' department';
END;
$$;

-- Procedure 3: Generate monthly attendance report
CREATE OR REPLACE PROCEDURE generate_attendance_report(
    report_month INT,
    report_year INT
)
RETURNS TABLE (
    employee_name VARCHAR,
    department VARCHAR,
    total_days INT,
    present_days INT,
    absent_days INT,
    total_hours DECIMAL,
    attendance_rate DECIMAL
)
LANGUAGE SQL
AS
$$
BEGIN
    LET result_set RESULTSET := (
        SELECT 
            e.first_name || ' ' || e.last_name AS employee_name,
            e.department,
            COUNT(*) AS total_days,
            SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS present_days,
            SUM(CASE WHEN a.status = 'Absent' THEN 1 ELSE 0 END) AS absent_days,
            SUM(a.hours_worked) AS total_hours,
            ROUND(
                (SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
                2
            ) AS attendance_rate
        FROM employees e
        LEFT JOIN attendance a ON e.employee_id = a.employee_id
        WHERE MONTH(a.attendance_date) = :report_month
          AND YEAR(a.attendance_date) = :report_year
        GROUP BY e.employee_id, e.first_name, e.last_name, e.department
        ORDER BY e.department, e.last_name
    );
    RETURN TABLE(result_set);
END;
$$;

-- Procedure 4: Onboard new employee (complete setup)
CREATE OR REPLACE PROCEDURE onboard_employee(
    emp_id INT,
    f_name VARCHAR,
    l_name VARCHAR,
    emp_email VARCHAR,
    emp_phone VARCHAR,
    dept VARCHAR,
    job_title_text VARCHAR,
    emp_salary DECIMAL,
    manager_emp_id INT
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    -- Insert new employee
    INSERT INTO employees (
        employee_id,
        first_name,
        last_name,
        email,
        phone,
        department,
        job_title,
        salary,
        hire_date,
        manager_id,
        is_active
    )
    VALUES (
        emp_id,
        f_name,
        l_name,
        emp_email,
        emp_phone,
        dept,
        job_title_text,
        emp_salary,
        CURRENT_DATE(),
        manager_emp_id,
        TRUE
    );
    
    -- Create initial salary history record
    INSERT INTO salary_history (employee_id, old_salary, new_salary, change_date, reason)
    VALUES (emp_id, 0, emp_salary, CURRENT_DATE(), 'Initial hire');
    
    RETURN 'Successfully onboarded ' || f_name || ' ' || l_name || 
           ' as ' || job_title_text || ' in ' || dept || ' department';
           
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Error: Failed to onboard employee. ' || SQLERRM;
END;
$$;

-- Procedure 5: Deactivate employee (offboarding)
CREATE OR REPLACE PROCEDURE offboard_employee(
    emp_id INT,
    exit_reason VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    emp_name VARCHAR;
BEGIN
    -- Get employee name
    SELECT first_name || ' ' || last_name 
    INTO emp_name
    FROM employees 
    WHERE employee_id = emp_id;
    
    -- Mark as inactive
    UPDATE employees
    SET is_active = FALSE,
        updated_at = CURRENT_TIMESTAMP()
    WHERE employee_id = emp_id;
    
    RETURN 'Employee ' || emp_name || ' has been offboarded. Reason: ' || exit_reason;
    
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Error: Could not find employee with ID ' || emp_id;
END;
$$;


-- Query the employee directory view
SELECT * FROM employee_directory;

-- Check department summaries
SELECT * FROM department_summary
ORDER BY total_salary_cost DESC;

-- See employee hierarchy
SELECT * FROM employee_hierarchy
WHERE department = 'Engineering';

