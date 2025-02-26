-- Drop existing notification trigger
DROP TRIGGER IF EXISTS tr_handle_part_status_notification ON parts;
DROP FUNCTION IF EXISTS handle_part_status_notification();

-- Create improved trigger function for notifications
CREATE OR REPLACE FUNCTION handle_part_status_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_admin_emails text[];
  v_provider_email text;
  v_contador_emails text[];
  v_part_info jsonb;
BEGIN
  -- Only proceed if status has changed
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Get part information
  SELECT jsonb_build_object(
    'id', p.id,
    'description', p.description[1],
    'unit_name', u.name,
    'provider_name', pr.name
  )
  INTO v_part_info
  FROM parts p
  LEFT JOIN units u ON u.id = NEW.unit_id
  LEFT JOIN providers pr ON pr.id = NEW.provider_id
  WHERE p.id = NEW.id;

  -- Handle notifications based on new status
  CASE NEW.status
    WHEN 2 THEN
      -- Get admin emails
      SELECT array_agg(email)
      INTO v_admin_emails
      FROM profiles
      WHERE role = 'admin'
      AND is_approved = true;

      -- Create notifications for each admin
      IF v_admin_emails IS NOT NULL THEN
        INSERT INTO email_notifications (part_id, recipient, type, status)
        SELECT 
          NEW.id,
          email,
          'admin_review',
          'pending'
        FROM unnest(v_admin_emails) AS email;
      END IF;

    WHEN 3 THEN
      -- Get provider email
      SELECT email
      INTO v_provider_email
      FROM providers
      WHERE id = NEW.provider_id;

      -- Create notification for provider
      IF v_provider_email IS NOT NULL THEN
        INSERT INTO email_notifications (part_id, recipient, type, status)
        VALUES (NEW.id, v_provider_email, 'provider_review', 'pending');
      END IF;

    WHEN 5 THEN
      -- Get contador emails
      SELECT array_agg(email)
      INTO v_contador_emails
      FROM profiles
      WHERE role = 'contador'
      AND is_approved = true;

      -- Create notifications for each contador
      IF v_contador_emails IS NOT NULL THEN
        INSERT INTO email_notifications (part_id, recipient, type, status)
        SELECT 
          NEW.id,
          email,
          'contador_receipt',
          'pending'
        FROM unnest(v_contador_emails) AS email;
      END IF;
  END CASE;

  -- Log the notification creation
  RAISE NOTICE 'Created notifications for part % with status %', NEW.id, NEW.status;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create new trigger
CREATE TRIGGER tr_handle_part_status_notification
  AFTER UPDATE OF status ON parts
  FOR EACH ROW
  EXECUTE FUNCTION handle_part_status_notification();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_email_notifications_part_id ON email_notifications(part_id);
CREATE INDEX IF NOT EXISTS idx_email_notifications_status ON email_notifications(status);
CREATE INDEX IF NOT EXISTS idx_email_notifications_type ON email_notifications(type);

-- Add helpful comments
COMMENT ON FUNCTION handle_part_status_notification IS 'Creates email notifications when part status changes';
COMMENT ON INDEX idx_email_notifications_part_id IS 'Index for faster lookups by part_id';
COMMENT ON INDEX idx_email_notifications_status IS 'Index for filtering by notification status';
COMMENT ON INDEX idx_email_notifications_type IS 'Index for filtering by notification type';