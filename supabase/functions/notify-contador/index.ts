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
    const { contador_emails, part_description, unit_name, provider_name, part_id } = await req.json()

    // Create SMTP client
    const client = new SmtpClient();

    // Connect to SMTP server
    await client.connectTLS({
      hostname: Deno.env.get('SMTP_HOSTNAME')!,
      port: parseInt(Deno.env.get('SMTP_PORT')!),
      username: Deno.env.get('SMTP_USERNAME')!,
      password: Deno.env.get('SMTP_PASSWORD')!,
    });

    // Send notification to each contador
    for (const email of contador_emails) {
      await client.send({
        from: Deno.env.get('SMTP_FROM')!,
        to: email,
        subject: "Nueva Factura para Contrarecibo",
        content: `
          <h1>Nueva Factura para Contrarecibo</h1>
          <p>Se ha recibido una nueva factura que requiere contrarecibo:</p>
          <ul>
            <li><strong>Descripción:</strong> ${part_description}</li>
            <li><strong>Unidad:</strong> ${unit_name}</li>
            <li><strong>Proveedor:</strong> ${provider_name}</li>
          </ul>
          <p>
            <a href="${Deno.env.get('APP_URL')}/dashboard?part=${part_id}">
              Generar Contrarecibo
            </a>
          </p>
        `,
        html: true,
      });
    }

    await client.close();

    return new Response(
      JSON.stringify({ message: 'Contador notifications sent' }),
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