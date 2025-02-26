-- Update admin user approval status
DO $$ 
BEGIN
  -- Update the profile
  UPDATE profiles
  SET is_approved = true
  WHERE email = 'admin@admin.com'
  AND role = 'admin';

  -- Update the auth.users metadata
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{is_approved}',
    'true'
  )
  WHERE email = 'admin@admin.com';

  -- Force schema reload
  NOTIFY pgrst, 'reload schema';
END $$;