/*
  # Clean up Email Notifications

  1. Changes
    - Drops email notification triggers
    - Drops email notification functions
    - Drops email notification tables
    - Drops edge schema and its contents safely

  2. Security
    - Maintains existing RLS policies
    - Preserves data integrity
*/

-- First drop triggers that might reference the functions
DROP TRIGGER IF EXISTS tr_handle_part_notifications ON parts;
DROP TRIGGER IF EXISTS tr_handle_part_status_notification ON parts;

-- Drop functions in the public schema
DROP FUNCTION IF EXISTS handle_part_notifications() CASCADE;
DROP FUNCTION IF EXISTS handle_part_status_notification() CASCADE;
DROP FUNCTION IF EXISTS check_notification_status() CASCADE;

-- Drop email notifications table
DROP TABLE IF EXISTS email_notifications CASCADE;

-- Drop edge schema functions one by one
DO $$
BEGIN
  -- Drop functions if they exist
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'edge' AND p.proname = 'notify_part_status_change') THEN
    DROP FUNCTION edge.notify_part_status_change() CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'edge' AND p.proname = 'notify_provider') THEN
    DROP FUNCTION edge.notify_provider() CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'edge' AND p.proname = 'notify_admin') THEN
    DROP FUNCTION edge.notify_admin() CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'edge' AND p.proname = 'notify_contador') THEN
    DROP FUNCTION edge.notify_contador() CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'edge' AND p.proname = 'request_email_verification') THEN
    DROP FUNCTION edge.request_email_verification() CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'edge' AND p.proname = 'verify_email') THEN
    DROP FUNCTION edge.verify_email() CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'edge' AND p.proname = 'log_email_notification') THEN
    DROP FUNCTION edge.log_email_notification() CASCADE;
  END IF;
END $$;

-- Drop edge schema tables
DROP TABLE IF EXISTS edge.email_verifications CASCADE;

-- Finally drop the edge schema
DROP SCHEMA IF EXISTS edge;