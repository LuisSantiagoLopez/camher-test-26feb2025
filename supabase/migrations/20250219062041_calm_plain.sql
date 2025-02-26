-- Drop existing policies for parts table
DROP POLICY IF EXISTS "Taller can create parts" ON parts;
DROP POLICY IF EXISTS "Taller can view their parts" ON parts;
DROP POLICY IF EXISTS "Admin can view parts in review" ON parts;
DROP POLICY IF EXISTS "Provider can view assigned parts" ON parts;
DROP POLICY IF EXISTS "Contador can view parts in final stage" ON parts;

-- Create more permissive policies for parts table
CREATE POLICY "Anyone can view parts"
  ON parts FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Taller can create and modify parts"
  ON parts FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'taller'
      AND is_approved = true
    )
  );

CREATE POLICY "Admin can manage parts"
  ON parts FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'admin'
      AND is_approved = true
    )
  );

-- Grant necessary permissions
GRANT ALL ON parts TO authenticated;
GRANT ALL ON units TO authenticated;
GRANT ALL ON providers TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE providers ENABLE ROW LEVEL SECURITY;