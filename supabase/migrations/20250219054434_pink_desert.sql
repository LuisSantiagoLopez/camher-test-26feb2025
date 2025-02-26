-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Users can view files they have access to" ON storage.objects;

-- Create storage policies
CREATE POLICY "Users can view files they have access to"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'part_files' AND
    EXISTS (
      SELECT 1 FROM parts p
      JOIN part_files pf ON pf.part_id = p.id
      JOIN profiles pr ON pr.user_id = auth.uid()
      WHERE 
        storage.objects.name = pf.file_path AND
        pr.is_approved = true AND
        (
          (pr.role = 'taller' AND p.status >= 1) OR
          (pr.role = 'admin' AND p.status >= 2) OR
          (pr.role = 'proveedor' AND p.status >= 3) OR
          (pr.role = 'contador' AND p.status >= 4)
        )
    )
  );

-- Ensure storage bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('part_files', 'part_files', false)
ON CONFLICT (id) DO NOTHING;
