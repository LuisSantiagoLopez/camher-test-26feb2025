import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
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
    const { provider_email, provider_name, part_description, unit_name, part_id } = await req.json()

    // Create SMTP client
    const client = new SmtpClient();

    // Connect to SMTP server
    await client.connectTLS({
      hostname: Deno.env.get('SMTP_HOSTNAME')!,
      port: parseInt(Deno.env.get('SMTP_PORT')!),
      username: Deno.env.get('SMTP_USERNAME')!,
      password: Deno.env.get('SMTP_PASSWORD')!,
    });

    // Send notification email
    await client.send({
      from: Deno.env.get('SMTP_FROM')!,
      to: provider_email,
      subject: "Nueva Refacción para Revisión",
      content: `
        <h1>Nueva Refacción para Revisar</h1>
        <p>Hola ${provider_name},</p>
        <p>Hay una nueva refacción que requiere tu revisión:</p>
        <ul>
          <li><strong>Descripción:</strong> ${part_description}</li>
          <li><strong>Unidad:</strong> ${unit_name}</li>
        </ul>
        <p>
          <a href="${Deno.env.get('APP_URL')}/dashboard?part=${part_id}">
            Ver Detalles
          </a>
        </p>
      `,
      html: true,
    });

    await client.close();

    return new Response(
      JSON.stringify({ message: 'Provider notification sent' }),
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