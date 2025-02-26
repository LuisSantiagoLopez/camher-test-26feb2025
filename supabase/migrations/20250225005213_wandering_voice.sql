/*
  # Final Cleanup of Email Notifications

  1. Changes
    - Safely drops email notification related objects
    - Checks for existence before dropping
*/

-- Drop triggers safely
DO $$
BEGIN
  -- Drop part notification triggers if they exist
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'tr_handle_part_notifications'
  ) THEN
    DROP TRIGGER IF EXISTS tr_handle_part_notifications ON parts;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'tr_handle_part_status_notification'
  ) THEN
    DROP TRIGGER IF EXISTS tr_handle_part_status_notification ON parts;
  END IF;
END $$;

-- Drop functions safely
DO $$
BEGIN
  -- Drop notification functions if they exist
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'handle_part_notifications'
  ) THEN
    DROP FUNCTION IF EXISTS handle_part_notifications() CASCADE;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'handle_part_status_notification'
  ) THEN
    DROP FUNCTION IF EXISTS handle_part_status_notification() CASCADE;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'check_notification_status'
  ) THEN
    DROP FUNCTION IF EXISTS check_notification_status() CASCADE;
  END IF;
END $$;

-- Drop tables safely
DO $$
BEGIN
  -- Drop notification tables if they exist
  IF EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'email_notifications'
  ) THEN
    DROP TABLE IF EXISTS email_notifications CASCADE;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'email_templates'
  ) THEN
    DROP TABLE IF EXISTS email_templates CASCADE;
  END IF;
END $$;

-- Drop types safely
DO $$
BEGIN
  -- Drop notification types if they exist
  IF EXISTS (
    SELECT 1 FROM pg_type 
    WHERE typname = 'email_notification_type'
  ) THEN
    DROP TYPE IF EXISTS email_notification_type;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_type 
    WHERE typname = 'email_notification_status'
  ) THEN
    DROP TYPE IF EXISTS email_notification_status;
  END IF;
END $$;