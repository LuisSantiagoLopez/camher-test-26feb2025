-- Drop existing provider policies
DROP POLICY IF EXISTS "Provider can view assigned parts" ON parts;
DROP POLICY IF EXISTS "Provider can update their parts" ON parts;

-- Create new provider policy with full permissions for their parts
CREATE POLICY "Provider has full access to their parts"
  ON parts
  AS PERMISSIVE
  FOR ALL
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
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'proveedor'
      AND is_approved = true
    )
    AND status >= 3
    AND status != -1
  );

-- Ensure proper permissions are granted
GRANT ALL ON parts TO authenticated;
GRANT ALL ON part_history TO authenticated;
GRANT ALL ON profiles TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE part_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;