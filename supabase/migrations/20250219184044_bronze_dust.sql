-- Create providers for approved provider profiles
INSERT INTO providers (name, email)
SELECT 
  name,
  email
FROM profiles
WHERE role = 'proveedor'
AND is_approved = true
AND NOT EXISTS (
  SELECT 1 FROM providers 
  WHERE providers.email = profiles.email
)
ON CONFLICT (email) DO UPDATE
SET name = EXCLUDED.name;

-- Add helpful comment
COMMENT ON TABLE providers IS 'Stores provider information with unique email constraint';

-- Log the registration
DO $$
DECLARE
  registered_count integer;
BEGIN
  GET DIAGNOSTICS registered_count = ROW_COUNT;
  RAISE NOTICE 'Registered % new providers', registered_count;
END $$;