-- Create admin user with proper constraints
DO $$ 
DECLARE 
  admin_user_id UUID;
BEGIN
  -- First, check if admin user already exists
  SELECT id INTO admin_user_id
  FROM auth.users
  WHERE email = 'admin@example.com';

  -- If admin user doesn't exist, create it
  IF admin_user_id IS NULL THEN
    -- Create the admin user
    INSERT INTO auth.users (
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      role,
      aud,
      confirmed_at
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      'admin@example.com',
      crypt('admin123', gen_salt('bf')),
      now(),
      now(),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      false,
      'authenticated',
      'authenticated',
      now()
    )
    RETURNING id INTO admin_user_id;

    -- Create admin profile
    INSERT INTO profiles (
      user_id,
      email,
      name,
      role,
      is_approved
    )
    VALUES (
      admin_user_id,
      'admin@example.com',
      'Administrator',
      'admin'::user_role,
      true
    );
  END IF;
END $$;