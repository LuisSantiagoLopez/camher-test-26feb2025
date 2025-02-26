-- First add the created_by column and update existing records
ALTER TABLE parts ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id);

-- Update existing parts to set created_by if null
UPDATE parts
SET created_by = (
  SELECT user_id 
  FROM profiles 
  WHERE role = 'taller' 
  LIMIT 1
)
WHERE created_by IS NULL;

-- Make created_by required for future records
ALTER TABLE parts ALTER COLUMN created_by SET NOT NULL;

-- Drop existing policies
DROP POLICY IF EXISTS "Full access for authenticated users" ON parts;
DROP POLICY IF EXISTS "Taller can view all their parts" ON parts;
DROP POLICY IF EXISTS "Taller can create and modify parts" ON parts;
DROP POLICY IF EXISTS "Admin full access" ON parts;
DROP POLICY IF EXISTS "Provider access" ON parts;
DROP POLICY IF EXISTS "Contador access" ON parts;

-- Create new policies with updated access rules

-- Admin policy: acceso total a todas las refacciones
CREATE POLICY "Admin full access"
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

-- Taller policy: solo ver y editar sus propias refacciones
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
    AND (
      -- El taller solo puede ver sus propias refacciones
      auth.uid() = created_by
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'taller'
      AND is_approved = true
    )
    AND (
      -- El taller solo puede modificar sus propias refacciones
      auth.uid() = created_by
      -- Y solo en estados iniciales
      AND status IN (0, 1)
    )
  );

-- Proveedor policy: solo ver refacciones asignadas
CREATE POLICY "Provider access"
  ON parts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN providers pr ON p.email = pr.email
      WHERE p.user_id = auth.uid()
      AND p.role = 'proveedor'
      AND p.is_approved = true
      AND pr.id = provider_id
    )
    AND (
      -- Puede ver refacciones asignadas en revisión
      status = 3
      OR
      -- Puede ver refacciones que ha aceptado
      (status >= 4 AND status != -1)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN providers pr ON p.email = pr.email
      WHERE p.user_id = auth.uid()
      AND p.role = 'proveedor'
      AND p.is_approved = true
      AND pr.id = provider_id
    )
    AND status IN (3, 4) -- Solo puede modificar en estos estados
  );

-- Contador policy: ver todas las refacciones en estado 4 o superior
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
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'contador'
      AND is_approved = true
    )
    AND status IN (4, 5) -- Solo puede modificar en estos estados
  );

-- Add helpful comments
COMMENT ON COLUMN parts.created_by IS 'UUID of the user who created the part';
COMMENT ON POLICY "Admin full access" ON parts IS 'Administrators have full access to all parts';
COMMENT ON POLICY "Taller access" ON parts IS 'Workshop users can only access their own parts';
COMMENT ON POLICY "Provider access" ON parts IS 'Providers can only access parts assigned to them';
COMMENT ON POLICY "Contador access" ON parts IS 'Accountants can access all parts in status 4 or higher';