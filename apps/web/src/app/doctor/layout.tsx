import { DashboardLayout } from "@/components/layout/dashboard-layout"

export default function DoctorDashboardLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return <DashboardLayout>{children}</DashboardLayout>
}
