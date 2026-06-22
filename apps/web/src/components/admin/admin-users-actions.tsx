'use client'

import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { UserPlus, Download } from 'lucide-react'
import { createClient } from '@/lib/supabase'

export function AdminUsersActions() {
    const handleExport = async () => {
        try {
            const supabase = createClient()
            const { data, error } = await supabase
                .from('profiles')
                .select('id, full_name, email, role, account_status, verification_status, created_at')
                .order('created_at', { ascending: false })
            
            if (error) throw error
            if (!data || data.length === 0) {
                toast.info('No users to export')
                return
            }

            const headers = ['ID', 'Name', 'Email', 'Role', 'Status', 'Verification', 'Joined']
            const rows = data.map(u => [
                u.id, u.full_name || '', u.email || '', u.role || '',
                u.account_status || 'active', u.verification_status || 'unsubmitted',
                new Date(u.created_at).toISOString()
            ])
            
            const csv = [headers, ...rows].map(r => r.map(c => `"${String(c).replace(/"/g, '""')}"`).join(',')).join('\n')
            const blob = new Blob([csv], { type: 'text/csv' })
            const url = URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url
            a.download = `premoncare-users-${new Date().toISOString().split('T')[0]}.csv`
            a.click()
            URL.revokeObjectURL(url)
            
            toast.success(`Exported ${data.length} users to CSV`)
        } catch (error: any) {
            toast.error(error.message || 'Export failed')
        }
    }

    return (
        <div className="flex items-center gap-3 relative z-10">
            <Button
                variant="outline"
                className="rounded-2xl h-12 px-6 font-bold shadow-sm hover:bg-slate-50 transition-all"
                onClick={handleExport}
            >
                <Download className="h-4 w-4 mr-2" />
                Export Data
            </Button>
            <Button
                className="rounded-2xl h-12 px-6 font-black bg-primary hover:bg-primary/90 shadow-lg shadow-primary/20 transition-all hover:scale-105 active:scale-95"
                onClick={() => toast.info('Users register themselves. Direct them to premoncare.com/register')}
            >
                <UserPlus className="h-4 w-4 mr-2" />
                Invite User
            </Button>
        </div>
    )
}
