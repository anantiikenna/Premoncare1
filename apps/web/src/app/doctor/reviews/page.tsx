import { createClient } from '@/lib/supabase-server'
import { getProfile, getDoctorReviews } from '@/lib/queries'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Star, MessageSquare } from 'lucide-react'
import { ReviewList } from '@/components/doctor/review-list'
import { redirect } from 'next/navigation'

export default async function DoctorReviewsPage() {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) redirect('/login')

    const { data: profile } = await getProfile(user.id)
    if (profile?.role !== 'doctor') redirect('/dashboard')

    const { data: reviews } = await getDoctorReviews(user.id)
    
    const averageRating = reviews && reviews.length > 0
        ? (reviews.reduce((acc, rev) => acc + rev.rating, 0) / reviews.length).toFixed(1)
        : '0.0'

    return (
        <div className="max-w-5xl mx-auto space-y-8">
            <div className="flex flex-col gap-2">
                <h1 className="text-3xl font-bold tracking-tight">Patient Reviews</h1>
                <p className="text-muted-foreground mt-1">Monitor your patient satisfaction and feedback.</p>
            </div>

            <div className="grid gap-4 md:grid-cols-3">
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Average Rating</CardTitle>
                        <Star className="h-4 w-4 text-yellow-500 fill-yellow-500" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">{averageRating}</div>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Total Reviews</CardTitle>
                        <MessageSquare className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">{reviews?.length || 0}</div>
                    </CardContent>
                </Card>
            </div>

            <section>
                <ReviewList reviews={reviews || []} />
            </section>
        </div>
    )
}
