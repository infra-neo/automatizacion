-- Initialize database for sample applications

-- Create tables for app1 (REST API)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create tables for app2 (JMS)
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    message_text TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- Create tables for app3 (EJB)
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create tables for app4 (JSF Web)
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create tables for app5 (Batch)
CREATE TABLE IF NOT EXISTS batch_jobs (
    id SERIAL PRIMARY KEY,
    job_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    records_processed INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS batch_records (
    id SERIAL PRIMARY KEY,
    job_id INTEGER REFERENCES batch_jobs(id),
    data TEXT,
    processed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (username, email) VALUES 
    ('admin', 'admin@test.com'),
    ('user1', 'user1@test.com'),
    ('user2', 'user2@test.com');

INSERT INTO products (name, description, price, stock) VALUES 
    ('Product A', 'Description for Product A', 99.99, 100),
    ('Product B', 'Description for Product B', 149.99, 50),
    ('Product C', 'Description for Product C', 199.99, 25);

INSERT INTO customers (first_name, last_name, email, phone) VALUES 
    ('John', 'Doe', 'john.doe@test.com', '555-0001'),
    ('Jane', 'Smith', 'jane.smith@test.com', '555-0002'),
    ('Bob', 'Johnson', 'bob.johnson@test.com', '555-0003');

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO appuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO appuser;
