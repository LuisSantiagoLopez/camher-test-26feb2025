-- Create email notifications table
CREATE TABLE IF NOT EXISTS email_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  part_id uuid REFERENCES parts(id) ON DELETE SET NULL,
  recipient text NOT NULL,
  type text NOT NULL CHECK (type IN ('verification', 'provider_review', 'admin_review', 'contador_receipt')),
  status text NOT NULL CHECK (status IN ('sent', 'failed')),
  error text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE email_notifications ENABLE ROW LEVEL SECURITY;

-- Create policy for viewing email notifications
CREATE POLICY "Admins can view email notifications"
  ON email_notifications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'admin'
      AND is_approved = true
    )
  );

-- Grant necessary permissions
GRANT ALL ON email_notifications TO authenticated;

-- Add helpful comments
COMMENT ON TABLE email_notifications IS 'Tracks all email notifications sent by the system';
COMMENT ON COLUMN email_notifications.type IS 'Type of notification: verification, provider_review, admin_review, contador_receipt';
COMMENT ON COLUMN email_notifications.status IS 'Status of the notification: sent or failed';

-- Modify edge functions to log email notifications
CREATE OR REPLACE FUNCTION edge.log_email_notification(
  p_part_id uuid,
  p_recipient text,
  p_type text,
  p_status text,
  p_error text DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  notification_id uuid;
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
  ) RETURNING id INTO notification_id;

  RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION edge.log_email_notification TO authenticated;