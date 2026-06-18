import Link from 'next/link'
import { createClient } from '@/lib/supabase-server'
import { getDoctorsWithRatings } from '@/lib/queries-base'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Filter, MessageSquare, Search, Star, Users, Verified, Video } from 'lucide-react'

interface DoctorWithRating {
  id: string
  full_name?: string | null
  specialty?: string | null
  avatar_url?: string | null
  consultation_fee?: number | null
  experience_years?: number | null
  reviews?: { rating?: number | null }[] | null
}

export default async function DoctorSearchPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) return null

  const { data: doctors } = await getDoctorsWithRatings(supabase)
  const topDoctors = ((doctors || []) as DoctorWithRating[]).map((doc) => {
    const ratings = (doc.reviews || [])
      .map((review) => review.rating)
      .filter((rating): rating is number => typeof rating === 'number')
    const avgRating = ratings.length > 0
      ? (ratings.reduce((sum, rating) => sum + rating, 0) / ratings.length).toFixed(1)
      : null

    return { ...doc, avgRating, reviewCount: ratings.length }
  })

  return (
    <div className="space-y-12 pb-24 animate-in-fade relative overflow-hidden">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-8">
        <div className="space-y-1">
          <h1 className="text-4xl font-black tracking-tighter text-slate-900">
            Search &amp; Discover
          </h1>
          <p className="text-slate-500 font-medium">Find the right doctor for your needs</p>
        </div>
      </div>

      <div className="flex flex-col md:flex-row gap-4 bg-white p-4 rounded-[2rem] border border-slate-100 shadow-xl shadow-slate-200/40">
        <div className="flex-1 relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
          <Input
            placeholder="Search doctors, specialties, conditions..."
            className="pl-12 h-14 rounded-xl border-slate-200 bg-slate-50 focus-visible:ring-primary"
          />
        </div>
        <div className="flex gap-4">
          <Select>
            <SelectTrigger className="h-14 w-[180px] rounded-xl border-slate-200 bg-slate-50">
              <SelectValue placeholder="Specialty" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Specialties</SelectItem>
              <SelectItem value="gp">General Physician</SelectItem>
              <SelectItem value="ped">Pediatrician</SelectItem>
              <SelectItem value="cardio">Cardiologist</SelectItem>
            </SelectContent>
          </Select>
          <Button variant="outline" className="h-14 px-6 rounded-xl border-slate-200 bg-slate-50 gap-2">
            <Filter className="h-4 w-4 text-slate-500" />
            Filters
          </Button>
        </div>
      </div>

      <div className="rounded-[2.5rem] bg-indigo-50 border border-indigo-100 p-8 flex flex-col md:flex-row items-center justify-between gap-8 overflow-hidden relative">
        <div className="absolute right-0 top-0 opacity-10">
          <Verified className="h-64 w-64 translate-x-1/3 -translate-y-1/4 text-indigo-600" />
        </div>
        <div className="relative z-10 space-y-4 max-w-xl">
          <h2 className="text-3xl font-black text-indigo-950 tracking-tight">Quality care, anywhere</h2>
          <p className="text-indigo-800/80 font-medium leading-relaxed">
            Connect with verified doctors and get the care you deserve. We verify licenses, qualifications and experience to ensure you receive safe and quality care.
          </p>
        </div>
      </div>

      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h3 className="text-xl font-black tracking-tight text-slate-900">
            Verified Doctors
            <span className="ml-3 text-sm font-semibold text-slate-400">({topDoctors.length} available)</span>
          </h3>
        </div>

        {topDoctors.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 gap-4 text-center">
            <div className="h-16 w-16 rounded-full bg-slate-100 flex items-center justify-center">
              <Users className="h-8 w-8 text-slate-400" />
            </div>
            <h4 className="text-xl font-bold text-slate-700">No doctors available yet</h4>
            <p className="text-slate-500 max-w-sm">Our team is verifying doctors. Check back soon to find verified specialists.</p>
          </div>
        ) : (
          <div className="grid gap-6 lg:grid-cols-2 xl:grid-cols-3">
            {topDoctors.map((doc) => {
              const displayName = doc.full_name || 'Doctor'
              const initials = displayName
                .split(' ')
                .map((name) => name[0])
                .slice(0, 2)
                .join('')
                .toUpperCase()

              return (
                <div key={doc.id} className="group flex flex-col bg-white rounded-[2rem] border border-slate-100 p-6 hover:border-primary/20 hover:shadow-2xl hover:shadow-primary/5 transition-all overflow-hidden relative">
                  <div className="absolute right-6 top-6 flex items-center gap-2">
                    <span className="h-2 w-2 rounded-full bg-emerald-500" />
                    <span className="text-[10px] font-black uppercase tracking-widest text-emerald-600">
                      Available
                    </span>
                  </div>

                  <div className="flex items-start gap-4 mb-6">
                    <div className="relative">
                      {doc.avatar_url ? (
                        <div className="h-16 w-16 rounded-full overflow-hidden border-2 border-slate-100">
                          {/* eslint-disable-next-line @next/next/no-img-element */}
                          <img src={doc.avatar_url} alt={displayName} className="w-full h-full object-cover" />
                        </div>
                      ) : (
                        <div className="h-16 w-16 rounded-full bg-primary/10 border-2 border-slate-100 flex items-center justify-center">
                          <span className="text-primary font-black text-lg">{initials}</span>
                        </div>
                      )}
                      <div className="absolute -bottom-1 -right-1 bg-emerald-500 h-5 w-5 rounded-full border-2 border-white flex items-center justify-center">
                        <Verified className="h-3 w-3 text-white" />
                      </div>
                    </div>
                    <div className="space-y-1 pr-16">
                      <h4 className="font-black text-slate-900 text-lg">
                        {displayName.startsWith('Dr.') ? displayName : `Dr. ${displayName}`}
                      </h4>
                      <p className="text-xs font-bold text-emerald-600">{doc.specialty || 'General Practice'}</p>
                      {doc.experience_years && (
                        <p className="text-[10px] font-medium text-slate-500">{doc.experience_years}+ years experience</p>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-4 py-4 border-y border-slate-100 mb-6">
                    <div className="flex items-center gap-1.5">
                      <Star className="h-4 w-4 fill-amber-400 text-amber-400" />
                      <span className="text-xs font-bold text-slate-900">
                        {doc.avgRating ?? 'New'}
                      </span>
                      <span className="text-xs text-slate-500">
                        ({doc.reviewCount} {doc.reviewCount === 1 ? 'review' : 'reviews'})
                      </span>
                    </div>
                    {doc.consultation_fee && (
                      <>
                        <div className="w-px h-4 bg-slate-200" />
                        <div className="flex items-center gap-1.5">
                          <span className="text-xs font-bold text-primary">
                            ₦{Number(doc.consultation_fee).toLocaleString()}/hr
                          </span>
                        </div>
                      </>
                    )}
                  </div>

                  <div className="mt-auto flex items-center gap-3">
                    <div className="flex gap-2">
                      <Button variant="outline" size="icon" className="rounded-xl border-slate-200 h-12 w-12 text-primary hover:bg-primary/5" asChild>
                        <Link href="/patient/messages">
                          <Video className="h-5 w-5" />
                        </Link>
                      </Button>
                      <Button variant="outline" size="icon" className="rounded-xl border-slate-200 h-12 w-12 text-primary hover:bg-primary/5" asChild>
                        <Link href="/patient/messages">
                          <MessageSquare className="h-5 w-5" />
                        </Link>
                      </Button>
                    </div>
                    <Button className="flex-1 h-12 rounded-xl bg-primary hover:bg-primary/90 font-bold" asChild>
                      <Link href={`/patient/doctors/${doc.id}`}>
                        View Profile
                      </Link>
                    </Button>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
