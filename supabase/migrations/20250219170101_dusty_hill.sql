/*
  # Edge Functions Setup

  1. New Tables
    - `email_verifications`
      - `id` (uuid, primary key)
      - `email` (text, unique)
      - `token` (text)
      - `verified` (boolean)
      - `created_at` (timestamp)
      - `verified_at` (timestamp)

  2. Functions
    - `request_email_verification`
    - `verify_email`
    - `notify_provider`
    - `notify_admin`
    - `notify_contador`

  3. Security
    - Enable RLS on new tables
    - Add policies for email verification
*/

-- Create schema for edge functions if it doesn't exist
CREATE SCHEMA IF NOT EXISTS edge;

-- Create email verifications table
CREATE TABLE IF NOT EXISTS edge.email_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  token text NOT NULL,
  verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  verified_at timestamptz,
  CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Enable RLS
ALTER TABLE edge.email_verifications ENABLE ROW LEVEL SECURITY;

-- Create policy for email verifications
CREATE POLICY "Users can view their own email verification"
  ON edge.email_verifications
  FOR SELECT
  TO authenticated
  USING (email = (SELECT email FROM auth.users WHERE id = auth.uid()));

-- Function to request email verification
CREATE OR REPLACE FUNCTION edge.request_email_verification(user_email text)
RETURNS void AS $$
DECLARE
  verification_token text;
BEGIN
  -- Generate a secure random token
  verification_token := encode(gen_random_bytes(32), 'hex');
  
  -- Insert or update verification record
  INSERT INTO edge.email_verifications (email, token)
  VALUES (user_email, verification_token)
  ON CONFLICT (email) 
  DO UPDATE SET 
    token = verification_token,
    verified = false,
    created_at = now(),
    verified_at = null;

  -- Trigger edge function for sending verification email
  PERFORM net.http_post(
    url := current_setting('app.edge_function_url') || '/send-verification-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.edge_function_key')
    ),
    body := jsonb_build_object(
      'email', user_email,
      'token', verification_token
    )::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to verify email
CREATE OR REPLACE FUNCTION edge.verify_email(user_email text, verification_token text)
RETURNS boolean AS $$
DECLARE
  is_valid boolean;
BEGIN
  -- Check if token is valid
  UPDATE edge.email_verifications
  SET verified = true,
      verified_at = now()
  WHERE email = user_email
    AND token = verification_token
    AND verified = false
  RETURNING true INTO is_valid;

  RETURN COALESCE(is_valid, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to notify provider
CREATE OR REPLACE FUNCTION edge.notify_provider(part_id uuid)
RETURNS void AS $$
BEGIN
  -- Get part and provider details
  PERFORM net.http_post(
    url := current_setting('app.edge_function_url') || '/notify-provider',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.edge_function_key')
    ),
    body := (
      SELECT jsonb_build_object(
        'part_id', p.id,
        'provider_email', pr.email,
        'provider_name', pr.name,
        'part_description', p.description[1],
        'unit_name', u.name
      )
      FROM parts p
      JOIN providers pr ON p.provider_id = pr.id
      JOIN units u ON p.unit_id = u.id
      WHERE p.id = part_id
    )::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to notify admin
CREATE OR REPLACE FUNCTION edge.notify_admin(part_id uuid)
RETURNS void AS $$
BEGIN
  PERFORM net.http_post(
    url := current_setting('app.edge_function_url') || '/notify-admin',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.edge_function_key')
    ),
    body := (
      SELECT jsonb_build_object(
        'part_id', p.id,
        'admin_emails', (
          SELECT jsonb_agg(email)
          FROM profiles
          WHERE role = 'admin'
          AND is_approved = true
        ),
        'part_description', p.description[1],
        'unit_name', u.name,
        'requester_name', pr.name
      )
      FROM parts p
      JOIN units u ON p.unit_id = u.id
      JOIN profiles pr ON pr.user_id = auth.uid()
      WHERE p.id = part_id
    )::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to notify contador
CREATE OR REPLACE FUNCTION edge.notify_contador(part_id uuid)
RETURNS void AS $$
BEGIN
  PERFORM net.http_post(
    url := current_setting('app.edge_function_url') || '/notify-contador',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.edge_function_key')
    ),
    body := (
      SELECT jsonb_build_object(
        'part_id', p.id,
        'contador_emails', (
          SELECT jsonb_agg(email)
          FROM profiles
          WHERE role = 'contador'
          AND is_approved = true
        ),
        'part_description', p.description[1],
        'unit_name', u.name,
        'provider_name', pr.name
      )
      FROM parts p
      JOIN units u ON p.unit_id = u.id
      JOIN providers pr ON p.provider_id = pr.id
      WHERE p.id = part_id
    )::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger functions for notifications
CREATE OR REPLACE FUNCTION edge.handle_part_notifications()
RETURNS TRIGGER AS $$
BEGIN
  -- Only handle status changes
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Notify based on new status
  CASE NEW.status
    WHEN 2 THEN
      -- Notify admin for review
      PERFORM edge.notify_admin(NEW.id);
    WHEN 3 THEN
      -- Notify provider for review
      PERFORM edge.notify_provider(NEW.id);
    WHEN 5 THEN
      -- Notify contador for counter receipt
      PERFORM edge.notify_contador(NEW.id);
  END CASE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for notifications
DROP TRIGGER IF EXISTS tr_handle_part_notifications ON parts;
CREATE TRIGGER tr_handle_part_notifications
  AFTER UPDATE OF status ON parts
  FOR EACH ROW
  EXECUTE FUNCTION edge.handle_part_notifications();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA edge TO authenticated;
GRANT ALL ON edge.email_verifications TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA edge TO authenticated;

-- Add helpful comments
COMMENT ON TABLE edge.email_verifications IS 'Stores email verification tokens and status';
COMMENT ON FUNCTION edge.request_email_verification IS 'Generates and sends email verification token';
COMMENT ON FUNCTION edge.verify_email IS 'Verifies email using token';
COMMENT ON FUNCTION edge.notify_provider IS 'Notifies provider about new parts to review';
COMMENT ON FUNCTION edge.notify_admin IS 'Notifies admin about parts needing review';
COMMENT ON FUNCTION edge.notify_contador IS 'Notifies contador about parts needing counter receipt';