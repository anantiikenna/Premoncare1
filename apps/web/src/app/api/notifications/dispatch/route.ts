import { createClient } from '@/lib/supabase-server';
import { sendNotification as sendPush } from '@/lib/notification-service';
import { sendEmail, templates } from '@/lib/email-service';
import { NextResponse, type NextRequest } from 'next/server';
import { withSecurity, sanitizeObject } from '@/lib/security';
import { z } from 'zod';

const dispatchSchema = z.object({
  userId: z.string().uuid(),
  title: z.string(),
  message: z.string(),
  type: z.enum(['appointment', 'payment', 'prescription', 'message', 'system', 'other']),
  link: z.string().optional(),
  sendEmail: z.boolean().default(false),
  emailTemplate: z.string().optional(),
  emailData: z.record(z.string(), z.any()).optional(),
});

async function dispatchHandler(req: NextRequest) {
  const jsonBody = await req.json();
  const parsed = dispatchSchema.safeParse(jsonBody);

  if (!parsed.success) {
    return NextResponse.json({ success: false, error: parsed.error }, { status: 400 });
  }

  const { userId, title, message, type, link, sendEmail: shouldEmail, emailTemplate, emailData } = sanitizeObject(parsed.data);
  
  const supabase = await createClient();

  // 1. Fetch user profile for email/settings
  const { data: profile } = await supabase
    .from('profiles')
    .select('email, full_name, email_alerts_enabled')
    .eq('id', userId)
    .single();

  if (!profile) {
    return NextResponse.json({ success: false, error: 'User not found' }, { status: 404 });
  }

  // 2. Send Push Notification (always attempt if it's a dispatch)
  const pushResult = await sendPush({
    user_id: userId,
    title,
    message,
    type,
    link,
  });

  // 3. Optional: Send Email
  let emailResult = null;
  if (shouldEmail && profile.email && profile.email_alerts_enabled !== false) {
    // Determine template logic here or via emailTemplate key
    // For simplicity, we can pass raw subject/html or a template key
    // (Translating existing templates here)
    let emailContent = null;
    
    // Example logic for template mapping
    if (emailTemplate === 'paymentApproval' && emailData) {
        emailContent = templates.paymentApproval(profile.full_name, emailData.amount as number, emailData.status as string);
    } else if (emailTemplate === 'doctorAppointment' && emailData) {
        emailContent = templates.doctorAppointment(profile.full_name, emailData.patientName as string, emailData.date as string, emailData.duration as number);
    }

    if (emailContent) {
        emailResult = await sendEmail({
            to: profile.email,
            subject: emailContent.subject,
            html: emailContent.html
        });
    }
  }

  return NextResponse.json({
    success: true,
    push: pushResult,
    email: emailResult
  });
}

export async function POST(req: NextRequest) {
  // We allow internal system calls, but want to ensure some level of protection
  // In a real prod app, we'd use a secret header or internal network check
  return withSecurity(req, dispatchHandler, { requireAuth: true });
}

export async function OPTIONS(req: NextRequest) {
  return withSecurity(req, async () => NextResponse.json({}), { requireAuth: false });
}
