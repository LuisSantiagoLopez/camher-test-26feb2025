-- Drop existing views if they exist
DROP VIEW IF EXISTS counter_receipt_summary;
DROP VIEW IF EXISTS invoice_summary;
DROP VIEW IF EXISTS part_summary;

-- Create view for part summary with security barrier
CREATE VIEW part_summary WITH (security_barrier) AS
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

-- Create view for invoice summary with security barrier
CREATE VIEW invoice_summary WITH (security_barrier) AS
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

-- Create view for counter receipt summary with security barrier
CREATE VIEW counter_receipt_summary WITH (security_barrier) AS
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

-- Grant permissions to views
GRANT SELECT ON part_summary TO authenticated;
GRANT SELECT ON invoice_summary TO authenticated;
GRANT SELECT ON counter_receipt_summary TO authenticated;

-- Add helpful comments
COMMENT ON VIEW part_summary IS 'Resumen de refacciones por estado';
COMMENT ON VIEW invoice_summary IS 'Resumen de facturas por proveedor';
COMMENT ON VIEW counter_receipt_summary IS 'Resumen de contrarecibos por mes';

-- Function to get part status text (if not exists)
CREATE OR REPLACE FUNCTION get_part_status_text(status integer)
RETURNS text AS $$
BEGIN
  RETURN CASE status
    WHEN -1 THEN 'Cancelada'
    WHEN 0 THEN 'Inicial/Rechazada'
    WHEN 1 THEN 'Creada'
    WHEN 2 THEN 'Revisión Admin'
    WHEN 3 THEN 'Revisión Proveedor'
    WHEN 4 THEN 'Esperando Factura'
    WHEN 5 THEN 'Esperando Contrarecibo'
    ELSE 'Desconocido'
  END;
END;
$$ LANGUAGE plpgsql;