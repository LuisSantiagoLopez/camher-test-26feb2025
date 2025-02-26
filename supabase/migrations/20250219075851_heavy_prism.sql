-- Drop existing policies for parts
DROP POLICY IF EXISTS "Provider has full access to their parts" ON parts;
DROP POLICY IF EXISTS "Admin has full access to parts" ON parts;
DROP POLICY IF EXISTS "Taller can create parts" ON parts;
DROP POLICY IF EXISTS "Taller can view their parts" ON parts;
DROP POLICY IF EXISTS "Taller can modify parts in status 0" ON parts;

-- Create simplified policies with proper permissions
CREATE POLICY "Full access for all authenticated users"
  ON parts
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND is_approved = true
      AND (
        -- Taller can access all their parts
        (role = 'taller') OR
        -- Admin can access all parts
        (role = 'admin') OR
        -- Provider can access parts in status 3 or higher (except cancelled)
        (role = 'proveedor' AND status >= 3 AND status != -1) OR
        -- Contador can access parts in status 4 or higher (except cancelled)
        (role = 'contador' AND status >= 4 AND status != -1)
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND is_approved = true
      AND (
        -- Taller can modify their parts
        (role = 'taller') OR
        -- Admin can modify all parts
        (role = 'admin') OR
        -- Provider can modify parts in status 3 or 4
        (role = 'proveedor' AND status IN (3, 4)) OR
        -- Contador can modify parts in status 4 or 5
        (role = 'contador' AND status IN (4, 5))
      )
    )
  );

-- Ensure proper permissions
GRANT ALL ON parts TO authenticated;
GRANT ALL ON part_history TO authenticated;
GRANT ALL ON profiles TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE part_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;