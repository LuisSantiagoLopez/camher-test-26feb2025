-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can view history" ON part_history;
DROP POLICY IF EXISTS "Users can create history records" ON part_history;
DROP POLICY IF EXISTS "Full access to part history" ON part_history;

-- Create a single, permissive policy for part_history
CREATE POLICY "Full access to part history"
  ON part_history
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
GRANT ALL ON part_history TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE part_history ENABLE ROW LEVEL SECURITY;

-- Add helpful comment
COMMENT ON TABLE part_history IS 'Tracks status changes for parts with RLS enabled for authenticated users';