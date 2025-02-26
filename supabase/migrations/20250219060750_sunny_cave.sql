-- Drop existing trigger and function
DROP TRIGGER IF EXISTS tr_handle_first_user ON profiles;
DROP FUNCTION IF EXISTS handle_first_user();

-- Create improved function to handle first user and email confirmation
CREATE OR REPLACE FUNCTION handle_first_user()
RETURNS TRIGGER AS $$
DECLARE
  user_count integer;
  user_email text;
BEGIN
  -- Get the count of existing profiles
  SELECT COUNT(*) INTO user_count FROM profiles;
  
  -- If this is the first user (count = 1 because trigger runs after insert)
  IF user_count = 1 THEN
    -- Get the user's email
    SELECT email INTO user_email FROM auth.users WHERE id = NEW.user_id;
    
    -- Update auth.users to confirm email
    UPDATE auth.users
    SET email_confirmed_at = now(),
        confirmed_at = now()
    WHERE id = NEW.user_id;
    
    -- Update the profile to be an approved admin
    UPDATE profiles
    SET role = 'admin',
        is_approved = true
    WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
CREATE TRIGGER tr_handle_first_user
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION handle_first_user();

-- Grant necessary permissions
GRANT UPDATE ON auth.users TO postgres;
GRANT EXECUTE ON FUNCTION handle_first_user() TO postgres;