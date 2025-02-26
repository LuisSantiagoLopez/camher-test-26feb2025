/*
  # Fix View Security

  1. Changes
    - Creates secure views with proper access control
    - Removes invalid RLS policies on views
    - Ensures proper permissions

  2. Security
    - Implements security through view definitions
    - Maintains data access control
*/

-- Drop existing views if they exist
DROP VIEW IF EXISTS counter_receipt_summary;
DROP VIEW IF EXISTS invoice_summary;
DROP VIEW IF EXISTS part_summary;

-- Create secure views that incorporate access control in their definitions
CREATE OR REPLACE VIEW part_summary AS
SELECT 
  status,
  COUNT(*) as total_parts,
  SUM(price) as total_amount,
  COUNT(*) FILTER (WHERE is_cash) as cash_parts,
  SUM(price) FILTER (WHERE is_cash) as cash_amount,
  COUNT(*) FILTER (WHERE NOT is_cash) as transfer_parts,
  SUM(price) FILTER (WHERE NOT is_cash) as transfer_amount
FROM parts
WHERE EXISTS (
  SELECT 1 FROM profiles
  WHERE user_id = auth.uid()
  AND role IN ('admin', 'contador')
  AND is_approved = true
)
GROUP BY status;

CREATE OR REPLACE VIEW invoice_summary AS
SELECT 
  p.provider_id,
  pr.name as provider_name,
  COUNT(*) as total_invoices,
  SUM(p.price) as total_amount,
  COUNT(*) FILTER (WHERE p.status = 4) as pending_counter_receipt,
  SUM(p.price) FILTER (WHERE p.status = 4) as pending_amount,
  COUNT(*) FILTER (WHERE p.status = 5) as with_counter_receipt,
  SUM(p.price) FILTER (WHERE p.status = 5) as completed_amount
FROM parts p
JOIN providers pr ON p.provider_id = pr.id
WHERE p.status >= 4
AND EXISTS (
  SELECT 1 FROM profiles
  WHERE user_id = auth.uid()
  AND role IN ('admin', 'contador')
  AND is_approved = true
)
GROUP BY p.provider_id, pr.name;

CREATE OR REPLACE VIEW counter_receipt_summary AS
SELECT 
  DATE_TRUNC('month', pf.created_at) as month,
  COUNT(*) as total_receipts,
  SUM(p.price) as total_amount
FROM parts p
JOIN part_files pf ON p.id = pf.part_id
WHERE 
  p.status = 5 
  AND pf.file_type = 'counter_receipt'
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = auth.uid()
    AND role IN ('admin', 'contador')
    AND is_approved = true
  )
GROUP BY DATE_TRUNC('month', pf.created_at)
ORDER BY month DESC;

-- Grant necessary permissions
GRANT SELECT ON part_summary TO authenticated;
GRANT SELECT ON invoice_summary TO authenticated;
GRANT SELECT ON counter_receipt_summary TO authenticated;

-- Add helpful comments
COMMENT ON VIEW part_summary IS 'Secure view showing summary of parts by status (admin and contador only)';
COMMENT ON VIEW invoice_summary IS 'Secure view showing summary of invoices by provider (admin and contador only)';
COMMENT ON VIEW counter_receipt_summary IS 'Secure view showing summary of counter receipts by month (admin and contador only)';