-- Create or replace the function to handle first user registration
CREATE OR REPLACE FUNCTION handle_first_user()
RETURNS TRIGGER AS $$
DECLARE
  user_count integer;
BEGIN
  -- Get the count of existing profiles
  SELECT COUNT(*) INTO user_count FROM profiles;
  
  -- If this is the first user (count = 1 because trigger runs after insert)
  IF user_count = 1 THEN
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
DROP TRIGGER IF EXISTS tr_handle_first_user ON profiles;
CREATE TRIGGER tr_handle_first_user
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION handle_first_user();