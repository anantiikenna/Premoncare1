import { LoopsClient } from 'loops';

const loopsApiKey = process.env.LOOPS_API_KEY;

// Only initialize if we have an API key, fallback for development gracefully
export const loops = loopsApiKey ? new LoopsClient(loopsApiKey) : null;

export async function sendLoopsEmail(email: string, subject: string, message: string, type?: string) {
    if (!loops) {
        console.warn(`Loops is not configured. Suppressing email to ${email}: ${subject}`);
        return { success: false, error: 'Loops API Key not configured' };
    }

    try {
        // In a real application, you would map 'type' to a specific Loops Transactional Email ID.
        // e.g. if (type === 'payment') { transactionalId = 'cli_123...' }
        // For this fallback, we send a beautifully formatted custom transactional email
        
        const response = await loops.sendTransactionalEmail({
            transactionalId: process.env.LOOPS_DEFAULT_TRANSACTIONAL_ID || '', // Replace with actual ID in production
            email: email,
            dataVariables: {
                subject: subject,
                message: message,
            }
        });
        
        return { success: true, response };
    } catch (error) {
        console.error('Error sending Loops email:', error);
        return { success: false, error };
    }
}
