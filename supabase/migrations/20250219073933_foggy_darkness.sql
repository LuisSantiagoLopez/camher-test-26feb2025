-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can view units" ON units;

-- Create policies for units table
CREATE POLICY "Taller can manage units"
  ON units FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'taller'
      AND is_approved = true
    )
  );

CREATE POLICY "Other roles can view units"
  ON units FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role != 'taller'
      AND is_approved = true
    )
  );

-- Grant necessary permissions
GRANT ALL ON units TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE units ENABLE ROW LEVEL SECURITY;