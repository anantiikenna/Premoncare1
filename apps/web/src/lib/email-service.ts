import nodemailer from 'nodemailer'

// SMTP Configuration from Environment Variables
const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: process.env.SMTP_PORT === '465', // true for 465, false for other ports
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
    },
})

const FROM_NAME = process.env.SMTP_FROM_NAME || 'Premon Care'
const FROM_EMAIL = process.env.SMTP_FROM_EMAIL || 'no-reply@premoncare.com'

interface EmailOptions {
    to: string
    subject: string
    html: string
}

export async function sendEmail({ to, subject, html }: EmailOptions) {
    if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
        console.warn('SMTP credentials missing. Email not sent:', { to, subject })
        return { success: false, error: 'Credentials missing' }
    }

    try {
        const info = await transporter.sendMail({
            from: `"${FROM_NAME}" <${FROM_EMAIL}>`,
            to,
            subject,
            html,
        })
        return { success: true, messageId: info.messageId }
    } catch (error) {
        console.error('Error sending email:', error)
        return { success: false, error }
    }
}

// Branded Templates
export const templates = {
    consultationFee: (doctorName: string, patientName: string, amount: number, duration: number) => ({
        subject: `New P2P Payment Received - ${patientName}`,
        html: `
            <div style="font-family: 'Inter', system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; background-color: #ffffff;">
                <div style="background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); padding: 32px; text-align: center; color: #ffffff;">
                    <h1 style="margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.025em;">Premon<span style="color: #0ea5e9;">Care</span></h1>
                </div>
                <div style="padding: 40px; color: #334155; line-height: 1.6;">
                    <h2 style="margin-top: 0; color: #0f172a; font-size: 20px; font-weight: 700;">Hello Dr. ${doctorName},</h2>
                    <p style="font-size: 16px;">A patient has submitted a direct payment for a consultation with you.</p>
                    
                    <div style="background-color: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding: 24px; margin: 32px 0;">
                        <table style="width: 100%; border-collapse: collapse;">
                            <tr>
                                <td style="padding: 8px 0; color: #64748b; font-size: 14px; font-weight: 600; text-transform: uppercase;">Patient</td>
                                <td style="padding: 8px 0; text-align: right; color: #0f172a; font-weight: 700;">${patientName}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px 0; color: #64748b; font-size: 14px; font-weight: 600; text-transform: uppercase;">Amount</td>
                                <td style="padding: 8px 0; text-align: right; color: #0ea5e9; font-weight: 800; font-size: 18px;">₦${amount.toLocaleString()}</td>
                            </tr>
                            <tr>
                                <td style="padding: 8px 0; color: #64748b; font-size: 14px; font-weight: 600; text-transform: uppercase;">Duration</td>
                                <td style="padding: 8px 0; text-align: right; color: #0f172a; font-weight: 700;">${duration} Minutes</td>
                            </tr>
                        </table>
                    </div>
                    
                    <p style="margin-bottom: 32px;">Please log in to your dashboard to verify the receipt and credit the patient's balance.</p>
                    
                    <div style="text-align: center;">
                        <a href="${process.env.NEXT_PUBLIC_SITE_URL}/doctor/dashboard" style="background-color: #0f172a; color: #ffffff; padding: 16px 32px; border-radius: 9999px; text-decoration: none; font-weight: 700; display: inline-block; box-shadow: 0 10px 15px -3px rgba(15, 23, 42, 0.1);">Verify Payment Now</a>
                    </div>
                </div>
                <div style="background-color: #f1f5f9; padding: 24px; text-align: center; color: #94a3b8; font-size: 12px;">
                    <p style="margin: 0;">&copy; ${new Date().getFullYear()} Premon Care Platform. All rights reserved.</p>
                    <p style="margin: 4px 0 0 0;">Strictly Confidential - For Professional Use Only</p>
                </div>
            </div>
        `
    }),

    paymentApproval: (patientName: string, amount: number, status: string) => ({
        subject: `Payment ${status.charAt(0).toUpperCase() + status.slice(1)} - Premon Care`,
        html: `
            <div style="font-family: 'Inter', system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; background-color: #ffffff;">
                <div style="background: linear-gradient(135deg, #0ea5e9 0%, #2563eb 100%); padding: 32px; text-align: center; color: #ffffff;">
                    <h1 style="margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.025em;">Premon<span style="color: #ffffff; opacity: 0.8;">Care</span></h1>
                </div>
                <div style="padding: 40px; color: #334155; line-height: 1.6;">
                    <h2 style="margin-top: 0; color: #0f172a; font-size: 20px; font-weight: 700;">Hello ${patientName},</h2>
                    <p style="font-size: 16px;">Your payment has been successfully ${status}.</p>
                    
                    <div style="background-color: #f0f9ff; border: 1px solid #e0f2fe; border-radius: 12px; padding: 24px; margin: 32px 0; text-align: center;">
                        <span style="color: #64748b; font-size: 14px; font-weight: 600; text-transform: uppercase; display: block; margin-bottom: 8px;">Approved Amount</span>
                        <span style="color: #0369a1; font-weight: 800; font-size: 32px;">₦${amount.toLocaleString()}</span>
                    </div>
                    
                    <p style="margin-bottom: 32px;">Your session credits have been updated. You can now proceed to book or attend your scheduled consultation.</p>
                    
                    <div style="text-align: center;">
                        <a href="${process.env.NEXT_PUBLIC_SITE_URL}/patient/dashboard" style="background-color: #0ea5e9; color: #ffffff; padding: 16px 32px; border-radius: 9999px; text-decoration: none; font-weight: 700; display: inline-block; shadow: 0 10px 15px -3px rgba(14, 165, 233, 0.1);">Go to Dashboard</a>
                    </div>
                </div>
                <div style="background-color: #f8fafc; padding: 24px; text-align: center; color: #94a3b8; font-size: 12px;">
                    <p style="margin: 0;">&copy; ${new Date().getFullYear()} Premon Care Platform. All rights reserved.</p>
                </div>
            </div>
        `
    }),

    accountActivation: (doctorName: string, expiryDate: string) => ({
        subject: 'Professional Dashboard Activated - Welcome!',
        html: `
            <div style="font-family: 'Inter', system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; background-color: #ffffff;">
                <div style="background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); padding: 32px; text-align: center; color: #ffffff;">
                    <h1 style="margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.025em;">Premon<span style="color: #0ea5e9;">Care</span></h1>
                </div>
                <div style="padding: 40px; color: #334155; line-height: 1.6;">
                    <h2 style="margin-top: 0; color: #0f172a; font-size: 20px; font-weight: 700;">Welcome, Dr. ${doctorName},</h2>
                    <p style="font-size: 16px;">We are excited to inform you that your professional dashboard has been fully activated.</p>
                    
                    <div style="background-color: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding: 24px; margin: 32px 0;">
                        <p style="margin: 0; color: #64748b; font-size: 14px; font-weight: 600; text-transform: uppercase; text-align: center; margin-bottom: 8px;">Subscription Status</p>
                        <p style="margin: 0; text-align: center; color: #10b981; font-weight: 800; font-size: 24px;">ACTIVE</p>
                        <p style="margin: 16px 0 0 0; text-align: center; color: #64748b; font-size: 14px;">Valid until: <span style="color: #0f172a; font-weight: 700;">${expiryDate}</span></p>
                    </div>
                    
                    <p style="margin-bottom: 32px;">You can now set your schedule, view patient records, and start conducting virtual consultations.</p>
                    
                    <div style="text-align: center;">
                        <a href="${process.env.NEXT_PUBLIC_SITE_URL}/doctor/dashboard" style="background-color: #0f172a; color: #ffffff; padding: 16px 32px; border-radius: 9999px; text-decoration: none; font-weight: 700; display: inline-block;">Open Practitoner Portal</a>
                    </div>
                </div>
                <div style="background-color: #f1f5f9; padding: 24px; text-align: center; color: #94a3b8; font-size: 12px;">
                    <p style="margin: 0;">&copy; ${new Date().getFullYear()} Premon Care Platform. All rights reserved.</p>
                    <p style="margin: 4px 0 0 0;">Dedicated to Premium Care.</p>
                </div>
            </div>
        `
    }),
    doctorAppointment: (doctorName: string, patientName: string, date: string, duration: number) => ({
        subject: `New Appointment Request - ${patientName}`,
        html: `
            <div style="font-family: 'Inter', system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; background-color: #ffffff;">
                <div style="background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); padding: 32px; text-align: center; color: #ffffff;">
                    <h1 style="margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.025em;">Premon<span style="color: #0ea5e9;">Care</span></h1>
                </div>
                <div style="padding: 40px; color: #334155; line-height: 1.6;">
                    <h2 style="margin-top: 0; color: #0f172a; font-size: 20px; font-weight: 700;">Hello Dr. ${doctorName},</h2>
                    <p style="font-size: 16px;">A patient has requested a new consultation session.</p>
                    
                    <div style="background-color: #f1f5f9; border-radius: 12px; padding: 24px; margin: 32px 0;">
                        <p style="margin: 0 0 8px 0; color: #64748b; font-size: 12px; font-weight: 600; text-transform: uppercase;">Appointment Details</p>
                        <p style="margin: 0; color: #0f172a; font-weight: 700; font-size: 18px;">${patientName}</p>
                        <p style="margin: 8px 0 0 0; color: #334155;">Date: ${date}</p>
                        <p style="margin: 4px 0 0 0; color: #334155;">Duration: ${duration} Minutes</p>
                    </div>
                    
                    <p style="margin-bottom: 32px;">Please log in to review the request and confirm your availability.</p>
                    
                    <div style="text-align: center;">
                        <a href="${process.env.NEXT_PUBLIC_SITE_URL}/doctor/appointments" style="background-color: #0f172a; color: #ffffff; padding: 16px 32px; border-radius: 9999px; text-decoration: none; font-weight: 700; display: inline-block;">View Appointment Request</a>
                    </div>
                </div>
                <div style="background-color: #f1f5f9; padding: 24px; text-align: center; color: #94a3b8; font-size: 12px;">
                    <p style="margin: 0;">&copy; ${new Date().getFullYear()} Premon Care Platform. All rights reserved.</p>
                </div>
            </div>
        `
    }),
    doctorActivation: (adminName: string, doctorName: string, expiryDate: string) => ({
        subject: `Practioner Activation Alert: Dr. ${doctorName}`,
        html: `
            <div style="font-family: 'Inter', system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; background-color: #ffffff;">
                <div style="background-color: #0f172a; padding: 24px; text-align: center; color: #ffffff; border-bottom: 4px solid #0ea5e9;">
                    <h2 style="margin: 0; font-size: 20px; font-weight: 800;">ADMIN ALERT</h2>
                </div>
                <div style="padding: 32px; color: #334155; line-height: 1.6;">
                    <p>Hello ${adminName},</p>
                    <p>A new practitioner has successfully activated their professional dashboard.</p>
                    
                    <div style="background-color: #fff7ed; border: 1px solid #ffedd5; border-radius: 12px; padding: 20px; margin: 24px 0;">
                        <table style="width: 100%;">
                            <tr>
                                <td style="color: #9a3412; font-size: 12px; font-weight: 700; text-transform: uppercase; width: 40%;">Practitioner</td>
                                <td style="color: #0f172a; font-weight: 700;">Dr. ${doctorName}</td>
                            </tr>
                            <tr>
                                <td style="color: #9a3412; font-size: 12px; font-weight: 700; text-transform: uppercase;">Expiry Date</td>
                                <td style="color: #0f172a; font-weight: 700;">${expiryDate}</td>
                            </tr>
                        </table>
                    </div>
                    
                    <div style="text-align: center; margin-top: 32px;">
                        <a href="${process.env.NEXT_PUBLIC_SITE_URL}/admin/doctors" style="background-color: #0f172a; color: #ffffff; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 700; font-size: 14px;">Review Practitioners</a>
                    </div>
                </div>
                <div style="background-color: #f8fafc; padding: 16px; text-align: center; color: #94a3b8; font-size: 11px;">
                    <p style="margin: 0;">This is an automated system notification.</p>
                </div>
            </div>
        `
    }),
    bookingInstructions: (patientName: string, doctorName: string, amount: number, instructions: string) => ({
        subject: `Payment Instructions for your Appointment - Dr. ${doctorName}`,
        html: `
            <div style="font-family: 'Inter', system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; background-color: #ffffff;">
                <div style="background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); padding: 32px; text-align: center; color: #ffffff;">
                    <h1 style="margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.025em;">Premon<span style="color: #0ea5e9;">Care</span></h1>
                </div>
                <div style="padding: 40px; color: #334155; line-height: 1.6;">
                    <h2 style="margin-top: 0; color: #0f172a; font-size: 20px; font-weight: 700;">Hello ${patientName},</h2>
                    <p style="font-size: 16px;">Your appointment request has been received. To confirm your session with <strong>Dr. ${doctorName}</strong>, please complete the manual payment as described below.</p>
                    
                    <div style="background-color: #fffbeb; border: 1px solid #fef3c7; border-radius: 12px; padding: 24px; margin: 32px 0;">
                        <h3 style="margin-top: 0; color: #92400e; font-size: 14px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em;">Payment Instructions</h3>
                        <div style="background-color: #ffffff; border: 1px solid #fde68a; border-radius: 8px; padding: 16px; margin: 16px 0; font-family: monospace; white-space: pre-wrap; color: #78350f;">${instructions}</div>
                        
                        <div style="border-top: 1px dashed #fde68a; padding-top: 16px; margin-top: 16px; display: flex; justify-content: space-between; align-items: center;">
                            <span style="font-weight: 700; color: #92400e;">Amount to Pay:</span>
                            <span style="font-size: 20px; font-weight: 900; color: #b45309;">₦${amount.toLocaleString()}</span>
                        </div>
                    </div>
                    
                    <p style="font-size: 14px; color: #64748b; font-style: italic;">💡 After payment, the doctor will verify the funds and confirm your appointment time. You can check the status in your dashboard.</p>
                    
                    <div style="text-align: center; margin-top: 32px;">
                        <a href="${process.env.NEXT_PUBLIC_SITE_URL}/patient/appointments" style="background-color: #0f172a; color: #ffffff; padding: 16px 32px; border-radius: 12px; text-decoration: none; font-weight: 700; display: inline-block;">View Appointment Status</a>
                    </div>
                </div>
                <div style="background-color: #f8fafc; padding: 24px; text-align: center; color: #94a3b8; font-size: 12px; border-top: 1px solid #f1f5f9;">
                    <p style="margin: 0;">&copy; ${new Date().getFullYear()} Premon Care Platform.</p>
                </div>
            </div>
        `
    })
}
