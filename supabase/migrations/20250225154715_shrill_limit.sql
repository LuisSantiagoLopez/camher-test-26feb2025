-- Add created_by column to parts table if it doesn't exist
DO $$ 
BEGIN
  -- First check if the column exists
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'parts' 
    AND column_name = 'created_by'
  ) THEN
    -- Add the column
    ALTER TABLE parts ADD COLUMN created_by uuid REFERENCES auth.users(id);
    
    -- Update existing records with a default value
    WITH default_user AS (
      SELECT user_id 
      FROM profiles 
      WHERE role = 'taller' 
      ORDER BY created_at ASC 
      LIMIT 1
    )
    UPDATE parts 
    SET created_by = (SELECT user_id FROM default_user)
    WHERE created_by IS NULL;
    
    -- Make the column required
    ALTER TABLE parts ALTER COLUMN created_by SET NOT NULL;
  END IF;
END $$;

-- Add helpful comment
COMMENT ON COLUMN parts.created_by IS 'UUID of the user who created the part';

-- Drop existing policies
DROP POLICY IF EXISTS "Full access for authenticated users" ON parts;
DROP POLICY IF EXISTS "Taller can view all their parts" ON parts;
DROP POLICY IF EXISTS "Taller can create and modify parts" ON parts;
DROP POLICY IF EXISTS "Admin full access" ON parts;
DROP POLICY IF EXISTS "Provider access" ON parts;
DROP POLICY IF EXISTS "Contador access" ON parts;

-- Create new policies with updated access rules

-- Admin policy: full access to all parts
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

-- Taller policy: only view and edit their own parts
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
    AND created_by = auth.uid()
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'taller'
      AND is_approved = true
    )
    AND created_by = auth.uid()
    AND status IN (0, 1)
  );

-- Provider policy: only view assigned parts
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
    AND status >= 3
    AND status != -1
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
    AND status IN (3, 4)
  );

-- Contador policy: view all parts in status 4 or higher
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
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'contador'
      AND is_approved = true
    )
    AND status IN (4, 5)
  );