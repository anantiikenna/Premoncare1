'use client'

import { useState, useEffect, useCallback } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { toast } from 'sonner'
import { createClient } from '@/lib/supabase'
import { getUserFacingError } from '@/lib/user-facing-errors'
import { 
    Loader2, Search, MoreHorizontal, ShieldCheck, 
    UserX, ShieldAlert, RefreshCcw, Eye, 
    Filter, ArrowUpRight, TrendingUp, Users,
    Stethoscope, User, Clock, AlertCircle, Download
} from 'lucide-react'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { cn } from '@/lib/utils'
import {
    Dialog, DialogContent, DialogHeader, DialogTitle,
    DialogDescription, DialogFooter
} from '@/components/ui/dialog'

export function UserManagement() {
    const [loading, setLoading] = useState(true)
    const [users, setUsers] = useState<any[]>([])
    const [searchTerm, setSearchTerm] = useState('')
    const [selectedRole, setSelectedRole] = useState('all')
    const [accountStatusFilter, setAccountStatusFilter] = useState<string | null>(null)
    const [verificationFilter, setVerificationFilter] = useState<string | null>(null)
    const [banDialogUser, setBanDialogUser] = useState<any>(null)
    const [resetDialogUser, setResetDialogUser] = useState<any>(null)
    const [stats, setStats] = useState({
        total: 0,
        doctors: 0,
        patients: 0,
        pending: 0,
        suspended: 0
    })
    const supabase = createClient()

    const fetchUsers = useCallback(async () => {
        setLoading(true)
        try {
            let query = supabase.from('profiles').select('*')
            
            if (selectedRole !== 'all') {
                query = query.eq('role', selectedRole)
            }
            
            if (accountStatusFilter) {
                query = query.eq('account_status', accountStatusFilter)
            }
            
            if (verificationFilter) {
                query = query.eq('verification_status', verificationFilter)
            }
            
            if (searchTerm) {
                query = query.or(`full_name.ilike.%${searchTerm}%,email.ilike.%${searchTerm}%`)
            }

            const { data, error } = await query.order('created_at', { ascending: false })
            if (error) throw error
            setUsers(data || [])

            // Fetch Stats
            const { data: allUsers } = await supabase.from('profiles').select('role, account_status, verification_status')
            if (allUsers) {
                setStats({
                    total: allUsers.length,
                    doctors: allUsers.filter(u => u.role === 'doctor').length,
                    patients: allUsers.filter(u => u.role === 'patient').length,
                    pending: allUsers.filter(u => u.verification_status === 'pending').length,
                    suspended: allUsers.filter(u => u.account_status === 'suspended').length
                })
            }
        } catch (error: unknown) {
            console.error('User list fetch failed', error)
            toast.error(getUserFacingError(error, 'We could not load users right now. Please try again.'))
        } finally {
            setLoading(false)
        }
    }, [supabase, selectedRole, searchTerm, accountStatusFilter, verificationFilter])

    useEffect(() => {
        fetchUsers()
    }, [fetchUsers])

    const handleUpdateStatus = async (userId: string, status: string) => {
        try {
            const { error } = await supabase
                .from('profiles')
                .update({ account_status: status })
                .eq('id', userId)
            
            if (error) throw error
            toast.success(`User account is now ${status}`)
            fetchUsers()
        } catch (error: unknown) {
            console.error('Account status update failed', error)
            toast.error(getUserFacingError(error, 'We could not update this account. Please try again.'))
        }
    }

    const handleResetVerification = async (userId: string) => {
        try {
            const { error } = await supabase
                .from('profiles')
                .update({ 
                    verification_status: 'unsubmitted',
                    verified_by: null 
                })
                .eq('id', userId)
            
            if (error) throw error
            toast.success('Verification state reset successfully')
            fetchUsers()
        } catch (error: unknown) {
            console.error('Verification reset failed', error)
            toast.error(getUserFacingError(error, 'We could not reset this verification state. Please try again.'))
        }
    }

    return (
        <div className="space-y-8">
            {/* Stats Overview */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
                <StatCard label="Total Users" value={stats.total} icon={Users} color="text-blue-600" bg="bg-blue-50" />
                <StatCard label="Doctors" value={stats.doctors} icon={Stethoscope} color="text-emerald-600" bg="bg-emerald-50" />
                <StatCard label="Patients" value={stats.patients} icon={User} color="text-violet-600" bg="bg-violet-50" />
                <StatCard label="Pending" value={stats.pending} icon={Clock} color="text-amber-600" bg="bg-amber-50" />
                <StatCard label="Suspended" value={stats.suspended} icon={AlertCircle} color="text-rose-600" bg="bg-rose-50" />
            </div>

            {/* Filters & Search */}
            <div className="flex flex-col md:flex-row gap-4 items-center justify-between bg-white p-4 rounded-[2rem] border shadow-sm">
                <Tabs defaultValue="all" onValueChange={setSelectedRole} className="w-full md:w-auto">
                    <TabsList className="bg-slate-50 p-1 rounded-xl h-12">
                        <TabsTrigger value="all" className="rounded-lg px-6 font-bold data-[state=active]:bg-white data-[state=active]:shadow-sm">All</TabsTrigger>
                        <TabsTrigger value="doctor" className="rounded-lg px-6 font-bold data-[state=active]:bg-white data-[state=active]:shadow-sm">Doctors</TabsTrigger>
                        <TabsTrigger value="patient" className="rounded-lg px-6 font-bold data-[state=active]:bg-white data-[state=active]:shadow-sm">Patients</TabsTrigger>
                        <TabsTrigger value="admin" className="rounded-lg px-6 font-bold data-[state=active]:bg-white data-[state=active]:shadow-sm">Admins</TabsTrigger>
                    </TabsList>
                </Tabs>

                <div className="flex items-center gap-3 w-full md:w-auto">
                    <div className="relative flex-1 md:w-80">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
                        <Input 
                            placeholder="Search by name, email or ID..." 
                            className="pl-10 h-12 rounded-xl bg-slate-50 border-none focus-visible:ring-primary"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                    <Button
                        variant="outline"
                        className={`h-12 rounded-xl px-4 border-slate-200 ${accountStatusFilter || verificationFilter ? 'bg-primary/5 border-primary/20 text-primary' : ''}`}
                        onClick={() => {
                            if (accountStatusFilter || verificationFilter) {
                                setAccountStatusFilter(null)
                                setVerificationFilter(null)
                                toast.success('Filters cleared')
                            } else {
                                setAccountStatusFilter('suspended')
                                toast.info('Showing suspended accounts. Click again to clear.')
                            }
                        }}
                    >
                        <Filter className="h-4 w-4 mr-2" />
                        Filters
                        {(accountStatusFilter || verificationFilter) && (
                            <span className="ml-2 h-5 w-5 rounded-full bg-primary text-white text-[10px] font-black flex items-center justify-center">1</span>
                        )}
                    </Button>
                </div>
            </div>

            {/* User List */}
            <div className="bg-white rounded-[2.5rem] border shadow-sm overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="border-b bg-slate-50/50">
                                <th className="p-6 text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">User Information</th>
                                <th className="p-6 text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">Role</th>
                                <th className="p-6 text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">Status</th>
                                <th className="p-6 text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">Activity</th>
                                <th className="p-6 text-[10px] font-black uppercase tracking-[0.2em] text-slate-400 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y">
                            {loading ? (
                                <tr>
                                    <td colSpan={5} className="p-20 text-center">
                                        <Loader2 className="h-8 w-8 animate-spin text-primary mx-auto" />
                                        <p className="mt-4 text-muted-foreground font-medium">Loading user database...</p>
                                    </td>
                                </tr>
                            ) : users.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="p-20 text-center">
                                        <div className="bg-slate-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-4">
                                            <Search className="h-8 w-8 text-slate-300" />
                                        </div>
                                        <p className="text-slate-500 font-bold">No users found matching your criteria.</p>
                                    </td>
                                </tr>
                            ) : (
                                users.map((user) => (
                                    <tr key={user.id} className="hover:bg-slate-50/50 transition-colors group">
                                        <td className="p-6">
                                            <div className="flex items-center gap-4">
                                                <Avatar className="h-12 w-12 border-2 border-white shadow-sm ring-1 ring-slate-100">
                                                    <AvatarImage src={user.avatar_url} />
                                                    <AvatarFallback className="bg-primary/5 text-primary font-black uppercase">
                                                        {user.full_name?.charAt(0)}
                                                    </AvatarFallback>
                                                </Avatar>
                                                <div className="flex flex-col">
                                                    <span className="font-black text-slate-900 tracking-tight group-hover:text-primary transition-colors">{user.full_name}</span>
                                                    <span className="text-xs text-slate-500 font-medium">{user.email}</span>
                                                    <span className="text-[10px] text-slate-400 font-bold uppercase mt-1">ID: {user.id.substring(0, 8)}</span>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="p-6">
                                            <Badge variant="secondary" className={cn(
                                                "rounded-lg px-3 py-1 font-black text-[10px] uppercase tracking-wider",
                                                user.role === 'admin' ? "bg-amber-100 text-amber-700" :
                                                user.role === 'doctor' ? "bg-emerald-100 text-emerald-700" :
                                                "bg-slate-100 text-slate-700"
                                            )}>
                                                {user.role}
                                            </Badge>
                                        </td>
                                        <td className="p-6">
                                            <Badge variant="outline" className={cn(
                                                "rounded-full px-3 py-1 font-black text-[10px] uppercase tracking-widest border-2",
                                                user.account_status === 'suspended' ? "border-rose-200 text-rose-600 bg-rose-50" :
                                                "border-emerald-200 text-emerald-600 bg-emerald-50"
                                            )}>
                                                {user.account_status || 'active'}
                                            </Badge>
                                        </td>
                                        <td className="p-6">
                                            <div className="flex flex-col gap-1">
                                                <span className="text-xs font-bold text-slate-600">Joined: {new Date(user.created_at).toLocaleDateString()}</span>
                                                {user.last_seen && (
                                                    <span className="text-[10px] font-medium text-slate-400">Last active: {new Date(user.last_seen).toLocaleDateString()}</span>
                                                )}
                                            </div>
                                        </td>
                                        <td className="p-6 text-right">
                                            <DropdownMenu>
                                                <DropdownMenuTrigger asChild>
                                                    <Button variant="ghost" className="h-10 w-10 p-0 rounded-xl hover:bg-slate-200">
                                                        <MoreHorizontal className="h-5 w-5 text-slate-500" />
                                                    </Button>
                                                </DropdownMenuTrigger>
                                                <DropdownMenuContent align="end" className="w-56 rounded-2xl p-2 border-none shadow-2xl ring-1 ring-black/5">
                                                    <DropdownMenuLabel className="text-[10px] font-black uppercase text-slate-400 px-3 py-2">Moderation Tools</DropdownMenuLabel>
                                                    <DropdownMenuItem 
                                                        className="rounded-xl px-3 py-2.5 text-sm font-bold gap-3"
                                                        onClick={() => handleUpdateStatus(user.id, user.account_status === 'suspended' ? 'active' : 'suspended')}
                                                    >
                                                        <ShieldAlert className={cn("h-4 w-4", user.account_status === 'suspended' ? "text-emerald-500" : "text-amber-500")} />
                                                        {user.account_status === 'suspended' ? 'Activate Account' : 'Suspend Account'}
                                                    </DropdownMenuItem>
                                                    <DropdownMenuItem 
                                                        className="rounded-xl px-3 py-2.5 text-sm font-bold gap-3 text-rose-600 focus:text-rose-700 focus:bg-rose-50"
                                                        onClick={() => setBanDialogUser(user)}
                                                    >
                                                        <UserX className="h-4 w-4" />
                                                        Ban Permanently
                                                    </DropdownMenuItem>
                                                    <DropdownMenuSeparator className="my-1 bg-slate-100" />
                                                    <DropdownMenuLabel className="text-[10px] font-black uppercase text-slate-400 px-3 py-2">System Actions</DropdownMenuLabel>
                                                    <DropdownMenuItem
                                                        className="rounded-xl px-3 py-2.5 text-sm font-bold gap-3"
                                                        onClick={() => toast.info(`View ${user.full_name}'s profile via the user detail drawer`)}
                                                    >
                                                        <RefreshCcw className="h-4 w-4 text-primary" />
                                                        Edit Profile Info
                                                    </DropdownMenuItem>
                                                    <DropdownMenuItem 
                                                        className="rounded-xl px-3 py-2.5 text-sm font-bold gap-3"
                                                        onClick={() => setResetDialogUser(user)}
                                                    >
                                                        <ShieldCheck className="h-4 w-4 text-emerald-500" />
                                                        Reset Verification
                                                    </DropdownMenuItem>
                                                    <DropdownMenuItem
                                                        className="rounded-xl px-3 py-2.5 text-sm font-bold gap-3 text-primary"
                                                        onClick={() => toast.info('Account impersonation is restricted to senior administrators and is under development.')}
                                                    >
                                                        <Eye className="h-4 w-4" />
                                                        Impersonate View
                                                    </DropdownMenuItem>
                                                </DropdownMenuContent>
                                            </DropdownMenu>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Ban Confirmation Dialog */}
            <Dialog open={!!banDialogUser} onOpenChange={(open) => { if (!open) setBanDialogUser(null) }}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle className="text-rose-600">Ban User Permanently</DialogTitle>
                        <DialogDescription>
                            Are you sure you want to permanently ban <strong>{banDialogUser?.full_name}</strong>? This action will immediately suspend their account and prevent all future access. You can reverse this later from the user management panel.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setBanDialogUser(null)}>Cancel</Button>
                        <Button
                            variant="destructive"
                            onClick={() => {
                                if (banDialogUser) {
                                    handleUpdateStatus(banDialogUser.id, 'banned')
                                    setBanDialogUser(null)
                                }
                            }}
                        >
                            <UserX className="h-4 w-4 mr-2" />
                            Ban Permanently
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>

            {/* Reset Verification Dialog */}
            <Dialog open={!!resetDialogUser} onOpenChange={(open) => { if (!open) setResetDialogUser(null) }}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Reset Verification Status</DialogTitle>
                        <DialogDescription>
                            Are you sure you want to reset <strong>{resetDialogUser?.full_name}</strong>&apos;s verification status? This will revert their verification to &quot;unsubmitted&quot; and they will need to go through the verification wizard again.
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setResetDialogUser(null)}>Cancel</Button>
                        <Button
                            variant="destructive"
                            onClick={() => {
                                if (resetDialogUser) {
                                    handleResetVerification(resetDialogUser.id)
                                    setResetDialogUser(null)
                                }
                            }}
                        >
                            <ShieldCheck className="h-4 w-4 mr-2" />
                            Reset Verification
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    )
}

function StatCard({ label, value, icon: Icon, color, bg }: { label: string, value: number, icon: any, color: string, bg: string }) {
    return (
        <div className="bg-white p-6 rounded-[2rem] border shadow-sm group hover:shadow-xl transition-all duration-500">
            <div className="flex justify-between items-start">
                <div className={cn("p-3 rounded-2xl transition-transform group-hover:scale-110", bg)}>
                    <Icon className={cn("h-6 w-6", color)} />
                </div>
            </div>
            <div className="mt-4">
                <p className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">{label}</p>
                <h3 className="text-3xl font-black text-slate-900 mt-1">{value.toLocaleString()}</h3>
            </div>
        </div>
    )
}

