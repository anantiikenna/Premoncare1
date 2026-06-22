'use client'

import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Plus, Download } from 'lucide-react'
import { createClient } from '@/lib/supabase'

export function AdminDoctorsActions() {
    const handleExport = async () => {
        try {
            const supabase = createClient()
            const { data, error } = await supabase
                .from('profiles')
                .select('id, full_name, email, specialty, verification_status, subscription_status, created_at')
                .or('role.eq.doctor,requested_role.eq.doctor')
                .order('created_at', { ascending: false })
            
            if (error) throw error
            if (!data || data.length === 0) {
                toast.info('No doctors to export')
                return
            }

            const headers = ['ID', 'Name', 'Email', 'Specialty', 'Verification', 'Subscription', 'Joined']
            const rows = data.map(d => [
                d.id, d.full_name || '', d.email || '', d.specialty || '',
                d.verification_status || 'unsubmitted', d.subscription_status || 'inactive',
                new Date(d.created_at).toISOString()
            ])
            
            const csv = [headers, ...rows].map(r => r.map(c => `"${String(c).replace(/"/g, '""')}"`).join(',')).join('\n')
            const blob = new Blob([csv], { type: 'text/csv' })
            const url = URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url
            a.download = `premoncare-doctors-${new Date().toISOString().split('T')[0]}.csv`
            a.click()
            URL.revokeObjectURL(url)
            
            toast.success(`Exported ${data.length} doctors to CSV`)
        } catch (error: any) {
            toast.error(error.message || 'Export failed')
        }
    }

    return (
        <div className="flex items-center gap-3">
            <Button
                variant="outline"
                className="rounded-full shadow-sm"
                onClick={handleExport}
            >
                <Download className="h-4 w-4 mr-2" />
                Export List
            </Button>
            <Button
                className="rounded-full shadow-lg shadow-primary/20 bg-primary hover:bg-primary/90"
                onClick={() => toast.info('Doctors register and submit credentials through the verification wizard. Direct them to premoncare.com/register')}
            >
                <Plus className="h-4 w-4 mr-2" />
                Invite Doctor
            </Button>
        </div>
    )
}
