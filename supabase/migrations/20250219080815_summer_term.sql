-- Drop existing provider policies
DROP POLICY IF EXISTS "Provider can view assigned parts" ON parts;
DROP POLICY IF EXISTS "Provider can update assigned parts" ON parts;
DROP POLICY IF EXISTS "Provider access" ON parts;

-- Create separate policies for viewing and updating
CREATE POLICY "Provider can view assigned parts"
  ON parts
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'proveedor'
      AND is_approved = true
    )
    AND status >= 3
    AND status != -1
  );

CREATE POLICY "Provider can update parts in review"
  ON parts
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'proveedor'
      AND is_approved = true
    )
    AND status IN (3, 4)
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'proveedor'
      AND is_approved = true
    )
    AND status IN (3, 4)
  );

-- Ensure proper permissions
GRANT ALL ON parts TO authenticated;
GRANT ALL ON part_history TO authenticated;
GRANT ALL ON profiles TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;