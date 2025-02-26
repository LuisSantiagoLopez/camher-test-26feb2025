import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7'
import { SmtpClient } from "https://deno.land/x/smtp@v0.7.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email, token } = await req.json()

    // Create SMTP client
    const client = new SmtpClient();

    // Connect to SMTP server
    await client.connectTLS({
      hostname: Deno.env.get('SMTP_HOSTNAME')!,
      port: parseInt(Deno.env.get('SMTP_PORT')!),
      username: Deno.env.get('SMTP_USERNAME')!,
      password: Deno.env.get('SMTP_PASSWORD')!,
    });

    // Send verification email
    await client.send({
      from: Deno.env.get('SMTP_FROM')!,
      to: email,
      subject: "Verifica tu correo electrónico",
      content: `
        <h1>Verificación de Correo Electrónico</h1>
        <p>Por favor haz clic en el siguiente enlace para verificar tu correo electrónico:</p>
        <a href="${Deno.env.get('APP_URL')}/verify-email?token=${token}&email=${encodeURIComponent(email)}">
          Verificar Correo Electrónico
        </a>
      `,
      html: true,
    });

    await client.close();

    return new Response(
      JSON.stringify({ message: 'Verification email sent' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})