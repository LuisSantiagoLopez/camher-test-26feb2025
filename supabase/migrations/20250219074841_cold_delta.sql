-- Drop existing admin policy
DROP POLICY IF EXISTS "Admin can update parts in review" ON parts;

-- Create new admin policies
CREATE POLICY "Admin can update any part"
  ON parts FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'admin'
      AND is_approved = true
    )
  );

-- Ensure proper permissions
GRANT ALL ON parts TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;