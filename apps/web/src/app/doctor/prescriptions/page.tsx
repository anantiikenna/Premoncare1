import Link from 'next/link'
import { FileText, MessageSquare, Stethoscope } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

export default function DoctorPrescriptionsPage() {
  return (
    <div className="mx-auto max-w-5xl space-y-8 pb-12">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Prescription Tool</h1>
        <p className="text-sm font-medium text-muted-foreground">
          Create and manage clinical prescriptions from active consultations.
        </p>
      </div>

      <div className="grid gap-5 md:grid-cols-3">
        {[
          {
            title: 'Open Appointments',
            description: 'Review current and recent sessions before issuing medication.',
            icon: Stethoscope,
            href: '/doctor/appointments',
          },
          {
            title: 'Message Patients',
            description: 'Send instructions and follow-up notes through secure chat.',
            icon: MessageSquare,
            href: '/doctor/messages',
          },
          {
            title: 'Clinical Records',
            description: 'Review shared records before finalizing prescription guidance.',
            icon: FileText,
            href: '/doctor/records',
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
            <CardContent>
              <Button asChild className="w-full rounded-2xl font-black">
                <Link href={item.href}>Continue</Link>
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}
