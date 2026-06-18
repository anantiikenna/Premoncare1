'use client'

import { format } from 'date-fns'
import { Star, MessageSquare } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'

interface Review {
    id: string
    rating: number
    comment: string | null
    created_at: string
    patient: {
        full_name: string
        avatar_url: string | null
    }
}

interface ReviewListProps {
    reviews: Review[]
}

export function ReviewList({ reviews }: ReviewListProps) {
    if (reviews.length === 0) {
        return (
            <div className="text-center py-12 border rounded-lg bg-accent/20">
                <MessageSquare className="h-12 w-12 text-muted-foreground/30 mx-auto mb-3" />
                <p className="text-muted-foreground font-medium">No reviews yet.</p>
                <p className="text-sm text-muted-foreground/70">Be the first to leave a review after your appointment.</p>
            </div>
        )
    }

    const averageRating = reviews.reduce((acc, rev) => acc + rev.rating, 0) / reviews.length

    return (
        <div className="space-y-6">
            <div className="flex items-center gap-4 p-4 border rounded-lg bg-card">
                <div className="text-4xl font-bold text-primary">{averageRating.toFixed(1)}</div>
                <div className="space-y-1">
                    <div className="flex">
                        {[1, 2, 3, 4, 5].map((star) => (
                            <Star
                                key={star}
                                className={`h-5 w-5 ${
                                    averageRating >= star ? 'fill-yellow-400 text-yellow-400' : 'text-muted-foreground/30'
                                }`}
                            />
                        ))}
                    </div>
                    <p className="text-sm text-muted-foreground font-medium">Based on {reviews.length} reviews</p>
                </div>
            </div>

            <div className="grid gap-4">
                {reviews.map((review) => (
                    <Card key={review.id} className="overflow-hidden">
                        <CardContent className="p-5">
                            <div className="flex items-start gap-4">
                                <Avatar className="h-10 w-10 border">
                                    <AvatarImage src={review.patient.avatar_url || ''} />
                                    <AvatarFallback>{review.patient.full_name?.charAt(0)}</AvatarFallback>
                                </Avatar>
                                <div className="flex-1 space-y-2">
                                    <div className="flex justify-between items-center">
                                        <h4 className="font-semibold text-sm">{review.patient.full_name}</h4>
                                        <span className="text-xs text-muted-foreground">
                                            {format(new Date(review.created_at), 'MMM d, yyyy')}
                                        </span>
                                    </div>
                                    <div className="flex">
                                        {[1, 2, 3, 4, 5].map((star) => (
                                            <Star
                                                key={star}
                                                className={`h-3 w-3 ${
                                                    review.rating >= star ? 'fill-yellow-400 text-yellow-400' : 'text-muted-foreground/30'
                                                }`}
                                            />
                                        ))}
                                    </div>
                                    {review.comment && (
                                        <p className="text-sm text-muted-foreground leading-relaxed">
                                            "{review.comment}"
                                        </p>
                                    )}
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                ))}
            </div>
        </div>
    )
}
