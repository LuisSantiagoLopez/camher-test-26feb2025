-- Drop existing policies
DROP POLICY IF EXISTS "Admin has full access" ON parts;
DROP POLICY IF EXISTS "Taller has full access" ON parts;
DROP POLICY IF EXISTS "Provider can view assigned parts" ON parts;
DROP POLICY IF EXISTS "Provider can update assigned parts" ON parts;
DROP POLICY IF EXISTS "Contador can view parts in final stage" ON parts;
DROP POLICY IF EXISTS "Contador can update parts with invoices" ON parts;

-- Create a single policy that gives full access to all authenticated users
CREATE POLICY "Full access for authenticated users"
  ON parts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND is_approved = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND is_approved = true
    )
  );

-- Ensure proper permissions
GRANT ALL ON parts TO authenticated;
GRANT ALL ON part_history TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON part_files TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;