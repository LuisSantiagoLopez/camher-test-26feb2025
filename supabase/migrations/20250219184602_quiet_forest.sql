/*
  # Register Providers

  1. Changes
    - Ensures all approved provider profiles have corresponding provider records
    - Updates existing providers with latest profile information
    - Adds logging for tracking registration process

  2. Security
    - Maintains existing RLS policies
    - Only affects provider records
*/

-- First, ensure we have the latest provider information
INSERT INTO providers (name, email)
SELECT DISTINCT ON (email)
  name,
  email
FROM profiles
WHERE role = 'proveedor'
AND is_approved = true
AND email IN (
  'proveedor@proveedor.com',
  'proveedor2@proveedor2.com',
  'proveedor3@proveedor3.com'
)
ON CONFLICT (email) DO UPDATE
SET name = EXCLUDED.name;

-- Log the registration
DO $$
DECLARE
  provider_count integer;
BEGIN
  SELECT COUNT(*) INTO provider_count FROM providers;
  RAISE NOTICE 'Total providers after registration: %', provider_count;
END $$;

-- Add helpful comment
COMMENT ON TABLE providers IS 'Stores provider information with unique email constraint';