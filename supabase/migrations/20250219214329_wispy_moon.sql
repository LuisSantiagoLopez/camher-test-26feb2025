-- Create function to check notification status
CREATE OR REPLACE FUNCTION check_notification_status(p_part_id uuid)
RETURNS TABLE (
  notification_count bigint,
  pending_count bigint,
  sent_count bigint,
  failed_count bigint,
  latest_status text,
  latest_error text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as notification_count,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
    COUNT(*) FILTER (WHERE status = 'sent') as sent_count,
    COUNT(*) FILTER (WHERE status = 'failed') as failed_count,
    MAX(status) as latest_status,
    MAX(error) FILTER (WHERE status = 'failed') as latest_error
  FROM email_notifications
  WHERE part_id = p_part_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION check_notification_status TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION check_notification_status IS 'Returns detailed status information about notifications for a specific part';