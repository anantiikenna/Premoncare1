import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { LifeBuoy, Mail, MessageSquare, ShieldAlert } from 'lucide-react'

export default function SupportPage() {
  return (
    <main className="min-h-screen bg-slate-50 px-6 py-16">
      <div className="mx-auto max-w-4xl space-y-8">
        <div className="space-y-3">
          <div className="inline-flex items-center gap-2 rounded-full bg-primary/10 px-4 py-2 text-[10px] font-black uppercase tracking-widest text-primary">
            <LifeBuoy className="h-4 w-4" />
            Premon Care Support
          </div>
          <h1 className="text-4xl font-black tracking-tight text-slate-900">How can we help?</h1>
          <p className="max-w-2xl text-sm font-medium leading-6 text-slate-600">
            Reach the care operations team for account access, booking, payment, verification, or emergency workflow help.
          </p>
        </div>

        <div className="grid gap-5 md:grid-cols-3">
          {[
            {
              title: 'Account Help',
              description: 'Login, email OTP, registration, and profile access.',
              icon: MessageSquare,
            },
            {
              title: 'Payment Review',
              description: 'P2P receipts, booking fees, and disputed payments.',
              icon: Mail,
            },
            {
              title: 'Emergency Care',
              description: 'Immediate booking support and urgent care routing.',
              icon: ShieldAlert,
            },
          ].map((item) => (
            <Card key={item.title} className="rounded-3xl border-slate-100 shadow-sm">
              <CardHeader>
                <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10 text-primary">
                  <item.icon className="h-6 w-6" />
                </div>
                <CardTitle className="text-lg font-black">{item.title}</CardTitle>
                <CardDescription className="font-medium leading-6">{item.description}</CardDescription>
              </CardHeader>
            </Card>
          ))}
        </div>

        <Card className="rounded-3xl border-slate-100 shadow-sm">
          <CardContent className="flex flex-col gap-5 p-6 md:flex-row md:items-center md:justify-between">
            <div>
              <p className="text-sm font-black text-slate-900">Primary support channel</p>
              <a href="mailto:support@premoncare.com" className="text-sm font-bold text-primary">
                support@premoncare.com
              </a>
            </div>
            <div className="flex flex-col gap-3 sm:flex-row">
              <Button asChild className="rounded-2xl font-black">
                <a href="mailto:support@premoncare.com">Email Support</a>
              </Button>
              <Button asChild variant="outline" className="rounded-2xl font-black">
                <Link href="/">Return Home</Link>
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </main>
  )
}
