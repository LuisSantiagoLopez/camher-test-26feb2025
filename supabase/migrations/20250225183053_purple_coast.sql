-- Drop existing policies
DROP POLICY IF EXISTS "Provider access" ON parts;

-- Create new provider policy with strict access control
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
      AND pr.id = provider_id -- Solo el proveedor asignado puede ver la refacción
    )
    AND status >= 3 -- Solo refacciones en estado de revisión o posterior
    AND status != -1 -- Excluir refacciones canceladas
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN providers pr ON p.email = pr.email
      WHERE p.user_id = auth.uid()
      AND p.role = 'proveedor'
      AND p.is_approved = true
      AND pr.id = provider_id -- Solo el proveedor asignado puede modificar la refacción
    )
    AND status IN (3, 4) -- Solo puede modificar en estados de revisión y facturación
  );

-- Add helpful comments
COMMENT ON POLICY "Provider access" ON parts IS 'Ensures providers can only access and modify parts specifically assigned to them';

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_parts_provider_id ON parts(provider_id);