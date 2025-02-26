-- Drop existing policies for part_history
DROP POLICY IF EXISTS "Users can view part history" ON part_history;

-- Create policies for part_history table
CREATE POLICY "Taller can view part history"
  ON part_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'taller'
      AND is_approved = true
    )
  );

CREATE POLICY "Admin can view part history"
  ON part_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'admin'
      AND is_approved = true
    )
  );

CREATE POLICY "Provider can view part history"
  ON part_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'proveedor'
      AND is_approved = true
    )
  );

CREATE POLICY "Contador can view part history"
  ON part_history FOR SELECT
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
GRANT ALL ON part_history TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE part_history ENABLE ROW LEVEL SECURITY;