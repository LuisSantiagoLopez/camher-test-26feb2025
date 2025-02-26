-- Drop existing admin policies
DROP POLICY IF EXISTS "Admin can update any part" ON parts;
DROP POLICY IF EXISTS "Admin can view parts in review" ON parts;

-- Create new admin policies with broader permissions
CREATE POLICY "Admin can manage all parts"
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

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;