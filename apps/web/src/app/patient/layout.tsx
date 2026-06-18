import { DashboardLayout } from "@/components/layout/dashboard-layout"

export default function PatientDashboardLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return <DashboardLayout>{children}</DashboardLayout>
}
