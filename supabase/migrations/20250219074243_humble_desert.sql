-- Drop existing policies for part_files
DROP POLICY IF EXISTS "Users can view part files" ON part_files;
DROP POLICY IF EXISTS "Users can insert part files" ON part_files;

-- Create more specific policies for part_files
CREATE POLICY "Users can view part files"
  ON part_files FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND is_approved = true
    )
  );

CREATE POLICY "Taller can manage part files"
  ON part_files FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'taller'
      AND is_approved = true
    )
  );

CREATE POLICY "Admin can manage part files"
  ON part_files FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'admin'
      AND is_approved = true
    )
  );

CREATE POLICY "Provider can manage part files"
  ON part_files FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'proveedor'
      AND is_approved = true
    )
  );

CREATE POLICY "Contador can manage part files"
  ON part_files FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'contador'
      AND is_approved = true
    )
  );

-- Grant necessary permissions
GRANT ALL ON part_files TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE part_files ENABLE ROW LEVEL SECURITY;