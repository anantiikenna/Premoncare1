import { ResetPasswordForm } from "@/components/auth/reset-password-form"
import { Metadata } from "next"

export const metadata: Metadata = {
    title: "Reset Password | Premon Care",
    description: "Update your Premon Care account password securely.",
}

export default function ResetPasswordPage() {
    return (
        <div className="min-h-screen flex items-center justify-center p-4 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-primary/5 via-background to-accent/5">
            <ResetPasswordForm />
        </div>
    )
}
