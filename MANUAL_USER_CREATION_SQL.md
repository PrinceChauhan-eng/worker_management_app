# Manual User Creation SQL Guide

## Overview
This guide shows how to manually create users in your Supabase database using SQL queries. This approach allows you to bypass the application's signup process and directly add users to the system.

## Prerequisites
1. Access to your Supabase project dashboard
2. PostgreSQL/SQL knowledge
3. User information (name, phone, email, password, role, etc.)

## How to Add Users Manually

### 1. Access Supabase SQL Editor
1. Go to your Supabase project dashboard
2. Navigate to the "SQL Editor" section
3. Create a new query or use an existing one

### 2. SQL Query Examples

#### Adding an Admin User
```sql
INSERT INTO users (
    name,
    phone,
    email,
    password,
    role,
    wage,
    join_date
) VALUES (
    'Admin User Name',
    '9876543210',
    'admin@example.com',
    'hashed_password_here',  -- See password hashing section below
    'admin',
    0.0,
    '2025-11-10'
);
```

#### Adding a Worker User
```sql
INSERT INTO users (
    name,
    phone,
    email,
    password,
    role,
    wage,
    join_date,
    designation
) VALUES (
    'Worker User Name',
    '9876543211',
    'worker@example.com',
    'hashed_password_here',  -- See password hashing section below
    'worker',
    500.0,
    '2025-11-10',
    'General Worker'
);
```

### 3. Password Hashing

#### Option A: Using Plain Text (NOT RECOMMENDED for production)
For testing purposes only, you can use plain text passwords:
```sql
INSERT INTO users (name, phone, email, password, role, wage, join_date)
VALUES ('Test User', '1234567890', 'test@example.com', 'test123', 'admin', 0.0, '2025-11-10');
```

#### Option B: Using MD5 Hash (Better for testing)
```sql
INSERT INTO users (name, phone, email, password, role, wage, join_date)
VALUES ('Test User', '1234567890', 'test@example.com', 'md5_hashed_password', 'admin', 0.0, '2025-11-10');
```

#### Option C: Using bcrypt (RECOMMENDED)
For production use, passwords should be properly hashed. You can use online bcrypt hash generators or hash them programmatically.

### 4. Complete Example with Multiple Users
```sql
-- Insert multiple users at once
INSERT INTO users (name, phone, email, password, role, wage, join_date, designation) VALUES
('John Admin', '9876543210', 'john.admin@example.com', 'admin_password_hash', 'admin', 0.0, '2025-11-10', NULL),
('Jane Worker', '9876543211', 'jane.worker@example.com', 'worker_password_hash', 'worker', 500.0, '2025-11-10', 'Senior Worker'),
('Bob Worker', '9876543212', 'bob.worker@example.com', 'bob_password_hash', 'worker', 400.0, '2025-11-10', 'Junior Worker');
```

### 5. Verifying User Creation
After inserting users, you can verify they were created correctly:
```sql
-- View all users
SELECT * FROM users;

-- View specific user
SELECT * FROM users WHERE email = 'admin@example.com';

-- Count total users
SELECT COUNT(*) FROM users;
```

### 6. Updating User Information
If you need to update user information:
```sql
-- Update user details
UPDATE users 
SET wage = 600.0, designation = 'Lead Worker'
WHERE email = 'jane.worker@example.com';

-- Change user role
UPDATE users 
SET role = 'admin'
WHERE email = 'jane.worker@example.com';
```

### 7. Deleting Users
To remove users from the system:
```sql
-- Delete specific user
DELETE FROM users WHERE email = 'test@example.com';

-- Delete user by ID
DELETE FROM users WHERE id = 5;
```

## Testing the Login

After creating users manually:

1. Open your application
2. Go to the login screen
3. Enter the credentials you just added:
   - Email/Phone: Use the email or phone you entered
   - Password: Use the password you entered (plain text or properly hashed)
   - Role: Select the appropriate role (admin/worker)
4. Click "Login"
5. You should be successfully logged in

## Security Considerations

1. **Password Storage**: Always hash passwords in production environments
2. **Role Management**: Be careful when assigning admin roles
3. **Data Validation**: Ensure all required fields are properly filled
4. **Access Control**: Limit who can execute these SQL queries

## Troubleshooting

### Common Issues:

1. **Duplicate Email/Phone**: Ensure email and phone numbers are unique
   ```sql
   -- Check for existing user
   SELECT * FROM users WHERE email = 'admin@example.com';
   ```

2. **Missing Required Fields**: Ensure all required fields are provided
   - name (required)
   - phone (required)
   - email (required)
   - password (required)
   - role (required)
   - join_date (required)

3. **Role Validation**: Ensure role is either 'admin' or 'worker'
   ```sql
   -- This will work
   INSERT INTO users (name, phone, email, password, role, wage, join_date)
   VALUES ('Test', '1234567890', 'test@example.com', 'pass', 'admin', 0.0, '2025-11-10');
   
   -- This will cause issues if your application expects only 'admin' or 'worker'
   INSERT INTO users (name, phone, email, password, role, wage, join_date)
   VALUES ('Test', '1234567890', 'test@example.com', 'pass', 'manager', 0.0, '2025-11-10');
   ```

## Next Steps

1. Use the SQL queries above to add your first admin user
2. Test the login functionality with your newly created user
3. Add additional users as needed
4. Consider implementing proper password hashing for production use