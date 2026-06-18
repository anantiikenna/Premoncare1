import { ForgotPasswordForm } from "@/components/auth/forgot-password-form"
import { Metadata } from "next"

export const metadata: Metadata = {
    title: "Forgot Password | Premon Care",
    description: "Recover your Premon Care account password securely.",
}

export default function ForgotPasswordPage() {
    return (
        <div className="min-h-screen flex items-center justify-center p-4 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-primary/5 via-background to-accent/5">
            <ForgotPasswordForm />
        </div>
    )
}
