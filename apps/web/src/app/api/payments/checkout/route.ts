import { NextResponse, type NextRequest } from 'next/server'
import { createClient } from '@/lib/supabase-server'
import { withSecurity } from '@/lib/security'
import { z } from 'zod'

export const dynamic = 'force-dynamic'

const checkoutSchema = z.object({
  amount: z.number().positive(),
  // userId is discarded from body, explicitly read from secure session
})

async function checkoutHandler(request: NextRequest, sessionUser?: any) {
    const jsonBody = await request.json()
    const parsed = checkoutSchema.safeParse(jsonBody)

    if (!parsed.success) {
      return NextResponse.json({ error: 'Invalid Request Data' }, { status: 400 })
    }

    const { amount } = parsed.data
    const userId = sessionUser.id

    const supabase = await createClient()

    // Create a payment record in 'pending' status — awaiting manual receipt verification
    const { data: payment, error: paymentError } = await supabase
      .from('payments')
      .insert({
        user_id: userId,
        amount: amount,
        method: 'manual',
        status: 'pending',
      })
      .select()
      .single()

    if (paymentError) {
        console.error('Error creating payment record', paymentError)
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
    }

    // Digital gateways (Dodo, Paystack) are DISABLED.
    // Payments are processed via P2P manual receipt upload.
    return NextResponse.json({
      paymentId: payment.id,
      message: 'Payment record created. Please upload your receipt for verification.',
    })
}

export async function POST(req: NextRequest) {
    return withSecurity(req, checkoutHandler, { requireAuth: true })
}
export async function OPTIONS(req: NextRequest) {
    return withSecurity(req, async () => NextResponse.json({}), { requireAuth: false })
}
