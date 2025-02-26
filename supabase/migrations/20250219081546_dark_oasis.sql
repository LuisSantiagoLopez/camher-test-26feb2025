-- Drop existing policies
DROP POLICY IF EXISTS "Role-based access to parts" ON parts;

-- Create separate policies for each role
CREATE POLICY "Admin has full access"
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

CREATE POLICY "Taller has full access"
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

CREATE POLICY "Provider can view assigned parts"
  ON parts FOR SELECT
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

CREATE POLICY "Provider can update assigned parts"
  ON parts FOR UPDATE
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

CREATE POLICY "Contador can view parts in final stage"
  ON parts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'contador'
      AND is_approved = true
    )
    AND status >= 4
    AND status != -1
  );

CREATE POLICY "Contador can update parts with invoices"
  ON parts FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'contador'
      AND is_approved = true
    )
    AND status IN (4, 5)
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'contador'
      AND is_approved = true
    )
    AND status IN (4, 5)
  );

-- Ensure proper permissions
GRANT ALL ON parts TO authenticated;
GRANT ALL ON part_history TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON part_files TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;