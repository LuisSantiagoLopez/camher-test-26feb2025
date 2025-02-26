-- Create email notifications tracking table
CREATE TABLE IF NOT EXISTS email_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  part_id uuid REFERENCES parts(id) ON DELETE CASCADE,
  recipient text NOT NULL,
  type text NOT NULL CHECK (type IN ('verification', 'provider_review', 'admin_review', 'contador_receipt')),
  status text NOT NULL CHECK (status IN ('pending', 'sent', 'failed')),
  error text,
  created_at timestamptz DEFAULT now(),
  sent_at timestamptz
);

-- Enable RLS
ALTER TABLE email_notifications ENABLE ROW LEVEL SECURITY;

-- Create policy for viewing email notifications
CREATE POLICY "Users can view their notifications"
  ON email_notifications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND is_approved = true
      AND (
        -- Users can see their own notifications
        email = recipient
        -- Admins can see all notifications
        OR role = 'admin'
      )
    )
  );

-- Create function to log email notifications
CREATE OR REPLACE FUNCTION log_email_notification(
  p_part_id uuid,
  p_recipient text,
  p_type text,
  p_status text DEFAULT 'pending',
  p_error text DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  v_notification_id uuid;
BEGIN
  INSERT INTO email_notifications (
    part_id,
    recipient,
    type,
    status,
    error
  ) VALUES (
    p_part_id,
    p_recipient,
    p_type,
    p_status,
    p_error
  ) RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to update notification status
CREATE OR REPLACE FUNCTION update_notification_status(
  p_notification_id uuid,
  p_status text,
  p_error text DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  UPDATE email_notifications
  SET 
    status = p_status,
    error = p_error,
    sent_at = CASE WHEN p_status = 'sent' THEN now() ELSE sent_at END
  WHERE id = p_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger function to log notifications when part status changes
CREATE OR REPLACE FUNCTION handle_part_status_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Only handle status changes
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Log notifications based on new status
  CASE NEW.status
    WHEN 2 THEN
      -- Notify admins
      PERFORM log_email_notification(
        NEW.id,
        admin.email,
        'admin_review'
      )
      FROM profiles admin
      WHERE admin.role = 'admin'
      AND admin.is_approved = true;
    
    WHEN 3 THEN
      -- Notify provider
      PERFORM log_email_notification(
        NEW.id,
        provider.email,
        'provider_review'
      )
      FROM providers provider
      WHERE provider.id = NEW.provider_id;
    
    WHEN 5 THEN
      -- Notify contadores
      PERFORM log_email_notification(
        NEW.id,
        contador.email,
        'contador_receipt'
      )
      FROM profiles contador
      WHERE contador.role = 'contador'
      AND contador.is_approved = true;
  END CASE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for notification logging
DROP TRIGGER IF EXISTS tr_handle_part_status_notification ON parts;
CREATE TRIGGER tr_handle_part_status_notification
  AFTER UPDATE OF status ON parts
  FOR EACH ROW
  EXECUTE FUNCTION handle_part_status_notification();

-- Grant necessary permissions
GRANT ALL ON email_notifications TO authenticated;
GRANT EXECUTE ON FUNCTION log_email_notification TO authenticated;
GRANT EXECUTE ON FUNCTION update_notification_status TO authenticated;

-- Add helpful comments
COMMENT ON TABLE email_notifications IS 'Tracks all email notifications sent by the system';
COMMENT ON FUNCTION log_email_notification IS 'Logs a new email notification';
COMMENT ON FUNCTION update_notification_status IS 'Updates the status of an email notification';
COMMENT ON FUNCTION handle_part_status_notification IS 'Automatically logs notifications when part status changes';