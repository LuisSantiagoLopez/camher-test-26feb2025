-- Drop existing policies for part_files
DROP POLICY IF EXISTS "Users can view part files" ON part_files;
DROP POLICY IF EXISTS "Users can insert part files" ON part_files;
DROP POLICY IF EXISTS "Taller can manage part files" ON part_files;
DROP POLICY IF EXISTS "Admin can manage part files" ON part_files;
DROP POLICY IF EXISTS "Provider can manage part files" ON part_files;
DROP POLICY IF EXISTS "Contador can manage part files" ON part_files;

-- Create a single, permissive policy for part_files
CREATE POLICY "Full access to part files"
  ON part_files
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND is_approved = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND is_approved = true
    )
  );

-- Drop existing storage policies
DROP POLICY IF EXISTS "Users can view files they have access to" ON storage.objects;

-- Create more permissive storage policy
CREATE POLICY "Authenticated users can access files"
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (bucket_id = 'part_files')
  WITH CHECK (bucket_id = 'part_files');

-- Ensure proper permissions
GRANT ALL ON part_files TO authenticated;
GRANT ALL ON parts TO authenticated;

-- Ensure RLS is enabled
ALTER TABLE part_files ENABLE ROW LEVEL SECURITY;

-- Add helpful comments
COMMENT ON TABLE part_files IS 'Stores file metadata for parts with RLS enabled for authenticated users';
COMMENT ON POLICY "Full access to part files" ON part_files IS 'Allows all authenticated users to manage part files';
COMMENT ON POLICY "Authenticated users can access files" ON storage.objects IS 'Allows all authenticated users to access files in the part_files bucket';