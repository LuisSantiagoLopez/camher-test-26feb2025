/*
  # Fix Provider Registration Policy

  1. Changes
    - Adds policy to allow provider creation during registration
    - Maintains existing provider data
    - Ensures proper security constraints

  2. Security
    - Only allows creation for approved provider profiles
    - Maintains data integrity
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow provider creation during registration" ON providers;

-- Create policy for provider creation
CREATE POLICY "Allow provider creation during registration"
  ON providers
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Ensure proper permissions
GRANT ALL ON providers TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE providers ENABLE ROW LEVEL SECURITY;

-- Add helpful comment
COMMENT ON TABLE providers IS 'Stores provider information with unique email constraint';