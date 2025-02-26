-- Drop existing policies
DROP POLICY IF EXISTS "Provider access to parts" ON parts;
DROP POLICY IF EXISTS "Admin has full access to parts" ON parts;
DROP POLICY IF EXISTS "Taller can create parts" ON parts;
DROP POLICY IF EXISTS "Taller can view their parts" ON parts;
DROP POLICY IF EXISTS "Taller can modify parts in status 0" ON parts;
DROP POLICY IF EXISTS "Contador can view parts in final stage" ON parts;
DROP POLICY IF EXISTS "Contador can update parts with invoices" ON parts;

-- Create a single, comprehensive policy for all roles
CREATE POLICY "Role-based access to parts" ON parts
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND is_approved = true
    AND (
      role = 'admin' OR role = 'taller' OR
      (role = 'proveedor' AND status >= 3 AND status != -1) OR
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
      role = 'admin' OR role = 'taller' OR
      (role = 'proveedor' AND status IN (3, 4)) OR
      (role = 'contador' AND status IN (4, 5))
    )
  )
);

-- Ensure proper permissions
GRANT ALL ON parts TO authenticated;
GRANT ALL ON part_history TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON part_files TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE part_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE part_files ENABLE ROW LEVEL SECURITY;