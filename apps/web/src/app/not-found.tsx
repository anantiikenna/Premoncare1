import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { HeartPulse, Home } from 'lucide-react'

export default function NotFound() {
  return (
    <div className="flex h-[100dvh] w-full flex-col items-center justify-center bg-background px-4">
      <div className="flex flex-col items-center text-center space-y-6">
        <div className="bg-primary/10 p-5 rounded-full flex items-center justify-center">
            <HeartPulse className="h-12 w-12 text-primary" />
        </div>
        <div className="space-y-2">
            <h1 className="text-6xl font-black text-primary/80">404</h1>
            <h2 className="text-2xl font-bold tracking-tight">Page Not Found</h2>
            <p className="text-muted-foreground max-w-[400px]">
            We couldn&apos;t find the page you&apos;re looking for. It might have been moved, deleted, or you may have mistyped the address.
            </p>
        </div>
        <Link href="/">
          <Button size="lg" className="mt-4 gap-2">
            <Home className="h-4 w-4" /> Return Home
          </Button>
        </Link>
      </div>
    </div>
  )
}
