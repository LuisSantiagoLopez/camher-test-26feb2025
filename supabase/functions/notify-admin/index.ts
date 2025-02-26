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
    const { admin_emails, part_description, unit_name, requester_name, part_id } = await req.json()

    // Create SMTP client
    const client = new SmtpClient();

    // Connect to SMTP server
    await client.connectTLS({
      hostname: Deno.env.get('SMTP_HOSTNAME')!,
      port: parseInt(Deno.env.get('SMTP_PORT')!),
      username: Deno.env.get('SMTP_USERNAME')!,
      password: Deno.env.get('SMTP_PASSWORD')!,
    });

    // Send notification to each admin
    for (const email of admin_emails) {
      await client.send({
        from: Deno.env.get('SMTP_FROM')!,
        to: email,
        subject: "Nueva Refacción para Aprobación",
        content: `
          <h1>Nueva Refacción para Aprobar</h1>
          <p>Se ha recibido una nueva solicitud de refacción que requiere tu aprobación:</p>
          <ul>
            <li><strong>Descripción:</strong> ${part_description}</li>
            <li><strong>Unidad:</strong> ${unit_name}</li>
            <li><strong>Solicitante:</strong> ${requester_name}</li>
          </ul>
          <p>
            <a href="${Deno.env.get('APP_URL')}/dashboard?part=${part_id}">
              Revisar Solicitud
            </a>
          </p>
        `,
        html: true,
      });
    }

    await client.close();

    return new Response(
      JSON.stringify({ message: 'Admin notifications sent' }),
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