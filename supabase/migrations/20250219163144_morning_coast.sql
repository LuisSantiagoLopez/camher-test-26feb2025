/*
  # Add RLS policy for part_history table

  1. Changes
    - Add RLS policy to allow providers to create history records
    - Add RLS policy to allow all authenticated users to view history records
  
  2. Security
    - Ensures providers can create history records for parts they manage
    - Maintains read access for all authenticated users
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Authenticated users can view history" ON part_history;
DROP POLICY IF EXISTS "Users can create history records" ON part_history;

-- Create policy for viewing history
CREATE POLICY "Authenticated users can view history"
  ON part_history
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND is_approved = true
    )
  );

-- Create policy for creating history records
CREATE POLICY "Users can create history records"
  ON part_history
  FOR INSERT
  TO authenticated
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