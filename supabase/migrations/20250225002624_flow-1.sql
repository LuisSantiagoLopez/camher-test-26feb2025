/*
  # Fix Policy Conflicts

  1. Changes
    - Drops existing policies to avoid conflicts
    - Recreates necessary policies with updated conditions
    - Ensures proper RLS setup for parts table

  2. Security
    - Maintains existing security model
    - Updates policies to be more specific and secure
*/

-- First drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Taller can view all their parts" ON parts;
DROP POLICY IF EXISTS "Taller can create parts" ON parts;
DROP POLICY IF EXISTS "Taller can modify parts in status 0" ON parts;
DROP POLICY IF EXISTS "Admin can view all parts" ON parts;
DROP POLICY IF EXISTS "Admin can update parts in review" ON parts;
DROP POLICY IF EXISTS "Provider can view assigned parts" ON parts;
DROP POLICY IF EXISTS "Provider can update assigned parts" ON parts;
DROP POLICY IF EXISTS "Contador can view parts in final stage" ON parts;
DROP POLICY IF EXISTS "Contador can update parts with invoices" ON parts;

-- Create updated policies
CREATE POLICY "Taller can view all their parts"
  ON parts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'taller'
      AND is_approved = true
    )
  );

CREATE POLICY "Taller can create and modify parts"
  ON parts FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'taller'
      AND is_approved = true
    )
  );

CREATE POLICY "Admin full access"
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

CREATE POLICY "Provider access"
  ON parts FOR ALL
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
  );

CREATE POLICY "Contador access"
  ON parts FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'contador'
      AND is_approved = true
    )
    AND status >= 4
    AND status != -1
  );

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;

-- Add helpful comments
COMMENT ON POLICY "Taller can view all their parts" ON parts IS 'Allows workshop users to view all parts';
COMMENT ON POLICY "Taller can create and modify parts" ON parts IS 'Allows workshop users to manage parts';
COMMENT ON POLICY "Admin full access" ON parts IS 'Gives administrators full access to all parts';
COMMENT ON POLICY "Provider access" ON parts IS 'Allows providers to access parts in relevant states';
COMMENT ON POLICY "Contador access" ON parts IS 'Allows accountants to access parts in final stages';