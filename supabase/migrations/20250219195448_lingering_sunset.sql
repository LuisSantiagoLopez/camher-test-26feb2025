-- Drop existing trigger
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
  v_notification_id uuid;
BEGIN
  -- Only proceed if status has changed
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Get part information with detailed logging
  RAISE NOTICE 'Getting part information for part ID: %', NEW.id;
  
  SELECT jsonb_build_object(
    'id', p.id,
    'description', p.description[1],
    'unit_name', u.name,
    'provider_name', pr.name,
    'price', p.price,
    'is_cash', p.is_cash
  )
  INTO v_part_info
  FROM parts p
  LEFT JOIN units u ON u.id = NEW.unit_id
  LEFT JOIN providers pr ON pr.id = NEW.provider_id
  WHERE p.id = NEW.id;

  RAISE NOTICE 'Part info: %', v_part_info;

  -- Handle notifications based on new status
  CASE NEW.status
    WHEN 2 THEN
      RAISE NOTICE 'Creating admin notifications for part: %', NEW.id;
      
      -- Get admin emails
      SELECT array_agg(email)
      INTO v_admin_emails
      FROM profiles
      WHERE role = 'admin'
      AND is_approved = true;

      RAISE NOTICE 'Found % admin recipients', array_length(v_admin_emails, 1);

      -- Create notifications for each admin
      IF v_admin_emails IS NOT NULL THEN
        INSERT INTO email_notifications (part_id, recipient, type, status)
        SELECT 
          NEW.id,
          email,
          'admin_review',
          'pending'
        FROM unnest(v_admin_emails) AS email
        RETURNING id INTO v_notification_id;
        
        RAISE NOTICE 'Created admin notification with ID: %', v_notification_id;
      END IF;

    WHEN 3 THEN
      RAISE NOTICE 'Creating provider notification for part: %', NEW.id;
      
      -- Get provider email
      SELECT email
      INTO v_provider_email
      FROM providers
      WHERE id = NEW.provider_id;

      RAISE NOTICE 'Provider email: %', v_provider_email;

      -- Create notification for provider
      IF v_provider_email IS NOT NULL THEN
        INSERT INTO email_notifications (part_id, recipient, type, status)
        VALUES (NEW.id, v_provider_email, 'provider_review', 'pending')
        RETURNING id INTO v_notification_id;
        
        RAISE NOTICE 'Created provider notification with ID: %', v_notification_id;
      END IF;

    WHEN 5 THEN
      RAISE NOTICE 'Creating contador notifications for part: %', NEW.id;
      
      -- Get contador emails
      SELECT array_agg(email)
      INTO v_contador_emails
      FROM profiles
      WHERE role = 'contador'
      AND is_approved = true;

      RAISE NOTICE 'Found % contador recipients', array_length(v_contador_emails, 1);

      -- Create notifications for each contador
      IF v_contador_emails IS NOT NULL THEN
        INSERT INTO email_notifications (part_id, recipient, type, status)
        SELECT 
          NEW.id,
          email,
          'contador_receipt',
          'pending'
        FROM unnest(v_contador_emails) AS email
        RETURNING id INTO v_notification_id;
        
        RAISE NOTICE 'Created contador notification with ID: %', v_notification_id;
      END IF;
  END CASE;

  -- Verify notification creation
  PERFORM pg_sleep(0.1); -- Small delay to ensure notification is created
  
  RAISE NOTICE 'Verifying notifications for part: %', NEW.id;
  
  SELECT COUNT(*)
  INTO v_notification_id
  FROM email_notifications
  WHERE part_id = NEW.id;
  
  RAISE NOTICE 'Found % notifications for part %', v_notification_id, NEW.id;
  
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
CREATE INDEX IF NOT EXISTS idx_email_notifications_recipient ON email_notifications(recipient);

-- Add helpful comments
COMMENT ON FUNCTION handle_part_status_notification IS 'Creates email notifications when part status changes with detailed logging';