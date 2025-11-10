# Supabase Setup Guide

## Overview

This guide will help you set up your Supabase project for the Worker Management App. Follow these steps to configure your Supabase project with the correct tables, policies, and authentication settings.

## 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in to your account
3. Click "New Project"
4. Enter your project details:
   - Name: Worker Management App
   - Database Password: Set a strong password
   - Region: Choose the region closest to you
5. Click "Create New Project"

## 2. Database Schema Setup

Once your project is created, navigate to the SQL Editor and run the following SQL commands to create the required tables:

### Users Table
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'worker')),
  wage DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  join_date DATE NOT NULL,
  work_location_latitude DOUBLE PRECISION,
  work_location_longitude DOUBLE PRECISION,
  work_location_address TEXT,
  location_radius DOUBLE PRECISION DEFAULT 100.0,
  profile_photo TEXT,
  id_proof TEXT,
  address TEXT,
  email TEXT,
  email_verified BOOLEAN DEFAULT false,
  email_verification_code TEXT,
  designation TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Attendance Table
```sql
CREATE TABLE attendance (
  id SERIAL PRIMARY KEY,
  worker_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  in_time TIME,
  out_time TIME,
  present BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_attendance_worker_id ON attendance(worker_id);
CREATE INDEX idx_attendance_date ON attendance(date);
```

### Advance Table
```sql
CREATE TABLE advance (
  id SERIAL PRIMARY KEY,
  worker_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  amount DOUBLE PRECISION NOT NULL,
  date DATE NOT NULL,
  purpose TEXT,
  note TEXT,
  status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'deducted')) DEFAULT 'pending',
  deducted_from_salary_id INTEGER,
  approved_by INTEGER,
  approved_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_advance_worker_id ON advance(worker_id);
CREATE INDEX idx_advance_date ON advance(date);
```

### Salary Table
```sql
CREATE TABLE salary (
  id SERIAL PRIMARY KEY,
  worker_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  month TEXT NOT NULL,
  year TEXT,
  total_days INTEGER NOT NULL,
  present_days INTEGER,
  absent_days INTEGER,
  gross_salary DOUBLE PRECISION,
  total_advance DOUBLE PRECISION,
  net_salary DOUBLE PRECISION,
  total_salary DOUBLE PRECISION,
  paid BOOLEAN DEFAULT false,
  paid_date DATE,
  pdf_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_salary_worker_id ON salary(worker_id);
CREATE INDEX idx_salary_month ON salary(month);
```

### Login Status Table
```sql
CREATE TABLE login_status (
  id SERIAL PRIMARY KEY,
  worker_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  login_time TIME,
  logout_time TIME,
  is_logged_in BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(worker_id, date)
);

CREATE INDEX idx_login_status_worker_id ON login_status(worker_id);
CREATE INDEX idx_login_status_date ON login_status(date);
```

### Login History Table
```sql
CREATE TABLE login_history (
  id SERIAL PRIMARY KEY,
  worker_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  login_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  logout_time TIMESTAMP WITH TIME ZONE,
  ip_address TEXT,
  user_agent TEXT
);

CREATE INDEX idx_login_history_worker_id ON login_history(worker_id);
```

### Notifications Table
```sql
CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('salary', 'advance', 'attendance', 'system')),
  user_id INTEGER NOT NULL,
  user_role TEXT NOT NULL CHECK (user_role IN ('admin', 'worker')),
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  related_id TEXT
);

CREATE INDEX idx_notifications_user ON notifications(user_id, user_role);
CREATE INDEX idx_notifications_unread ON notifications(user_id, user_role, is_read);
```

## 3. Row Level Security (RLS) Policies

For development, we'll set up permissive policies. You can tighten these later for production.

### Enable RLS on all tables
```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE advance ENABLE ROW LEVEL SECURITY;
ALTER TABLE salary ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
```

### Create permissive policies for development
```sql
-- Users table policies
CREATE POLICY "Users are viewable by everyone" ON users FOR SELECT USING (true);
CREATE POLICY "Users are insertable by everyone" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Users are updateable by everyone" ON users FOR UPDATE USING (true);
CREATE POLICY "Users are deletable by everyone" ON users FOR DELETE USING (true);

-- Attendance table policies
CREATE POLICY "Attendance records are viewable by everyone" ON attendance FOR SELECT USING (true);
CREATE POLICY "Attendance records are insertable by everyone" ON attendance FOR INSERT WITH CHECK (true);
CREATE POLICY "Attendance records are updateable by everyone" ON attendance FOR UPDATE USING (true);
CREATE POLICY "Attendance records are deletable by everyone" ON attendance FOR DELETE USING (true);

-- Advance table policies
CREATE POLICY "Advance records are viewable by everyone" ON advance FOR SELECT USING (true);
CREATE POLICY "Advance records are insertable by everyone" ON advance FOR INSERT WITH CHECK (true);
CREATE POLICY "Advance records are updateable by everyone" ON advance FOR UPDATE USING (true);
CREATE POLICY "Advance records are deletable by everyone" ON advance FOR DELETE USING (true);

-- Salary table policies
CREATE POLICY "Salary records are viewable by everyone" ON salary FOR SELECT USING (true);
CREATE POLICY "Salary records are insertable by everyone" ON salary FOR INSERT WITH CHECK (true);
CREATE POLICY "Salary records are updateable by everyone" ON salary FOR UPDATE USING (true);
CREATE POLICY "Salary records are deletable by everyone" ON salary FOR DELETE USING (true);

-- Login status table policies
CREATE POLICY "Login status records are viewable by everyone" ON login_status FOR SELECT USING (true);
CREATE POLICY "Login status records are insertable by everyone" ON login_status FOR INSERT WITH CHECK (true);
CREATE POLICY "Login status records are updateable by everyone" ON login_status FOR UPDATE USING (true);
CREATE POLICY "Login status records are deletable by everyone" ON login_status FOR DELETE USING (true);

-- Login history table policies
CREATE POLICY "Login history records are viewable by everyone" ON login_history FOR SELECT USING (true);
CREATE POLICY "Login history records are insertable by everyone" ON login_history FOR INSERT WITH CHECK (true);
CREATE POLICY "Login history records are updateable by everyone" ON login_history FOR UPDATE USING (true);
CREATE POLICY "Login history records are deletable by everyone" ON login_history FOR DELETE USING (true);

-- Notifications table policies
CREATE POLICY "Notifications are viewable by everyone" ON notifications FOR SELECT USING (true);
CREATE POLICY "Notifications are insertable by everyone" ON notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Notifications are updateable by everyone" ON notifications FOR UPDATE USING (true);
CREATE POLICY "Notifications are deletable by everyone" ON notifications FOR DELETE USING (true);
```

## 4. Authentication Setup

### Configure Redirect URLs

1. In your Supabase dashboard, go to Authentication → URL Configuration
2. Add the following redirect URLs:
   ```
   https://princechauhan-eng.github.io
   https://princechauhan-eng.github.io/*
   http://localhost:3000
   http://localhost:3000/*
   ```

### Create Default Admin User

After setting up your application, you can create a default admin user by running this SQL command in the SQL Editor:

```sql
INSERT INTO users (name, phone, password, role, wage, join_date, email, email_verified)
VALUES ('Admin User', '9999999999', 'admin123', 'admin', 0.0, '2023-01-01', 'admin@example.com', true);
```

## 5. Environment Variables

Update your application to use environment variables for the Supabase configuration:

In your `main.dart`:
```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL', 
    defaultValue: 'https://your-project-ref.supabase.co'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key'),
);
```

When building for production:
```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## 6. Testing the Setup

1. Run your Flutter application:
   ```bash
   flutter run -d chrome
   ```

2. Test the following functionality:
   - User registration and login
   - CRUD operations for all entities
   - Real-time updates
   - Notifications

## 7. Deployment

To deploy to GitHub Pages:

1. Build the web application:
   ```bash
   flutter clean
   flutter build web --release \
     --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=your-anon-key
   ```

2. Copy the contents of `build/web` to your GitHub Pages repository

3. Commit and push to deploy

## Troubleshooting

### Common Issues

1. **Authentication Redirect Loop**
   - Check that your redirect URLs in Supabase Auth exactly match your deployment URLs

2. **403/401 Errors**
   - Ensure RLS policies are applied to all tables
   - Check that your anonKey is correct

3. **CORS Errors**
   - Verify that your Supabase project URL is correct
   - Check that you're using the correct anonKey

4. **White Screen**
   - Clear browser cache and service workers
   - Ensure main.dart.js and flutter_bootstrap.js are properly loaded

### Useful Supabase Console Queries

To check your data in the Supabase Table Editor:

```sql
-- Check users
SELECT * FROM users;

-- Check attendance
SELECT * FROM attendance;

-- Check advance requests
SELECT * FROM advance;

-- Check salaries
SELECT * FROM salary;

-- Check login status
SELECT * FROM login_status;

-- Check notifications
SELECT * FROM notifications;
```

This setup guide provides everything you need to get your Worker Management App running with Supabase. The application is now cloud-ready with real-time capabilities and integrated authentication.