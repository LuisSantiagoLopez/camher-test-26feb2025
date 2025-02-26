-- Grant more specific permissions to auth schema
GRANT USAGE ON SCHEMA auth TO anon;
GRANT USAGE ON SCHEMA auth TO authenticated;

-- Grant specific permissions to auth tables
GRANT SELECT, INSERT ON auth.users TO anon;
GRANT SELECT ON auth.users TO authenticated;

-- Grant execute permission on auth functions
GRANT EXECUTE ON FUNCTION auth.email() TO anon;
GRANT EXECUTE ON FUNCTION auth.uid() TO anon;
GRANT EXECUTE ON FUNCTION auth.role() TO anon;
GRANT EXECUTE ON FUNCTION auth.email() TO authenticated;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;
GRANT EXECUTE ON FUNCTION auth.role() TO authenticated;

-- Ensure public schema is accessible
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant specific permissions to profiles table
GRANT ALL ON profiles TO anon;
GRANT ALL ON profiles TO authenticated;

-- Drop and recreate profile policies with simpler conditions
DROP POLICY IF EXISTS "Anyone can create a profile" ON profiles;
DROP POLICY IF EXISTS "Anyone can view profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admin can manage all profiles" ON profiles;

-- Simplified policies
CREATE POLICY "Anyone can create a profile"
  ON profiles FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Anyone can view profiles"
  ON profiles FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Anyone can update profiles"
  ON profiles FOR UPDATE
  TO anon, authenticated
  USING (true);

-- Ensure sequences are accessible if they exist
DO $$
BEGIN
  EXECUTE (
    SELECT string_agg('GRANT USAGE, SELECT ON SEQUENCE ' || quote_ident(sequence_schema) || '.' || quote_ident(sequence_name) || ' TO anon, authenticated;', E'\n')
    FROM information_schema.sequences
    WHERE sequence_schema = 'public'
  );
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;