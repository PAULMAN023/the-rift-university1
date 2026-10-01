import { Resend } from "resend";

export async function sendEmail(to: string, subject: string, html: string) {
  if (!process.env.RESEND_API_KEY || !process.env.EMAIL_FROM) {
    return { configured: false as const };
  }
  const resend = new Resend(process.env.RESEND_API_KEY);
  const result = await resend.emails.send({
    from: process.env.EMAIL_FROM, to, subject, html
  });
  if (result.error) throw new Error(result.error.message);
  return { configured: true as const, id: result.data?.id };
}
