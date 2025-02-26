-- Drop existing policies
DROP POLICY IF EXISTS "Full access for authenticated users" ON parts;
DROP POLICY IF EXISTS "Taller can view all their parts" ON parts;
DROP POLICY IF EXISTS "Taller can create and modify parts" ON parts;
DROP POLICY IF EXISTS "Admin full access" ON parts;
DROP POLICY IF EXISTS "Provider access" ON parts;
DROP POLICY IF EXISTS "Contador access" ON parts;
DROP POLICY IF EXISTS "Taller access" ON parts;

-- Create simplified policies

-- Admin policy: full access to all parts
CREATE POLICY "Admin access"
  ON parts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'admin'
      AND is_approved = true
    )
  );

-- Taller policy: view and edit their own parts
CREATE POLICY "Taller access"
  ON parts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'taller'
      AND is_approved = true
    )
  );

-- Provider policy: view and update assigned parts
CREATE POLICY "Provider access"
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
    AND status >= 3
    AND status != -1
  );

-- Contador policy: view and update parts in final stages
CREATE POLICY "Contador access"
  ON parts
  FOR ALL
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

-- Add helpful comments
COMMENT ON POLICY "Admin access" ON parts IS 'Administrators have full access to all parts';
COMMENT ON POLICY "Taller access" ON parts IS 'Workshop users can access all parts';
COMMENT ON POLICY "Provider access" ON parts IS 'Providers can access parts in review or later stages';
COMMENT ON POLICY "Contador access" ON parts IS 'Accountants can access parts in invoice or later stages';