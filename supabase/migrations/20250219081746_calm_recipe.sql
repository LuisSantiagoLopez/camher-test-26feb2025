-- Drop existing policies
DROP POLICY IF EXISTS "Full access for authenticated users" ON parts;

-- Create a function to log policy checks
CREATE OR REPLACE FUNCTION log_policy_check()
RETURNS TRIGGER AS $$
BEGIN
  -- Log the check
  RAISE NOTICE 'Policy check: user_id=%, method=%, role=%', 
    auth.uid(),
    current_setting('request.method'),
    current_setting('role');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for logging
DROP TRIGGER IF EXISTS tr_log_policy_check ON parts;
CREATE TRIGGER tr_log_policy_check
  BEFORE UPDATE ON parts
  FOR EACH ROW
  EXECUTE FUNCTION log_policy_check();

-- Create a completely permissive policy
CREATE POLICY "Debug full access"
  ON parts
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Ensure proper permissions
GRANT ALL ON parts TO authenticated;
GRANT ALL ON part_history TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON part_files TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;