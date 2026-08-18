'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase'
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { User, FileText, Check, X, Loader2, ExternalLink, Search, Eye, AlertTriangle, ShieldCheck } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { UserDetailDrawer } from './user-detail-drawer'
import { toast } from 'sonner'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog'

interface Profile {
    id: string
    full_name: string | null
    role: string
    requested_role: string
    updated_at: string
    verification_status: 'unsubmitted' | 'pending' | 'approved' | 'rejected'
    verification_document_url: string | null
}

export function UserTable({ profiles: initialProfiles }: { profiles: Profile[] }) {
    const [profiles, setProfiles] = useState<Profile[]>(initialProfiles)
    const [updating, setUpdating] = useState<string | null>(null)
    const [search, setSearch] = useState('')
    const [drawerUserId, setDrawerUserId] = useState<string | null>(null)
    const [drawerUserName, setDrawerUserName] = useState('')
    const [drawerUserRole, setDrawerUserRole] = useState('')
    const [drawerUserRequestedRole, setDrawerUserRequestedRole] = useState('')
    const [confirmAction, setConfirmAction] = useState<{ userId: string; userName: string; action: 'approved' | 'rejected' } | null>(null)
    const supabase = createClient()

    const handleUpdateStatus = async (userId: string, status: 'approved' | 'rejected') => {
        setUpdating(userId)
        try {
            const profile = profiles.find(p => p.id === userId)
            const updates: any = { verification_status: status }
            
            // Auto-promote if verification is approved and user has a pending role request
            if (status === 'approved' && profile && profile.requested_role !== profile.role) {
                updates.role = profile.requested_role
                toast.info(`Promoting user to ${profile.requested_role}...`)
            }

            const { error } = await supabase
                .from('profiles')
                .update(updates)
                .eq('id', userId)

            if (error) throw error

            setProfiles(profiles.map(p => p.id === userId ? { ...p, ...updates } : p))
            toast.success(`Verification ${status}${updates.role ? ' and user promoted' : ''}.`)
        } catch (err: unknown) {
            console.error(err)
            toast.error(`Failed to update status: ${err instanceof Error ? err.message : String(err)}`)
        } finally {
            setUpdating(null)
        }
    }

    const openDrawer = (profile: Profile) => {
        setDrawerUserId(profile.id)
        setDrawerUserName(profile.full_name || 'Unnamed User')
        setDrawerUserRole(profile.role)
        setDrawerUserRequestedRole(profile.requested_role)
    }

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'approved': return <Badge variant="outline" className="text-green-600 border-green-200 bg-green-50">Approved</Badge>
            case 'pending': return <Badge variant="outline" className="text-amber-600 border-amber-200 bg-amber-50 animate-pulse">Pending Review</Badge>
            case 'rejected': return <Badge variant="outline" className="text-red-600 border-red-200 bg-red-50">Rejected</Badge>
            default: return <Badge variant="outline" className="text-muted-foreground border-zinc-200">Unsubmitted</Badge>
        }
    }

    const filtered = profiles.filter(p =>
        (p.full_name || '').toLowerCase().includes(search.toLowerCase()) ||
        p.role.toLowerCase().includes(search.toLowerCase()) ||
        p.requested_role.toLowerCase().includes(search.toLowerCase())
    )

    return (
        <>
            <div className="p-4 border-b bg-muted/10">
                <div className="relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                        placeholder="Search by name, role, or requests..."
                        className="pl-9 h-10 rounded-full bg-white shadow-sm"
                        value={search}
                        onChange={e => setSearch(e.target.value)}
                    />
                </div>
            </div>
            <div className="rounded-md">
                <Table>
                    <TableHeader>
                        <TableRow className="bg-muted/50 hover:bg-muted/50">
                            <TableHead className="w-[140px] font-bold">Role & Status</TableHead>
                            <TableHead className="font-bold">User Information</TableHead>
                            <TableHead className="font-bold">Credential Review</TableHead>
                            <TableHead className="text-right font-bold">Actions</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {filtered.map((profile) => (
                            <TableRow key={profile.id} className="hover:bg-muted/20 transition-colors group">
                                <TableCell>
                                    <div className="flex flex-col gap-1.5">
                                        <Badge
                                            variant={profile.role === 'admin' ? 'destructive' : profile.role === 'doctor' ? 'default' : 'secondary'}
                                            className="capitalize font-bold w-fit"
                                        >
                                            {profile.role}
                                        </Badge>
                                        {profile.requested_role !== profile.role && profile.role === 'patient' && (
                                            <div className="flex items-center gap-1 text-[10px] font-black text-primary uppercase animate-in slide-in-from-left-1">
                                                <div className="w-1 h-1 rounded-full bg-primary" />
                                                Applying for: {profile.requested_role}
                                            </div>
                                        )}
                                    </div>
                                </TableCell>
                                <TableCell className="font-medium">
                                    <div className="flex items-center gap-3">
                                        <div className="h-10 w-10 rounded-full bg-primary/10 flex items-center justify-center border border-primary/5 transition-transform group-hover:scale-105">
                                            <User className="h-5 w-5 text-primary" />
                                        </div>
                                        <div>
                                            <p className="text-sm font-black text-slate-900 leading-none mb-1">
                                                {profile.role === 'doctor' && profile.verification_status === 'approved' ? 'Dr. ' : ''}{profile.full_name || 'Unnamed User'}
                                            </p>
                                            <p className="text-xs text-muted-foreground font-mono">ID: {profile.id.slice(0, 8)}</p>
                                        </div>
                                    </div>
                                </TableCell>
                                <TableCell>
                                    <div className="flex flex-col gap-1.5">
                                        {getStatusBadge(profile.verification_status)}
                                        {profile.verification_document_url && (
                                            <button
                                                onClick={async () => {
                                                    try {
                                                        const { data, error } = await supabase.storage
                                                            .from('patient-verifications')
                                                            .createSignedUrl(profile.verification_document_url!, 60)
                                                        if (error) throw error
                                                        if (data?.signedUrl) window.open(data.signedUrl, '_blank')
                                                    } catch (err: unknown) {
                                                        toast.error('Failed to open document: ' + (err instanceof Error ? err.message : String(err)))
                                                    }
                                                }}
                                                className="text-[10px] text-primary flex items-center gap-1 hover:underline mt-1 font-bold bg-transparent border-0 p-0 text-left cursor-pointer transition-all hover:gap-1.5"
                                            >
                                                <ExternalLink className="h-3 w-3" />
                                                Verify Credentials
                                            </button>
                                        )}
                                    </div>
                                </TableCell>
                                <TableCell className="text-right">
                                    <div className="flex justify-end gap-1">
                                        <Button
                                            size="sm"
                                            variant="outline"
                                            className="gap-1.5 text-xs"
                                            onClick={() => openDrawer(profile)}
                                        >
                                            <Eye className="h-3 w-3" /> View
                                        </Button>
                                        {profile.verification_status === 'pending' && (
                                            <>
                                                <Button
                                                    size="icon"
                                                    variant="ghost"
                                                    className="h-8 w-8 text-green-600 hover:text-green-700 hover:bg-green-50"
                                                    onClick={() => setConfirmAction({ userId: profile.id, userName: profile.full_name || 'Unnamed User', action: 'approved' })}
                                                    disabled={updating === profile.id}
                                                >
                                                    {updating === profile.id ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
                                                </Button>
                                                <Button
                                                    size="icon"
                                                    variant="ghost"
                                                    className="h-8 w-8 text-red-600 hover:text-red-700 hover:bg-red-50"
                                                    onClick={() => setConfirmAction({ userId: profile.id, userName: profile.full_name || 'Unnamed User', action: 'rejected' })}
                                                    disabled={updating === profile.id}
                                                >
                                                    <X className="h-4 w-4" />
                                                </Button>
                                            </>
                                        )}
                                    </div>
                                </TableCell>
                            </TableRow>
                        ))}
                        {filtered.length === 0 && (
                            <TableRow>
                                <TableCell colSpan={4} className="h-24 text-center text-muted-foreground">
                                    {search ? 'No users match your search.' : 'No registered users found.'}
                                </TableCell>
                            </TableRow>
                        )}
                    </TableBody>
                </Table>
            </div>

            <UserDetailDrawer
                userId={drawerUserId || ''}
                userName={drawerUserName}
                userRole={drawerUserRole}
                requestedRole={drawerUserRequestedRole}
                isOpen={!!drawerUserId}
                onClose={() => setDrawerUserId(null)}
            />

            {/* Confirmation Dialog */}
            <Dialog open={!!confirmAction} onOpenChange={() => setConfirmAction(null)}>
                <DialogContent className="sm:max-w-md rounded-2xl">
                    <DialogHeader>
                        <DialogTitle className="flex items-center gap-2">
                            {confirmAction?.action === 'approved' ? (
                                <ShieldCheck className="h-5 w-5 text-green-600" />
                            ) : (
                                <AlertTriangle className="h-5 w-5 text-red-600" />
                            )}
                            {confirmAction?.action === 'approved' ? 'Approve Verification' : 'Reject Verification'}
                        </DialogTitle>
                        <DialogDescription>
                            {confirmAction?.action === 'approved'
                                ? `Are you sure you want to approve ${confirmAction?.userName}'s verification? This will promote them to ${confirmAction?.userId ? profiles.find(p => p.id === confirmAction.userId)?.requested_role || '' : ''} role.`
                                : `Are you sure you want to reject ${confirmAction?.userName}'s verification?`}
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter className="gap-2 sm:gap-0">
                        <Button variant="outline" onClick={() => setConfirmAction(null)}>Cancel</Button>
                        <Button
                            variant={confirmAction?.action === 'approved' ? 'default' : 'destructive'}
                            className={confirmAction?.action === 'approved' ? 'bg-green-600 hover:bg-green-700' : ''}
                            disabled={updating === confirmAction?.userId}
                            onClick={async () => {
                                if (!confirmAction) return
                                await handleUpdateStatus(confirmAction.userId, confirmAction.action)
                                setConfirmAction(null)
                            }}
                        >
                            {updating === confirmAction?.userId ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
                            {confirmAction?.action === 'approved' ? 'Approve' : 'Reject'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </>
    )
}
