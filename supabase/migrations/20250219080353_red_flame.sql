-- Drop existing provider policies
DROP POLICY IF EXISTS "Provider can view and update assigned parts" ON parts;
DROP POLICY IF EXISTS "Provider has full access to their parts" ON parts;
DROP POLICY IF EXISTS "Full access for all authenticated users" ON parts;

-- Create new simplified provider policy
CREATE POLICY "Provider full access"
  ON parts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'proveedor'
      AND is_approved = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'proveedor'
      AND is_approved = true
    )
  );

-- Ensure proper permissions
GRANT ALL ON parts TO authenticated;
GRANT ALL ON part_history TO authenticated;
GRANT ALL ON profiles TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;