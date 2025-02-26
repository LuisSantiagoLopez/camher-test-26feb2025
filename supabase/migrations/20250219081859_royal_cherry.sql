-- Create enhanced logging function
CREATE OR REPLACE FUNCTION debug_policy_check()
RETURNS TRIGGER AS $$
DECLARE
  user_role text;
  user_approved boolean;
BEGIN
  -- Get user details
  SELECT role, is_approved 
  INTO user_role, user_approved
  FROM profiles 
  WHERE user_id = auth.uid();

  -- Log detailed information
  RAISE LOG 'Policy Check Details:';
  RAISE LOG 'User ID: %', auth.uid();
  RAISE LOG 'Operation: %', TG_OP;
  RAISE LOG 'User Role: %', user_role;
  RAISE LOG 'User Approved: %', user_approved;
  RAISE LOG 'Part ID: %', NEW.id;
  RAISE LOG 'Part Status: % -> %', OLD.status, NEW.status;
  RAISE LOG 'Request Method: %', current_setting('request.method', true);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS tr_debug_policy_check ON parts;

-- Create new debug trigger
CREATE TRIGGER tr_debug_policy_check
  BEFORE UPDATE ON parts
  FOR EACH ROW
  EXECUTE FUNCTION debug_policy_check();

-- Drop all existing policies on parts
DROP POLICY IF EXISTS "Debug full access" ON parts;
DROP POLICY IF EXISTS "Full access for authenticated users" ON parts;

-- Create a completely permissive policy with no restrictions
CREATE POLICY "Unrestricted access"
  ON parts
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Grant all permissions explicitly
GRANT ALL ON parts TO authenticated;
GRANT ALL ON part_history TO authenticated;
GRANT ALL ON part_files TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON units TO authenticated;
GRANT ALL ON providers TO authenticated;

-- Ensure RLS is enabled but with permissive policies
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE part_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE part_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE providers ENABLE ROW LEVEL SECURITY;