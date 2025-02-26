-- Update specific admin user
DO $$ 
BEGIN
  -- Update the profile
  UPDATE profiles
  SET is_approved = true
  WHERE email = 'admin@admin.com'
  AND role = 'admin';

  -- Update the auth.users metadata
  UPDATE auth.users
  SET 
    email_confirmed_at = now(),
    confirmed_at = now(),
    raw_user_meta_data = jsonb_build_object('is_approved', true)
  WHERE email = 'admin@admin.com'
  AND id IN (
    SELECT user_id 
    FROM profiles 
    WHERE email = 'admin@admin.com'
    AND role = 'admin'
  );

  -- Force schema reload
  NOTIFY pgrst, 'reload schema';
END $$;