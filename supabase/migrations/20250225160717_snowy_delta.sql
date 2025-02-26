-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Full access for authenticated users" ON parts;
DROP POLICY IF EXISTS "Taller can view all their parts" ON parts;
DROP POLICY IF EXISTS "Taller can create and modify parts" ON parts;
DROP POLICY IF EXISTS "Admin full access" ON parts;
DROP POLICY IF EXISTS "Provider access" ON parts;
DROP POLICY IF EXISTS "Contador access" ON parts;

-- Drop the column if it exists (to ensure a clean state)
ALTER TABLE parts DROP COLUMN IF EXISTS created_by;

-- Add the created_by column
ALTER TABLE parts ADD COLUMN created_by uuid REFERENCES auth.users(id);

-- Update existing records with a default value
DO $$
DECLARE
  default_user_id uuid;
BEGIN
  -- Get a default user ID from taller role
  SELECT user_id INTO default_user_id
  FROM profiles
  WHERE role = 'taller'
  ORDER BY created_at ASC
  LIMIT 1;

  -- Update records
  IF default_user_id IS NOT NULL THEN
    UPDATE parts SET created_by = default_user_id WHERE created_by IS NULL;
  END IF;
END $$;

-- Make the column required
ALTER TABLE parts ALTER COLUMN created_by SET NOT NULL;

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
  );

-- Add helpful comment
COMMENT ON COLUMN parts.created_by IS 'UUID of the user who created the part';

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_parts_created_by ON parts(created_by);