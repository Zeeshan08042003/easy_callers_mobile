import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const { email, name, otp, role } = await req.json();

        if (!email || !otp) {
            return new Response(
                JSON.stringify({ error: "email and otp are required" }),
                { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        if (!RESEND_API_KEY) {
            console.error("RESEND_API_KEY is not set");
            return new Response(
                JSON.stringify({ error: "Email service not configured" }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        const roleLabel = role === "manager" ? "Manager" : "Employee";
        const greeting = name ? `Hello ${name}` : "Hello";

        const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
      </head>
      <body style="margin:0;padding:0;background-color:#f5f5f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
        <div style="max-width:480px;margin:40px auto;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
          <!-- Header -->
          <div style="background:#2D201C;padding:32px 24px;text-align:center;">
            <h1 style="color:#ffffff;margin:0;font-size:24px;font-weight:700;">Easy Callers</h1>
            <p style="color:rgba(255,255,255,0.7);margin:8px 0 0;font-size:14px;">Account Activation</p>
          </div>
          
          <!-- Body -->
          <div style="padding:32px 24px;">
            <p style="color:#333;font-size:16px;margin:0 0 8px;">${greeting},</p>
            <p style="color:#666;font-size:14px;line-height:1.6;margin:0 0 24px;">
              Your <strong>${roleLabel}</strong> account has been created on Easy Callers. 
              Use the verification code below to activate your account.
            </p>
            
            <!-- OTP Box -->
            <div style="background:#f8f5f3;border:2px solid #2D201C;border-radius:12px;padding:24px;text-align:center;margin:0 0 24px;">
              <p style="color:#999;font-size:12px;text-transform:uppercase;letter-spacing:2px;margin:0 0 12px;font-weight:600;">Your Activation Code</p>
              <p style="color:#2D201C;font-size:36px;font-weight:800;letter-spacing:8px;margin:0;">${otp}</p>
            </div>
            
            <p style="color:#666;font-size:13px;line-height:1.6;margin:0 0 8px;">
              <strong>How to activate:</strong>
            </p>
            <ol style="color:#666;font-size:13px;line-height:1.8;margin:0 0 24px;padding-left:20px;">
              <li>Open the Easy Callers app</li>
              <li>Tap <strong>"First time login? Activate with OTP"</strong></li>
              <li>Enter your email: <strong>${email}</strong></li>
              <li>Enter the code above</li>
              <li>Set your password</li>
            </ol>
            
            <div style="background:#fff8e1;border-radius:8px;padding:12px 16px;margin:0 0 16px;">
              <p style="color:#f57c00;font-size:12px;margin:0;">
                ⏳ This code is valid for <strong>24 hours</strong>. If it expires, ask your administrator to resend it.
              </p>
            </div>
          </div>
          
          <!-- Footer -->
          <div style="background:#fafafa;padding:16px 24px;text-align:center;border-top:1px solid #eee;">
            <p style="color:#999;font-size:11px;margin:0;">
              If you didn't request this, please ignore this email.
            </p>
          </div>
        </div>
      </body>
      </html>
    `;

        const res = await fetch("https://api.resend.com/emails", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${RESEND_API_KEY}`,
            },
            body: JSON.stringify({
                from: "Easy Callers <onboarding@resend.dev>",
                to: [email],
                subject: `Your Easy Callers Activation Code: ${otp}`,
                html: htmlContent,
            }),
        });

        const data = await res.json();

        if (!res.ok) {
            console.error("Resend API error:", data);
            return new Response(
                JSON.stringify({ error: "Failed to send email", details: data }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        return new Response(
            JSON.stringify({ success: true, message: "OTP email sent" }),
            { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    } catch (error: unknown) {
        console.error("Error:", error);
        const message = error instanceof Error ? error.message : String(error);
        return new Response(
            JSON.stringify({ error: message }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
});
