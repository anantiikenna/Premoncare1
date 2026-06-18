import { NextResponse, type NextRequest } from 'next/server'
import { withSecurity } from '@/lib/security'

export const dynamic = 'force-dynamic'

// Dodo Payments — DISABLED
// Client requires P2P manual receipt verification.
// This webhook endpoint is intentionally non-functional until Dodo is re-enabled.

async function webhookHandler(_request: NextRequest) {
  return NextResponse.json(
    { error: 'Dodo Payments is not enabled. Manual receipt verification is active.' },
    { status: 501 }
  )
}

export async function POST(req: NextRequest) {
    return withSecurity(req, webhookHandler, { requireAuth: false, isWebhook: true })
}
export async function OPTIONS(req: NextRequest) {
    return withSecurity(req, async () => NextResponse.json({}), { requireAuth: false, isWebhook: true })
}

