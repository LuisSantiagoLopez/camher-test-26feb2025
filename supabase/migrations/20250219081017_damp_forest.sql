-- Drop existing provider policies
DROP POLICY IF EXISTS "Provider can view assigned parts" ON parts;
DROP POLICY IF EXISTS "Provider can update parts in review" ON parts;

-- Create a single, comprehensive policy for providers
CREATE POLICY "Provider access to parts"
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
    AND (
      CASE 
        -- For SELECT operations
        WHEN current_setting('role') = 'authenticated' AND current_setting('request.method') = 'GET' THEN
          status >= 3 AND status != -1
        -- For UPDATE operations
        WHEN current_setting('role') = 'authenticated' AND current_setting('request.method') = 'PATCH' THEN
          status IN (3, 4)
        ELSE false
      END
    )
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