-- VIAN Architects ERP Database Schema
-- DBMS: MySQL

CREATE DATABASE IF NOT EXISTS vian_architects_db;
USE vian_architects_db;

-- 1. Users table (for all roles)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(50) UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    mobile VARCHAR(20),
    role VARCHAR(100) NOT NULL,
    department VARCHAR(50),
    designation VARCHAR(50),
    joining_date DATE,
    status ENUM('Active', 'Inactive') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. Sessions (Remember Login & Device tracking)
CREATE TABLE IF NOT EXISTS sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(500) NOT NULL,
    device_id VARCHAR(255),
    device_name VARCHAR(255),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. CRM Leads table
CREATE TABLE IF NOT EXISTS leads (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    source VARCHAR(50),
    budget DECIMAL(15, 2),
    requirement TEXT,
    notes TEXT,
    status ENUM('New', 'Contacted', 'Site Visit Scheduled', 'Proposal Sent', 'Negotiation', 'Won', 'Lost') DEFAULT 'New',
    assigned_to INT,
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL
);

-- 4. CRM Lead Timeline
CREATE TABLE IF NOT EXISTS lead_timeline (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lead_id INT NOT NULL,
    action VARCHAR(255) NOT NULL,
    notes TEXT,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 5. Clients table
CREATE TABLE IF NOT EXISTS clients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE, -- Nullable link if client has login portal access
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    address TEXT,
    gst VARCHAR(15),
    property_details TEXT,
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 6. Projects table
CREATE TABLE IF NOT EXISTS projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id VARCHAR(50) UNIQUE NOT NULL, -- Custom project code
    name VARCHAR(150) NOT NULL,
    type ENUM('Residential', 'Villa', 'Commercial', 'Apartment', 'Interior Design', 'Renovation') NOT NULL,
    client_id INT NOT NULL,
    managing_director_id INT,
    architect_id INT,
    design_engineer_id INT,
    site_engineer_id INT,
    supervisor_id INT,
    budget DECIMAL(15, 2) NOT NULL,
    start_date DATE,
    completion_date DATE,
    status ENUM('Planning', 'In Progress', 'On Hold', 'Completed', 'Cancelled') DEFAULT 'Planning',
    progress_percentage INT DEFAULT 0,
    actual_material_cost DECIMAL(15, 2) NULL,
    actual_labour_cost DECIMAL(15, 2) NULL,
    actual_timeline_months INT NULL,
    actual_purchase_cost DECIMAL(15, 2) NULL,
    actual_profit DECIMAL(15, 2) NULL,
    is_archived BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (managing_director_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (architect_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (design_engineer_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (site_engineer_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (supervisor_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 7. GPS Attendance System
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    date DATE NOT NULL,
    check_in_time TIME,
    check_in_gps VARCHAR(100),
    check_in_selfie_url VARCHAR(255),
    check_out_time TIME,
    check_out_gps VARCHAR(100),
    working_hours DECIMAL(5, 2) DEFAULT 0.00,
    status ENUM('Present', 'Late', 'Half Day', 'Absent') DEFAULT 'Present',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY user_date_unique (user_id, date),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 8. Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    project_id INT,
    priority ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    assigned_to INT,
    due_date DATE,
    status ENUM('Pending', 'In Progress', 'Review', 'Completed') DEFAULT 'Pending',
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL
);

-- 9. Site Visit Module
CREATE TABLE IF NOT EXISTS site_visits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    user_id INT NOT NULL,
    date DATE NOT NULL,
    gps_location VARCHAR(100) NOT NULL,
    notes TEXT,
    photo_urls TEXT, -- JSON array of photo URLs
    voice_note_url VARCHAR(255),
    signature_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 10. Drawings Management
CREATE TABLE IF NOT EXISTS drawings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    drawing_number VARCHAR(100),
    title VARCHAR(150) NOT NULL,
    version VARCHAR(20) DEFAULT '1.0',
    type ENUM('Floor Plans', 'Elevations', 'Structural Drawings', 'Electrical Drawings', 'Plumbing Drawings', 'Interior Drawings') NOT NULL,
    file_url VARCHAR(255) NOT NULL,
    approved_by INT,
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    assigned_architect_id INT,
    completion_percentage INT DEFAULT 0,
    approval_status VARCHAR(50) DEFAULT 'Pending',
    upload_date DATE,
    last_updated DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_architect_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 11. Document Management
CREATE TABLE IF NOT EXISTS documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT,
    title VARCHAR(150) NOT NULL,
    folder VARCHAR(100) DEFAULT 'General', -- Folder-based structures
    file_url VARCHAR(255) NOT NULL,
    file_size INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- 12. Quotation Module
CREATE TABLE IF NOT EXISTS quotations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    quotation_number VARCHAR(50) UNIQUE NOT NULL,
    date DATE NOT NULL,
    tax_rate DECIMAL(5, 2) DEFAULT 18.00, -- GST default 18%
    discount DECIMAL(15, 2) DEFAULT 0.00,
    subtotal DECIMAL(15, 2) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    status ENUM('Draft', 'Sent', 'Approved', 'Declined') DEFAULT 'Draft',
    items TEXT NOT NULL, -- JSON block of items
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- 13. Invoice Module
CREATE TABLE IF NOT EXISTS invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    date DATE NOT NULL,
    due_date DATE,
    tax_rate DECIMAL(5, 2) DEFAULT 18.00,
    discount DECIMAL(15, 2) DEFAULT 0.00,
    subtotal DECIMAL(15, 2) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    paid_amount DECIMAL(15, 2) DEFAULT 0.00,
    status ENUM('Draft', 'Sent', 'Paid', 'Overdue') DEFAULT 'Draft',
    items TEXT NOT NULL, -- JSON block of items
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- 14. Expense Management
CREATE TABLE IF NOT EXISTS expenses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT,
    user_id INT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    category ENUM('Site Expenses', 'Material Expenses', 'Labour Expenses', 'Travel Expenses') NOT NULL,
    description TEXT,
    receipt_url VARCHAR(255),
    date DATE NOT NULL,
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 15. Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    read_status BOOLEAN DEFAULT FALSE,
    type VARCHAR(50) DEFAULT 'General',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 16. Company Settings table
CREATE TABLE IF NOT EXISTS company_settings (
    id INT PRIMARY KEY DEFAULT 1,
    company_name VARCHAR(150) NOT NULL,
    logo_url VARCHAR(255),
    address TEXT,
    gst VARCHAR(15),
    email VARCHAR(100),
    phone VARCHAR(20),
    cloudinary_cloud_name VARCHAR(100),
    cloudinary_api_key VARCHAR(100),
    cloudinary_api_secret VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 17. Labour Management - Worker Master
CREATE TABLE IF NOT EXISTS workers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    worker_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    mobile VARCHAR(20),
    skill_type ENUM('Mason', 'Carpenter', 'Painter', 'Electrician', 'Plumber', 'Tile Worker', 'Welder', 'Helper', 'Interior Worker') NOT NULL,
    daily_wage DECIMAL(15, 2) NOT NULL,
    contractor VARCHAR(100),
    project_id INT,
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL
);

-- 18. Manager-marked Labour Attendance
CREATE TABLE IF NOT EXISTS manager_attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    worker_id INT NOT NULL,
    date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'Half Day') DEFAULT 'Present',
    overtime_hours DECIMAL(5, 2) DEFAULT 0.00,
    remarks TEXT,
    manager_id INT NOT NULL,
    entry_time TIME NOT NULL,
    gps_location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY worker_date_unique (worker_id, date),
    FOREIGN KEY (worker_id) REFERENCES workers(id) ON DELETE CASCADE,
    FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 19. Daily Work Completion Reports (Employees)
CREATE TABLE IF NOT EXISTS daily_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    user_id INT NOT NULL,
    date DATE NOT NULL,
    work_category VARCHAR(100) NOT NULL, -- e.g., Brick Work, Painting
    work_description TEXT,
    quantity_completed VARCHAR(100), -- e.g., 1200 Sq Ft, 2 Rooms
    photo_urls TEXT, -- JSON array of photo URLs
    notes TEXT,
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 20. Manager Daily Progress Reports
CREATE TABLE IF NOT EXISTS manager_progress_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    manager_id INT NOT NULL,
    date DATE NOT NULL,
    workers_present INT DEFAULT 0,
    work_completed TEXT NOT NULL,
    materials_used TEXT,
    issues_faced TEXT,
    delays TEXT,
    photo_urls TEXT, -- JSON array of photo URLs
    tomorrow_plan TEXT,
    voice_note_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 21. Announcements board
CREATE TABLE IF NOT EXISTS announcements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    created_by INT,
    target_role VARCHAR(50) DEFAULT 'All', -- e.g. 'All' or specific role
    deleted_at TIMESTAMP NULL,
    deleted_by INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 22. Import Activity Logs
CREATE TABLE IF NOT EXISTS import_activity_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    type ENUM('Import', 'Export', 'Backup', 'Restore') NOT NULL,
    module VARCHAR(50) NOT NULL,
    file_name VARCHAR(255),
    file_path VARCHAR(500),
    records_imported INT DEFAULT 0,
    records_updated INT DEFAULT 0,
    records_failed INT DEFAULT 0,
    ip_address VARCHAR(45),
    device VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 23. Geofence Warnings
CREATE TABLE IF NOT EXISTS geofence_warnings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    project_id INT NOT NULL,
    current_location VARCHAR(100),
    time_left_site TIMESTAMP NULL,
    duration_outside INT DEFAULT 0,
    status ENUM('Warning Pending', 'Approved', 'Ignored', 'Fine Applied') DEFAULT 'Warning Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- 24. Fines Management
CREATE TABLE IF NOT EXISTS fines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    warning_id INT,
    employee_id INT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    reason TEXT NOT NULL,
    acknowledged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (warning_id) REFERENCES geofence_warnings(id) ON DELETE SET NULL,
    FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 25. Hourly Site Progress
CREATE TABLE IF NOT EXISTS hourly_site_progress (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    user_id INT NOT NULL,
    work_progress TEXT NOT NULL,
    remarks TEXT,
    completion_percentage INT DEFAULT 0,
    workers_present INT DEFAULT 0,
    materials_used TEXT,
    delay_reason TEXT,
    weather VARCHAR(50),
    photo_urls TEXT, -- JSON array
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 26. Announcement Actions (Acknowledgements & Comments)
CREATE TABLE IF NOT EXISTS announcement_actions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    announcement_id INT NOT NULL,
    user_id INT NOT NULL,
    acknowledged BOOLEAN DEFAULT FALSE,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (announcement_id) REFERENCES announcements(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 27. BOQ Items Table
CREATE TABLE IF NOT EXISTS boq_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    item_description TEXT NOT NULL,
    unit VARCHAR(50),
    quantity DECIMAL(15, 2) DEFAULT 0,
    rate DECIMAL(15, 2) DEFAULT 0,
    total_amount DECIMAL(15, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- 28. Material Purchases Table
CREATE TABLE IF NOT EXISTS materials (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    material_name VARCHAR(100) NOT NULL,
    purchased_quantity DECIMAL(15, 2) DEFAULT 0,
    used_quantity DECIMAL(15, 2) DEFAULT 0,
    balance_stock DECIMAL(15, 2) DEFAULT 0,
    material_cost DECIMAL(15, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- 29. Project Payments Table
CREATE TABLE IF NOT EXISTS project_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    payment_date DATE NOT NULL,
    description TEXT,
    paid_amount DECIMAL(15, 2) DEFAULT 0,
    pending_amount DECIMAL(15, 2) DEFAULT 0,
    payment_type VARCHAR(50) NOT NULL,
    expense_category VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- 30. Vendors Table
CREATE TABLE IF NOT EXISTS vendors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    gst_number VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 31. Contractors Table
CREATE TABLE IF NOT EXISTS contractors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 32. Drawing Progress Table
CREATE TABLE IF NOT EXISTS drawing_progress (
    id INT AUTO_INCREMENT PRIMARY KEY,
    drawing_id INT NOT NULL,
    assigned_employee_id INT,
    current_status VARCHAR(50) DEFAULT 'Pending',
    pending_work TEXT,
    revision_history TEXT,
    completion_percentage INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (drawing_id) REFERENCES drawings(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_employee_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 33. Annual Targets Table
CREATE TABLE IF NOT EXISTS annual_targets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    financial_year VARCHAR(10) UNIQUE NOT NULL,
    annual_project_target INT DEFAULT 0,
    annual_revenue_target DECIMAL(15, 2) DEFAULT 0.00,
    annual_profit_target DECIMAL(15, 2) DEFAULT 0.00,
    residential_projects_target INT DEFAULT 0,
    commercial_projects_target INT DEFAULT 0,
    interior_projects_target INT DEFAULT 0,
    renovation_projects_target INT DEFAULT 0,
    new_client_target INT DEFAULT 0,
    repeat_client_target INT DEFAULT 0,
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 34. Monthly Targets Table
CREATE TABLE IF NOT EXISTS monthly_targets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    annual_target_id INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    month_number INT NOT NULL,
    project_target INT DEFAULT 0,
    revenue_target DECIMAL(15, 2) DEFAULT 0.00,
    profit_target DECIMAL(15, 2) DEFAULT 0.00,
    residential_projects_target INT DEFAULT 0,
    commercial_projects_target INT DEFAULT 0,
    interior_projects_target INT DEFAULT 0,
    renovation_projects_target INT DEFAULT 0,
    new_client_target INT DEFAULT 0,
    repeat_client_target INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (annual_target_id) REFERENCES annual_targets(id) ON DELETE CASCADE
);

-- 35. Team Targets Table
CREATE TABLE IF NOT EXISTS team_targets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    financial_year VARCHAR(10) NOT NULL,
    team_name VARCHAR(100) NOT NULL,
    target_metric VARCHAR(100) NOT NULL,
    target_value DECIMAL(15, 2) DEFAULT 0.00,
    unit VARCHAR(50) DEFAULT 'number',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 36. Employee Targets Table
CREATE TABLE IF NOT EXISTS employee_targets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    assigned_by INT NOT NULL,
    target_description TEXT NOT NULL,
    target_metric VARCHAR(100) NOT NULL,
    target_value DECIMAL(15, 2) DEFAULT 0.00,
    current_value DECIMAL(15, 2) DEFAULT 0.00,
    period VARCHAR(50) DEFAULT 'Monthly',
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE CASCADE
);

-- 37. Build History Table
CREATE TABLE IF NOT EXISTS build_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version_name VARCHAR(50) NOT NULL,
    build_number INT NOT NULL,
    platform VARCHAR(50) NOT NULL,
    built_by INT,
    status VARCHAR(50) DEFAULT 'Pending',
    duration INT DEFAULT 0,
    file_name VARCHAR(255),
    file_size INT DEFAULT 0,
    sha256_checksum VARCHAR(64),
    release_notes TEXT,
    logs_path VARCHAR(500),
    artifact_path VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (built_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 38. Signing Configs Table
CREATE TABLE IF NOT EXISTS signing_configs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    platform VARCHAR(50) UNIQUE NOT NULL,
    keystore_file VARCHAR(255),
    keystore_alias VARCHAR(100),
    keystore_password VARCHAR(255),
    key_password VARCHAR(255),
    certificate_file VARCHAR(255),
    provisioning_profile VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 39. Build Configurations Table
CREATE TABLE IF NOT EXISTS build_configurations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    application_name VARCHAR(100) NOT NULL,
    package_name VARCHAR(100) NOT NULL,
    version VARCHAR(50) NOT NULL,
    build_number INT NOT NULL,
    environment VARCHAR(50) DEFAULT 'Production',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 40. Estimates Table
CREATE TABLE IF NOT EXISTS estimates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    estimate_number VARCHAR(50) UNIQUE NOT NULL,
    project_name VARCHAR(150) NOT NULL,
    client_name VARCHAR(100) NOT NULL,
    project_type VARCHAR(50) NOT NULL,
    construction_type VARCHAR(50) NOT NULL,
    state VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    site_address TEXT,
    built_up_area DECIMAL(15, 2) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    selected_package VARCHAR(50) NOT NULL,
    package_rate DECIMAL(15, 2) NOT NULL,
    total_cost DECIMAL(15, 2) NOT NULL,
    company_margin_percentage DECIMAL(5, 2) NOT NULL,
    estimated_profit DECIMAL(15, 2) NOT NULL,
    gst_percentage DECIMAL(5, 2) DEFAULT 18.00,
    gst_amount DECIMAL(15, 2) NOT NULL,
    net_project_value DECIMAL(15, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'Pending',
    complexity_score VARCHAR(50) NULL,
    structural_complexity VARCHAR(100) NULL,
    finishing_quality VARCHAR(50) NULL,
    drawing_details TEXT NULL,
    confidence_metrics TEXT NULL,
    similar_projects_data TEXT NULL,
    approved_by INT,
    created_by INT,
    project_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL
);

-- 41. Estimate Materials Table
CREATE TABLE IF NOT EXISTS estimate_materials (
    id INT AUTO_INCREMENT PRIMARY KEY,
    estimate_id INT NOT NULL,
    material_name VARCHAR(100) NOT NULL,
    quantity DECIMAL(15, 2) NOT NULL,
    unit VARCHAR(50),
    rate DECIMAL(15, 2) NOT NULL,
    cost DECIMAL(15, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (estimate_id) REFERENCES estimates(id) ON DELETE CASCADE
);

-- 42. Estimate Phases Table
CREATE TABLE IF NOT EXISTS estimate_phases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    estimate_id INT NOT NULL,
    phase_name VARCHAR(100) NOT NULL,
    estimated_cost DECIMAL(15, 2) NOT NULL,
    estimated_duration INT NOT NULL,
    completion_percentage INT DEFAULT 0,
    budget_allocation DECIMAL(15, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (estimate_id) REFERENCES estimates(id) ON DELETE CASCADE
);

-- 43. Estimate BOQs Table
CREATE TABLE IF NOT EXISTS estimate_boqs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    estimate_id INT NOT NULL,
    material_name VARCHAR(100) NOT NULL,
    unit VARCHAR(50),
    quantity DECIMAL(15, 2) NOT NULL,
    rate DECIMAL(15, 2) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    gst_rate DECIMAL(5, 2) DEFAULT 18.00,
    gst_amount DECIMAL(15, 2) NOT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (estimate_id) REFERENCES estimates(id) ON DELETE CASCADE
);

-- 44. Estimate Labours Table
CREATE TABLE IF NOT EXISTS estimate_labours (
    id INT AUTO_INCREMENT PRIMARY KEY,
    estimate_id INT NOT NULL,
    labour_type VARCHAR(100) NOT NULL,
    required_workers INT NOT NULL,
    estimated_days INT NOT NULL,
    estimated_cost DECIMAL(15, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (estimate_id) REFERENCES estimates(id) ON DELETE CASCADE
);

-- 45. Estimation Settings Table
CREATE TABLE IF NOT EXISTS estimation_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    economy_rate DECIMAL(15, 2) DEFAULT 2200.00,
    standard_rate DECIMAL(15, 2) DEFAULT 2500.00,
    premium_rate DECIMAL(15, 2) DEFAULT 2800.00,
    profit_margin_percentage DECIMAL(5, 2) DEFAULT 15.00,
    gst_percentage DECIMAL(5, 2) DEFAULT 18.00,
    materials_formula TEXT, -- JSON
    labour_formula TEXT,    -- JSON
    timeline_formula TEXT,  -- JSON
    district_adjustments TEXT, -- JSON
    regional_cost_index DECIMAL(5, 2) DEFAULT 1.00,
    company_overhead DECIMAL(15, 2) DEFAULT 0.00,
    civil_labour_rate DECIMAL(15, 2) DEFAULT 450.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 46. Market Prices Table
CREATE TABLE IF NOT EXISTS market_prices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    material_name VARCHAR(100) NOT NULL,
    current_rate DECIMAL(15, 2) NOT NULL,
    previous_rate DECIMAL(15, 2) DEFAULT 0.00,
    supplier VARCHAR(150),
    district VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 47. Build Versions Table
CREATE TABLE IF NOT EXISTS build_versions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version_name VARCHAR(50) NOT NULL,
    build_number INT NOT NULL,
    release_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 48. Builds Table
CREATE TABLE IF NOT EXISTS builds (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT,
    platform VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'Pending',
    started_at TIMESTAMP NULL,
    finished_at TIMESTAMP NULL,
    duration INT DEFAULT 0,
    built_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES build_versions(id) ON DELETE SET NULL,
    FOREIGN KEY (built_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 49. Build Logs Table
CREATE TABLE IF NOT EXISTS build_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    build_id INT NOT NULL,
    log_file_path VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (build_id) REFERENCES builds(id) ON DELETE CASCADE
);

-- 50. Build Artifacts Table
CREATE TABLE IF NOT EXISTS build_artifacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    build_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT DEFAULT 0,
    sha256_checksum VARCHAR(64),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (build_id) REFERENCES builds(id) ON DELETE CASCADE
);

-- 51. AI Settings Table
CREATE TABLE IF NOT EXISTS ai_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    gemini_api_key VARCHAR(255) NULL,
    ai_model VARCHAR(50) DEFAULT 'gemini-1.5-flash',
    temperature DECIMAL(3, 2) DEFAULT 0.2,
    max_tokens INT DEFAULT 2048,
    timeout INT DEFAULT 30000,
    enable_ai BOOLEAN DEFAULT TRUE,
    enable_pdf_analysis BOOLEAN DEFAULT TRUE,
    enable_image_analysis BOOLEAN DEFAULT TRUE,
    enable_boq_generation BOOLEAN DEFAULT TRUE,
    enable_cost_estimation BOOLEAN DEFAULT TRUE,
    api_usage_count INT DEFAULT 0,
    daily_token_usage INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 52. Conference Calls table
CREATE TABLE IF NOT EXISTS conference_calls (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type ENUM('Morning Call', 'Evening Call') DEFAULT 'Morning Call' NOT NULL,
    date DATE NOT NULL,
    duration_minutes INT DEFAULT 15,
    notes TEXT,
    logged_by_id INT,
    participants TEXT, -- JSON string of attendees
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (logged_by_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 53. Incentives table
CREATE TABLE IF NOT EXISTS incentives (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    month VARCHAR(10) NOT NULL, -- YYYY-MM
    attendance_score DECIMAL(5, 2) DEFAULT 0.00,
    calls_score DECIMAL(5, 2) DEFAULT 0.00,
    tasks_score DECIMAL(5, 2) DEFAULT 0.00,
    photos_score DECIMAL(5, 2) DEFAULT 0.00,
    reports_score DECIMAL(5, 2) DEFAULT 0.00,
    total_score DECIMAL(5, 2) DEFAULT 0.00,
    incentive_amount DECIMAL(15, 2) DEFAULT 0.00,
    penalty_amount DECIMAL(15, 2) DEFAULT 0.00,
    status ENUM('Pending', 'Approved', 'Paid') DEFAULT 'Pending',
    remarks TEXT,
    approved_by_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 54. Construction Stages table
CREATE TABLE IF NOT EXISTS project_stages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    stage_name VARCHAR(100) NOT NULL,
    sequence_order INT NOT NULL,
    status ENUM('Pending', 'In Progress', 'Completed', 'Delayed') DEFAULT 'Pending',
    completion_percentage INT DEFAULT 0,
    start_date DATE,
    end_date DATE,
    actual_end_date DATE,
    budget_allocation DECIMAL(15, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- 55. Nested Working Checklists table
CREATE TABLE IF NOT EXISTS stage_checklists (
    id INT AUTO_INCREMENT PRIMARY KEY,
    stage_id INT NOT NULL,
    parent_id INT NULL,
    title VARCHAR(150) NOT NULL,
    status ENUM('Pending', 'Completed') DEFAULT 'Pending',
    completion_percentage INT DEFAULT 0,
    sequence_order INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (stage_id) REFERENCES project_stages(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES stage_checklists(id) ON DELETE CASCADE
);

-- 56. Conference Call Action Items table
CREATE TABLE IF NOT EXISTS conference_call_actions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    call_id INT NOT NULL,
    task_description TEXT NOT NULL,
    assigned_to INT NOT NULL,
    due_date DATE NOT NULL,
    status ENUM('Pending', 'Completed') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (call_id) REFERENCES conference_calls(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE CASCADE
);

-- 57. Drawing Revisions table
CREATE TABLE IF NOT EXISTS drawing_revisions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    drawing_id INT NOT NULL,
    revision_number VARCHAR(20) NOT NULL,
    file_url VARCHAR(255) NOT NULL,
    pdf_preview_url VARCHAR(255) NOT NULL,
    comments TEXT,
    uploaded_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (drawing_id) REFERENCES drawings(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE
);

-- 58. Drawing Comments table
CREATE TABLE IF NOT EXISTS drawing_comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    drawing_id INT NOT NULL,
    user_id INT NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (drawing_id) REFERENCES drawings(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 59. Public Enquiry Links
CREATE TABLE IF NOT EXISTS public_enquiry_links (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lead_id INT NOT NULL UNIQUE,
    token VARCHAR(255) NOT NULL UNIQUE,
    expiry_date TIMESTAMP NULL,
    status ENUM('Active', 'Inactive') DEFAULT 'Active',
    qr_code_data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE
);

-- 60. Public Enquiry Submissions
CREATE TABLE IF NOT EXISTS public_enquiry_submissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lead_id INT NOT NULL,
    client_ip VARCHAR(45),
    browser VARCHAR(255),
    submission_time TIMESTAMP NULL,
    client_name VARCHAR(100) NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    whatsapp_number VARCHAR(20),
    email VARCHAR(100),
    occupation VARCHAR(100),
    preferred_contact_time VARCHAR(100),
    date DATE,
    site_address TEXT NOT NULL,
    near_landmark VARCHAR(255),
    village VARCHAR(100),
    taluk VARCHAR(100),
    district VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(20),
    road_width VARCHAR(50),
    building_type VARCHAR(100),
    local_authority VARCHAR(100),
    site_condition VARCHAR(100),
    site_condition_other VARCHAR(255),
    water_condition VARCHAR(100),
    bore_available BOOLEAN DEFAULT FALSE,
    bore_depth VARCHAR(50),
    water_remarks TEXT,
    electricity VARCHAR(50),
    eb_distance VARCHAR(50),
    electricity_remarks TEXT,
    drainage VARCHAR(50),
    drainage_remarks TEXT,
    underground_sump BOOLEAN DEFAULT FALSE,
    underground_sump_remarks TEXT,
    road_to_plinth VARCHAR(100),
    road_to_plinth_remarks TEXT,
    site_level VARCHAR(100),
    site_level_remarks TEXT,
    parking_cars INT DEFAULT 0,
    parking_bikes INT DEFAULT 0,
    parking_remarks TEXT,
    water_tank_capacity VARCHAR(100),
    building_purpose VARCHAR(100),
    staircase VARCHAR(100),
    terrace_access VARCHAR(100),
    site_facing VARCHAR(50),
    front_road_width VARCHAR(50),
    main_road_width VARCHAR(50),
    connecting_road_width VARCHAR(50),
    water_level VARCHAR(100),
    north_context_type VARCHAR(100),
    south_context_type VARCHAR(100),
    east_context_type VARCHAR(100),
    west_context_type VARCHAR(100),
    latitude VARCHAR(50),
    longitude VARCHAR(50),
    north_context TEXT,
    south_context TEXT,
    east_context TEXT,
    west_context TEXT,
    client_requirements TEXT,
    concept_sketch_json TEXT,
    notes TEXT,
    confirm_full_name VARCHAR(255),
    relationship VARCHAR(100),
    status ENUM('New', 'In Review', 'Approved', 'Rejected', 'Converted') DEFAULT 'New',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE
);

-- 61. Public Enquiry Documents
CREATE TABLE IF NOT EXISTS public_enquiry_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    submission_id INT NULL,
    lead_id INT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_size INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE,
    FOREIGN KEY (submission_id) REFERENCES public_enquiry_submissions(id) ON DELETE SET NULL
);

-- 62. Public Enquiry History
CREATE TABLE IF NOT EXISTS public_enquiry_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lead_id INT NOT NULL,
    action VARCHAR(255) NOT NULL,
    notes TEXT,
    client_ip VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE
);

-- 63. Public Enquiry Drafts
CREATE TABLE IF NOT EXISTS public_enquiry_drafts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(255) NOT NULL UNIQUE,
    draft_data TEXT NOT NULL,
    last_saved TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 64. Public Enquiry Notes
CREATE TABLE IF NOT EXISTS public_enquiry_notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    submission_id INT NOT NULL,
    author VARCHAR(100) NOT NULL,
    note_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (submission_id) REFERENCES public_enquiry_submissions(id) ON DELETE CASCADE
);



