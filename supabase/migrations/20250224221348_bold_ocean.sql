-- Drop any existing triggers that might reference the net schema
DROP TRIGGER IF EXISTS tr_handle_part_notifications ON parts;
DROP FUNCTION IF EXISTS edge.handle_part_notifications();
DROP FUNCTION IF EXISTS edge.notify_part_status_change();

-- Create or replace the notifications function
CREATE OR REPLACE FUNCTION handle_part_notifications()
RETURNS TRIGGER AS $$
DECLARE
  v_provider_email text;
  v_admin_emails text[];
  v_contador_emails text[];
BEGIN
  -- Only proceed if status has changed
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Handle notifications based on new status
  CASE NEW.status
    WHEN 2 THEN
      -- Get admin emails and create notifications
      INSERT INTO email_notifications (part_id, recipient, type, status)
      SELECT 
        NEW.id,
        p.email,
        'admin_review',
        'pending'
      FROM profiles p
      WHERE p.role = 'admin'
      AND p.is_approved = true;

    WHEN 3 THEN
      -- Get provider email and create notification
      SELECT email INTO v_provider_email
      FROM providers
      WHERE id = NEW.provider_id;

      IF v_provider_email IS NOT NULL THEN
        INSERT INTO email_notifications (part_id, recipient, type, status)
        VALUES (NEW.id, v_provider_email, 'provider_review', 'pending');
      END IF;

    WHEN 5 THEN
      -- Get contador emails and create notifications
      INSERT INTO email_notifications (part_id, recipient, type, status)
      SELECT 
        NEW.id,
        p.email,
        'contador_receipt',
        'pending'
      FROM profiles p
      WHERE p.role = 'contador'
      AND p.is_approved = true;
  END CASE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
CREATE TRIGGER tr_handle_part_notifications
  AFTER UPDATE OF status ON parts
  FOR EACH ROW
  EXECUTE FUNCTION handle_part_notifications();

-- Ensure proper permissions
GRANT ALL ON email_notifications TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION handle_part_notifications IS 'Creates notification records when part status changes';