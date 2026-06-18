import { NextResponse, type NextRequest } from 'next/server'
import { withSecurity } from '@/lib/security'

export const dynamic = 'force-dynamic'

// Paystack — DISABLED
// Client requires P2P manual receipt verification.
// This webhook endpoint is intentionally non-functional until Paystack is re-enabled.

async function paystackWebhookHandler(_request: NextRequest) {
  return NextResponse.json(
    { error: 'Paystack is not enabled. Manual receipt verification is active.' },
    { status: 501 }
  )
}

export async function POST(req: NextRequest) {
    return withSecurity(req, paystackWebhookHandler, { isWebhook: true, requireAuth: false })
}

export async function OPTIONS(req: NextRequest) {
    return withSecurity(req, async () => NextResponse.json({}), { isWebhook: true, requireAuth: false })
}
