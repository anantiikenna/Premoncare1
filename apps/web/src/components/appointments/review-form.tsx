'use client'

import { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Star, Loader2 } from 'lucide-react'
import { submitReview } from '@/lib/queries-client'
import { toast } from 'sonner'

interface ReviewFormProps {
    appointmentId: string
    patientId: string
    doctorId: string
    doctorName: string
    onSuccess: () => void
    onCancel: () => void
}

export function ReviewForm({ appointmentId, patientId, doctorId, doctorName, onSuccess, onCancel }: ReviewFormProps) {
    const [rating, setRating] = useState(0)
    const [hoverRating, setHoverRating] = useState(0)
    const [comment, setComment] = useState('')
    const [isSubmitting, setIsSubmitting] = useState(false)

    const handleSubmit = async () => {
        if (rating === 0) {
            toast.error('Please select a rating')
            return
        }

        setIsSubmitting(true)
        try {
            const { error } = await submitReview({
                patient_id: patientId,
                doctor_id: doctorId,
                rating,
                comment: comment.trim() || undefined
            })

            if (error) throw error

            toast.success('Thank you for your feedback!')
            onSuccess()
        } catch (error: unknown) {
            toast.error('Failed to submit review: ' + (error instanceof Error ? error.message : String(error)))
        } finally {
            setIsSubmitting(false)
        }
    }

    return (
        <Card className="w-full max-w-md mx-auto">
            <CardHeader>
                <CardTitle>Rate your consultation</CardTitle>
                <CardDescription>How was your experience with Dr. {doctorName}?</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                <div className="flex justify-center gap-2">
                    {[1, 2, 3, 4, 5].map((star) => (
                        <button
                            key={star}
                            className="p-1 focus:outline-none transition-transform hover:scale-110"
                            onMouseEnter={() => setHoverRating(star)}
                            onMouseLeave={() => setHoverRating(0)}
                            onClick={() => setRating(star)}
                        >
                            <Star
                                className={`h-8 w-8 ${
                                    (hoverRating || rating) >= star
                                        ? 'fill-yellow-400 text-yellow-400'
                                        : 'text-muted-foreground'
                                }`}
                            />
                        </button>
                    ))}
                </div>

                <div className="space-y-2">
                    <label className="text-sm font-medium">Comments (optional)</label>
                    <Textarea
                        placeholder="Share more about your visit..."
                        value={comment}
                        onChange={(e) => setComment(e.target.value)}
                        className="min-h-[100px]"
                    />
                </div>
            </CardContent>
            <CardFooter className="flex justify-end gap-3">
                <Button variant="outline" onClick={onCancel}>Cancel</Button>
                <Button onClick={handleSubmit} disabled={isSubmitting || rating === 0}>
                    {isSubmitting ? (
                        <>
                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            Submitting...
                        </>
                    ) : (
                        'Submit Review'
                    )}
                </Button>
            </CardFooter>
        </Card>
    )
}
