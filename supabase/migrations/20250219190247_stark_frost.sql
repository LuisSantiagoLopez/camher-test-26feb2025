/*
  # Sistema de Notificaciones por Correo

  1. Nuevas Tablas
    - `email_notifications`: Almacena el historial de notificaciones enviadas
    - `email_templates`: Almacena las plantillas de correo

  2. Funciones
    - `notify_admins`: Envía notificaciones a todos los administradores
    - `notify_provider`: Envía notificación a un proveedor específico
    - `notify_contador`: Envía notificación a los contadores

  3. Seguridad
    - RLS habilitado para todas las tablas
    - Políticas específicas por rol
*/

-- Create email templates table
CREATE TABLE IF NOT EXISTS email_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  subject text NOT NULL,
  body text NOT NULL,
  variables jsonb NOT NULL DEFAULT '[]',
  created_at timestamptz DEFAULT now()
);

-- Create email notifications table
CREATE TABLE IF NOT EXISTS email_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id uuid REFERENCES email_templates(id),
  recipient text NOT NULL,
  variables jsonb,
  status text NOT NULL CHECK (status IN ('pending', 'sent', 'failed')),
  error text,
  sent_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_notifications ENABLE ROW LEVEL SECURITY;

-- Create policies for email templates
CREATE POLICY "Admins can manage email templates"
  ON email_templates
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE user_id = auth.uid()
      AND role = 'admin'
      AND is_approved = true
    )
  );

-- Create policies for email notifications
CREATE POLICY "Users can view their own notifications"
  ON email_notifications
  FOR SELECT
  TO authenticated
  USING (
    recipient IN (
      SELECT email FROM profiles
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all notifications"
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

-- Create default email templates
INSERT INTO email_templates (name, subject, body, variables) VALUES
('admin_review', 
 'Nueva Refacción para Revisión - #{part_id}',
 'Se requiere tu revisión para la refacción #{part_description} de la unidad #{unit_name}.',
 '["part_id", "part_description", "unit_name"]'),
('provider_review',
 'Refacción Lista para Revisión - #{part_id}',
 'La refacción #{part_description} de la unidad #{unit_name} está lista para tu revisión.',
 '["part_id", "part_description", "unit_name"]'),
('contador_receipt',
 'Contrarecibo Pendiente - #{part_id}',
 'Se requiere generar contrarecibo para la refacción #{part_description} del proveedor #{provider_name}.',
 '["part_id", "part_description", "provider_name"]')
ON CONFLICT (name) DO UPDATE
SET subject = EXCLUDED.subject,
    body = EXCLUDED.body,
    variables = EXCLUDED.variables;

-- Create function to send notifications
CREATE OR REPLACE FUNCTION notify_users(
  p_template_name text,
  p_recipients text[],
  p_variables jsonb
)
RETURNS void AS $$
DECLARE
  v_template_id uuid;
BEGIN
  -- Get template ID
  SELECT id INTO v_template_id
  FROM email_templates
  WHERE name = p_template_name;

  -- Create notification records
  INSERT INTO email_notifications (template_id, recipient, variables, status)
  SELECT 
    v_template_id,
    recipient,
    p_variables,
    'pending'
  FROM unnest(p_recipients) AS recipient;

  -- Trigger edge function to send emails
  PERFORM edge.send_notifications();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT ALL ON email_templates TO authenticated;
GRANT ALL ON email_notifications TO authenticated;
GRANT EXECUTE ON FUNCTION notify_users TO authenticated;

-- Add helpful comments
COMMENT ON TABLE email_templates IS 'Stores email notification templates';
COMMENT ON TABLE email_notifications IS 'Tracks all email notifications sent by the system';
COMMENT ON FUNCTION notify_users IS 'Creates notification records and triggers email sending';