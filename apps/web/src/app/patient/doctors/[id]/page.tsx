import { createClient } from '@/lib/supabase-server'
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
    ChevronLeft, Star, Users, Video, MessageSquare, Verified,
    Clock, Calendar, Award, ShieldCheck, HeartPulse, GraduationCap
} from 'lucide-react'
import { Card } from '@/components/ui/card'
import { ShareProfileButton, ViewCredentialsButton, DoctorBottomBar } from './doctor-profile-actions'

export default async function DoctorProfilePage({ params }: { params: Promise<{ id: string }> }) {
    const { id } = await params
    const supabase = await createClient()

    const { data: doctor } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', id)
        .eq('role', 'doctor')
        .single()

    if (!doctor) notFound()

    const { data: reviewsData } = await supabase
        .from('reviews')
        .select('*, patient:profiles!reviews_patient_id_fkey(full_name, avatar_url)')
        .eq('doctor_id', id)
        .order('created_at', { ascending: false })
        .limit(10)

    const reviews = reviewsData || []
    const avgRating = doctor.rating || (reviews.length > 0
        ? (reviews.reduce((sum: number, r: any) => sum + r.rating, 0) / reviews.length).toFixed(1)
        : '0.0')
    const reviewCount = doctor.review_count || reviews.length

    const age = doctor.dob
        ? Math.floor((Date.now() - new Date(doctor.dob).getTime()) / (365.25 * 24 * 60 * 60 * 1000))
        : null

    const specializations = doctor.specializations_list?.length > 0
        ? doctor.specializations_list
        : [doctor.specialty || 'General Practice']

    const education = doctor.education?.length > 0
        ? doctor.education
        : []

    return (
        <div className="space-y-8 pb-32 animate-in-fade relative max-w-4xl mx-auto">

            {/* Header / Navigation */}
            <div className="flex items-center justify-between">
                <Button variant="ghost" size="icon" asChild className="rounded-xl border border-slate-200">
                    <Link href="/patient/doctors">
                        <ChevronLeft className="h-5 w-5 text-slate-700" />
                    </Link>
                </Button>
                <div className="flex items-center gap-2">
                    <h1 className="text-xl font-black text-slate-900">Doctor Public Profile</h1>
                    {doctor.verification_status === 'approved' && (
                        <Verified className="h-5 w-5 text-emerald-500" />
                    )}
                </div>
                <ShareProfileButton />
            </div>

            {/* Verification Banner */}
            {doctor.verification_status === 'approved' && (
                <div className="flex items-center gap-2">
                    <Verified className="h-4 w-4 text-emerald-500" />
                    <span className="text-xs font-bold text-emerald-600 uppercase tracking-widest">Verified Healthcare Professional</span>
                </div>
            )}

            {/* Hero Card */}
            <div className="relative overflow-hidden rounded-[3rem] bg-linear-to-br from-[#032B69] to-[#0A47A5] text-white p-8 md:p-12 shadow-2xl shadow-blue-900/20">
                <div className="absolute right-0 top-0 opacity-10">
                    <HeartPulse className="h-96 w-96 translate-x-1/4 -translate-y-1/4 text-white" />
                </div>

                <div className="relative z-10 flex flex-col md:flex-row gap-8 items-center md:items-start">
                    <div className="relative">
                        <div className="h-32 w-32 rounded-full overflow-hidden border-4 border-white shadow-xl">
                            {/* eslint-disable-next-line @next/next/no-img-element */}
                            <img
                                src={doctor.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(doctor.full_name || 'D')}&background=0F62FE&color=fff&size=300`}
                                alt={doctor.full_name || 'Doctor'}
                                className="w-full h-full object-cover"
                            />
                        </div>
                        {doctor.is_online && (
                            <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 bg-white text-emerald-600 text-[10px] font-black uppercase tracking-widest px-4 py-1.5 rounded-full shadow-lg flex items-center gap-1.5 whitespace-nowrap">
                                <span className="h-2 w-2 rounded-full bg-emerald-500" />
                                Available
                            </div>
                        )}
                    </div>

                    <div className="flex-1 text-center md:text-left space-y-4">
                        <div>
                            <div className="flex items-center justify-center md:justify-start gap-2">
                                <h2 className="text-3xl font-black">{doctor.full_name || 'Unknown Doctor'}</h2>
                                {doctor.verification_status === 'approved' && (
                                    <Verified className="h-6 w-6 text-blue-400" />
                                )}
                            </div>
                            {doctor.experience_years && (
                                <p className="text-white/80 font-medium mt-1">{doctor.experience_years}+ Years Experience</p>
                            )}
                            <p className="text-emerald-400 font-bold text-sm mt-1">{doctor.specialty || 'General Physician'}</p>
                        </div>

                        <div className="flex flex-wrap justify-center md:justify-start gap-8 pt-4">
                            {doctor.experience_years && (
                                <div className="space-y-1">
                                    <div className="flex items-center gap-2 text-white/80">
                                        <Award className="h-4 w-4" />
                                        <span className="text-xs font-bold uppercase tracking-widest">Experience</span>
                                    </div>
                                    <p className="text-xl font-black">{doctor.experience_years}+ Years</p>
                                </div>
                            )}
                            <div className="space-y-1">
                                <div className="flex items-center gap-2 text-white/80">
                                    <Star className="h-4 w-4" />
                                    <span className="text-xs font-bold uppercase tracking-widest">Rating</span>
                                </div>
                                <p className="text-xl font-black">{avgRating} <span className="text-sm font-medium text-white/60">({reviewCount})</span></p>
                            </div>
                            {doctor.consultation_counts > 0 && (
                                <div className="space-y-1">
                                    <div className="flex items-center gap-2 text-white/80">
                                        <Users className="h-4 w-4" />
                                        <span className="text-xs font-bold uppercase tracking-widest">Consultations</span>
                                    </div>
                                    <p className="text-xl font-black">{doctor.consultation_counts.toLocaleString()}+</p>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </div>

            {/* Quick Info Grid */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {[
                    { title: 'Video Consult', icon: Video, color: 'text-blue-500', bg: 'bg-blue-50', status: 'Available' },
                    { title: 'In-Person', icon: Users, color: 'text-emerald-500', bg: 'bg-emerald-50', status: 'Available' },
                    { title: 'Chat Support', icon: MessageSquare, color: 'text-purple-500', bg: 'bg-purple-50', status: 'Available' },
                    { title: 'Response Time', icon: Clock, color: 'text-orange-500', bg: 'bg-orange-50', status: '~5 min' },
                ].map((item, i) => (
                    <Card key={i} className="p-6 text-center border-slate-100 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
                        <div className={`h-12 w-12 rounded-xl mx-auto flex items-center justify-center ${item.bg} ${item.color} mb-4`}>
                            <item.icon className="h-6 w-6" />
                        </div>
                        <h4 className="font-bold text-slate-900 text-sm mb-1">{item.title}</h4>
                        <p className="text-xs font-semibold text-slate-500">{item.status}</p>
                    </Card>
                ))}
            </div>

            {/* Verified Banner */}
            {doctor.verification_status === 'approved' && (
                <div className="bg-blue-50 border border-blue-100 rounded-2xl p-6 flex items-start gap-4">
                    <div className="h-12 w-12 rounded-full bg-white flex items-center justify-center shrink-0">
                        <ShieldCheck className="h-6 w-6 text-blue-500" />
                    </div>
                    <div className="flex-1">
                        <h3 className="font-bold text-blue-900 text-sm">Verified & Trusted</h3>
                        <p className="text-xs text-blue-800/70 mt-1 mb-2 leading-relaxed">
                            This doctor&apos;s license, qualifications and identity have been verified by Premon Care.
                        </p>
                    </div>
                    <ViewCredentialsButton />
                </div>
            )}

            {/* Main Details Grid */}
            <div className="grid md:grid-cols-2 gap-12">
                <div className="space-y-8">
                    {/* About Section */}
                    <div className="space-y-4">
                        <h3 className="text-lg font-black text-slate-900">About {doctor.full_name || 'Doctor'}</h3>
                        <p className="text-slate-600 leading-relaxed text-sm">
                            {doctor.about_text || `${doctor.full_name || 'This doctor'} is a verified healthcare professional on Premon Care with${doctor.experience_years ? ` ${doctor.experience_years}+ years` : ''} of experience in ${doctor.specialty || 'general practice'}.`}
                        </p>
                    </div>

                    {/* Specializations */}
                    {specializations.length > 0 && (
                        <div className="space-y-4">
                            <h3 className="text-lg font-black text-slate-900">Specializations</h3>
                            <div className="flex flex-wrap gap-2">
                                {specializations.map((spec: string, i: number) => (
                                    <Badge key={i} variant="secondary" className="bg-emerald-50 text-emerald-600 border-none px-4 py-2 font-bold text-xs rounded-xl">
                                        <HeartPulse className="h-3 w-3 mr-2" />
                                        {spec}
                                    </Badge>
                                ))}
                            </div>
                        </div>
                    )}
                </div>

                <div className="space-y-8">
                    {/* Education Timeline */}
                    {education.length > 0 && (
                        <div className="space-y-6">
                            <h3 className="text-lg font-black text-slate-900">Education & Qualifications</h3>
                            <div className="space-y-6 relative before:absolute before:inset-0 before:ml-2.5 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-linear-to-b before:from-transparent before:via-emerald-500/20 before:to-transparent">
                                {education.map((edu: any, i: number) => (
                                    <div key={i} className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group is-active">
                                        <div className="flex items-center justify-center w-5 h-5 rounded-full border-4 border-white bg-emerald-500 text-slate-500 shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2" />
                                        <div className="w-[calc(100%-3rem)] md:w-[calc(50%-1.5rem)] p-4 rounded-2xl border border-slate-100 bg-white shadow-sm">
                                            <div className="flex items-center justify-between space-x-2 mb-1">
                                                <div className="font-bold text-slate-900 text-sm">{edu.degree}</div>
                                                {edu.years && <time className="text-[10px] font-bold text-emerald-600 uppercase tracking-widest">{edu.years}</time>}
                                            </div>
                                            {edu.school && (
                                                <div className="text-slate-500 text-xs flex items-start gap-2 mt-2">
                                                    <GraduationCap className="h-4 w-4 shrink-0" />
                                                    <span>{edu.school}</span>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Recent Reviews */}
                    {reviews.length > 0 && (
                        <div className="space-y-4">
                            <h3 className="text-lg font-black text-slate-900">Recent Reviews</h3>
                            <div className="space-y-3">
                                {reviews.slice(0, 5).map((review: any) => (
                                    <div key={review.id} className="bg-slate-50 rounded-2xl p-4 space-y-2">
                                        <div className="flex items-center justify-between">
                                            <div className="flex items-center gap-2">
                                                <span className="font-bold text-sm text-slate-900">{review.patient?.full_name || 'Patient'}</span>
                                                <div className="flex items-center gap-0.5">
                                                    {Array.from({ length: 5 }).map((_, i) => (
                                                        <Star key={i} className={`h-3 w-3 ${i < review.rating ? 'fill-amber-400 text-amber-400' : 'text-slate-200'}`} />
                                                    ))}
                                                </div>
                                            </div>
                                            <span className="text-[10px] font-bold text-slate-400">{new Date(review.created_at).toLocaleDateString()}</span>
                                        </div>
                                        {review.comment && (
                                            <p className="text-xs text-slate-600">{review.comment}</p>
                                        )}
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {/* Bottom Action Bar */}
            <DoctorBottomBar
                doctorId={id}
                videoFee={doctor.video_fee || 7500}
                inPersonFee={doctor.in_person_fee || 10000}
            />
        </div>
    )
}
