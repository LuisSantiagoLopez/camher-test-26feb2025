-- Drop existing provider policies
DROP POLICY IF EXISTS "Provider access" ON parts;

-- Create new provider policy with updated access rules
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
    AND (
      -- Puede ver refacciones en revisión (status 3)
      status = 3
      OR
      -- Puede ver refacciones que ha aceptado (status >= 4)
      (status >= 4 AND status != -1)
      OR
      -- No puede ver refacciones rechazadas (status = 0)
      (status != 0)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'proveedor'
      AND is_approved = true
    )
    AND status IN (3, 4) -- Solo puede modificar en estos estados
  );

-- Add helpful comment
COMMENT ON POLICY "Provider access" ON parts IS 'Allows providers to view parts in review and accepted parts, but not rejected ones';