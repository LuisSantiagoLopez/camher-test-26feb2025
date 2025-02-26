/*
  # Fix Notifications System

  1. Changes
    - Removes dependency on net schema
    - Simplifies notification handling
    - Adds direct notification tracking

  2. Security
    - Maintains RLS policies
    - Ensures proper access control
*/

-- Create email notifications table if it doesn't exist
CREATE TABLE IF NOT EXISTS email_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  part_id uuid REFERENCES parts(id) ON DELETE CASCADE,
  recipient text NOT NULL,
  type text NOT NULL CHECK (type IN ('verification', 'provider_review', 'admin_review', 'contador_receipt')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  error text,
  created_at timestamptz DEFAULT now(),
  sent_at timestamptz
);

-- Enable RLS
ALTER TABLE email_notifications ENABLE ROW LEVEL SECURITY;

-- Create policy for viewing email notifications
CREATE POLICY "Users can view notifications"
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

-- Grant necessary permissions
GRANT ALL ON email_notifications TO authenticated;

-- Add helpful comments
COMMENT ON TABLE email_notifications IS 'Tracks all email notifications in the system';
COMMENT ON COLUMN email_notifications.type IS 'Type of notification: verification, provider_review, admin_review, contador_receipt';
COMMENT ON COLUMN email_notifications.status IS 'Status of the notification: pending, sent, or failed';