'use client'

import React, { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'
import { toast } from 'sonner'
import Link from 'next/link'

interface Profile {
  id: string
  full_name: string
  email?: string
  avatar_url?: string
  is_verified?: boolean
  role?: string
  created_at?: string
}

export default function SettingsPrivacyPage() {
  const router = useRouter()
  const [profile, setProfile] = useState<Profile | null>(null)
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(true)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [deleteConfirmEmail, setDeleteConfirmEmail] = useState('')

  useEffect(() => {
    const fetchProfile = async () => {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        router.push('/login')
        return
      }
      setEmail(user.email || '')
      const { data } = await supabase
        .from('profiles')
        .select('id, full_name, avatar_url, is_verified, role, created_at')
        .eq('id', user.id)
        .single()
      setProfile(data)
      setLoading(false)
    }
    fetchProfile()
  }, [router])

  const handleDeleteAccount = async () => {
    setDeleting(true)
    try {
      const res = await fetch('/api/user/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason: 'User requested account deletion' }),
      })
      const data = await res.json()
      if (!res.ok) {
        toast.error(data.error || 'Failed to delete account. Please contact support.')
      } else {
        toast.success(data.message || 'Account scheduled for deletion in 30 days.')
        router.push('/')
      }
    } catch {
      toast.error('Failed to delete account. Please contact support.')
    }
    setDeleting(false)
    setShowDeleteDialog(false)
    setDeleteConfirmEmail('')
  }

  const handleExportData = async () => {
    try {
      const res = await fetch('/api/user/export')
      if (!res.ok) {
        const body = await res.json().catch(() => null)
        if (res.status === 429) {
          toast.error(body?.error || 'You can only export once every 24 hours.')
        } else {
          toast.error('Failed to export data. Please try again.')
        }
        return
      }
      const blob = await res.blob()
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `premoncare-data-${new Date().toISOString().split('T')[0]}.json`
      a.click()
      URL.revokeObjectURL(url)
      toast.success('Data exported successfully.')
    } catch {
      toast.error('Failed to export data. Please try again.')
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-50 p-6 md:p-12 flex items-center justify-center">
        <div className="animate-spin h-8 w-8 border-4 border-primary border-t-transparent rounded-full" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-slate-50 p-6 md:p-12">
      <div className="max-w-3xl mx-auto space-y-8">

        {/* Header */}
        <div className="flex items-center gap-4 border-b border-slate-200 pb-6">
          <Link href="/dashboard" className="p-2 bg-white rounded-full border border-slate-200 hover:bg-slate-50 transition-colors">
            <svg className="w-5 h-5 text-slate-700" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
          </Link>
          <div>
            <h1 className="text-2xl font-black text-slate-800 tracking-tight">Settings & Privacy</h1>
            <p className="text-sm font-semibold text-slate-500">Manage your account and security</p>
          </div>
        </div>

        {/* Profile Card */}
        <div className="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm flex items-center gap-6">
          <div className="w-20 h-20 rounded-full bg-slate-200 overflow-hidden relative border-4 border-white shadow-lg">
            {profile?.avatar_url ? (
              <img src={profile.avatar_url} alt="Profile" className="w-full h-full object-cover" />
            ) : (
              <div className="w-full h-full flex items-center justify-center bg-primary/10 text-primary text-2xl font-black">
                {profile?.full_name?.charAt(0) || '?'}
              </div>
            )}
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-xl font-black text-slate-800">{profile?.full_name || 'User'}</h2>
              {profile?.is_verified && (
                <svg className="w-5 h-5 text-blue-500" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
              )}
            </div>
            <p className="text-sm font-semibold text-slate-500">{email}</p>
            {profile?.is_verified && (
              <div className="mt-2 inline-flex items-center gap-1.5 px-3 py-1 bg-emerald-50 rounded-lg border border-emerald-100">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                <span className="text-xs font-bold text-emerald-700">Identity Verified</span>
              </div>
            )}
          </div>
        </div>

        {/* Account Settings */}
        <div className="space-y-4">
          <h3 className="text-xs font-black text-slate-500 uppercase tracking-wider ml-2">Account Settings</h3>
          <div className="bg-white rounded-3xl border border-slate-200 overflow-hidden">
            <SettingsRow icon="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" iconColor="text-blue-500" iconBg="bg-blue-50" title="Login & Security" subtitle="Manage password and 2FA" onClick={() => toast.info('Password and two-factor authentication settings are under development. Contact support to update your credentials in the meantime.')} />
            <div className="h-px bg-slate-100 mx-6"></div>
            <SettingsRow icon="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" iconColor="text-amber-500" iconBg="bg-amber-50" title="Notification Preferences" subtitle="Push, email, and SMS alerts" onClick={() => router.push('/notifications')} />
            <div className="h-px bg-slate-100 mx-6"></div>
            <SettingsRow icon="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" iconColor="text-emerald-500" iconBg="bg-emerald-50" title="Payment Methods" subtitle="Manage cards and bank accounts" onClick={() => router.push('/patient/payments')} />
          </div>
        </div>

        {/* Privacy & Data */}
        <div className="space-y-4">
          <h3 className="text-xs font-black text-slate-500 uppercase tracking-wider ml-2">Privacy & Data</h3>
          <div className="bg-white rounded-3xl border border-slate-200 overflow-hidden">
            <SettingsRow icon="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2" iconColor="text-violet-500" iconBg="bg-violet-50" title="Medical Record Permissions" subtitle="Manage who can see your records" onClick={() => router.push('/patient/records')} />
            <div className="h-px bg-slate-100 mx-6"></div>
            <SettingsRow icon="M12 11c0 3.517-1.009 6.799-2.753 9.571m-3.44-2.04l.054-.09A13.916 13.916 0 008 11a4 4 0 118 0c0 1.017-.07 2.019-.203 3m-2.118 6.844A21.88 21.88 0 0015.171 17m3.839 1.132c.645-2.266.99-4.659.99-7.132A8 8 0 008 4.07M3 15.364c.64-1.319 1-2.8 1-4.364 0-1.457.39-2.823 1.07-4" iconColor="text-blue-500" iconBg="bg-blue-50" title="Biometric & Privacy Controls" subtitle="Face ID and app locking" onClick={() => toast.info('Biometric authentication and app lock features are coming soon. Your data is protected by Supabase Row-Level Security in the meantime.')} />
            <div className="h-px bg-slate-100 mx-6"></div>
            <SettingsRow icon="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" iconColor="text-slate-500" iconBg="bg-slate-100" title="Device Sessions & Activity" subtitle="Review active logins" onClick={() => toast.info('Active session monitoring is under development. You can revoke access by changing your password from the Login & Security section.')} />
            <div className="h-px bg-slate-100 mx-6"></div>
            <SettingsRow icon="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" iconColor="text-emerald-500" iconBg="bg-emerald-50" title="Download My Data" subtitle="Export all your data (GDPR)" onClick={handleExportData} />
          </div>
        </div>

        {/* Danger Zone */}
        <div className="space-y-4">
          <h3 className="text-xs font-black text-slate-500 uppercase tracking-wider ml-2">Danger Zone</h3>
          <div className="bg-white rounded-3xl border border-red-100 overflow-hidden">
            <button
              onClick={() => setShowDeleteDialog(true)}
              className="w-full flex items-center justify-between p-4 hover:bg-red-50 transition-colors cursor-pointer"
            >
              <div className="flex items-center gap-4">
                <div className="p-3 bg-red-50 rounded-xl text-red-500">
                  <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </div>
                <div className="text-left">
                  <p className="text-base font-black text-red-600">Delete Account</p>
                  <p className="text-xs font-semibold text-red-400">Permanently delete your data</p>
                </div>
              </div>
              <svg className="w-5 h-5 text-red-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </button>
          </div>
        </div>

      </div>

      {/* Delete Confirmation Dialog */}
      {showDeleteDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="bg-white rounded-3xl p-8 max-w-lg w-full mx-4 shadow-2xl space-y-5 max-h-[85vh] overflow-y-auto">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-red-50 rounded-full">
                <svg className="w-7 h-7 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
              <h3 className="text-xl font-black text-slate-900">Delete Account</h3>
            </div>

            <div className="bg-red-50 border border-red-100 rounded-2xl p-4">
              <p className="text-sm font-bold text-red-800 leading-relaxed">
                You are about to deactivate your account. Your profile will be hidden immediately and permanently deleted after a <span className="underline">30-day grace period</span>.
              </p>
            </div>

            <div className="space-y-1">
              <p className="text-sm font-black text-slate-800">This will deactivate:</p>
              <ul className="space-y-2 mt-2">
                <li className="flex items-start gap-3 text-sm text-slate-600">
                  <svg className="w-4 h-4 mt-0.5 text-red-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                  Your profile and personal information
                </li>
                <li className="flex items-start gap-3 text-sm text-slate-600">
                  <svg className="w-4 h-4 mt-0.5 text-red-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                  All appointments and consultation history
                </li>
                <li className="flex items-start gap-3 text-sm text-slate-600">
                  <svg className="w-4 h-4 mt-0.5 text-red-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" /></svg>
                  Medical records and uploaded documents
                </li>
                <li className="flex items-start gap-3 text-sm text-slate-600">
                  <svg className="w-4 h-4 mt-0.5 text-red-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" /></svg>
                  All messages and chat history
                </li>
                <li className="flex items-start gap-3 text-sm text-slate-600">
                  <svg className="w-4 h-4 mt-0.5 text-red-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16l3.5-2 3.5 2 3.5-2 3.5 2z" /></svg>
                  Payment records and transaction history
                </li>
                <li className="flex items-start gap-3 text-sm text-slate-600">
                  <svg className="w-4 h-4 mt-0.5 text-red-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" /></svg>
                  Reviews and ratings you&apos;ve given
                </li>
              </ul>
            </div>

            {profile?.role === 'doctor' && (
              <div className="bg-amber-50 border border-amber-200 rounded-xl p-3">
                <p className="text-xs font-bold text-amber-700">
                  ⚠ You have a doctor account. Deleting this will also remove your verification status and all patient records you&apos;ve managed.
                </p>
              </div>
            )}

            <div className="space-y-2">
              <label className="text-sm font-black text-slate-800">
                Type your email to confirm:
              </label>
              <input
                type="email"
                value={deleteConfirmEmail}
                onChange={(e) => setDeleteConfirmEmail(e.target.value)}
                placeholder={email}
                className="w-full px-4 py-3 rounded-xl border text-sm font-semibold transition-colors outline-none
                  border-slate-200 focus:border-red-400 focus:ring-2 focus:ring-red-100"
              />
              {deleteConfirmEmail && deleteConfirmEmail !== email && (
                <p className="text-xs font-semibold text-red-500">Email does not match</p>
              )}
            </div>

            <div className="flex gap-3 pt-1">
              <button
                onClick={() => { setShowDeleteDialog(false); setDeleteConfirmEmail('') }}
                className="flex-1 h-12 rounded-xl border border-slate-200 font-black text-sm text-slate-600 hover:bg-slate-50 transition-colors cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={handleDeleteAccount}
                disabled={deleting || deleteConfirmEmail !== email}
                className="flex-1 h-12 rounded-xl bg-red-600 hover:bg-red-700 text-white font-black text-sm transition-colors disabled:opacity-30 disabled:cursor-not-allowed cursor-pointer"
              >
                {deleting ? 'Deleting...' : 'Delete My Account'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function SettingsRow({ icon, iconColor, iconBg, title, subtitle, onClick }: any) {
  return (
    <button onClick={onClick} className="w-full flex items-center justify-between p-4 hover:bg-slate-50 transition-colors cursor-pointer">
      <div className="flex items-center gap-4">
        <div className={`p-3 rounded-xl ${iconBg} ${iconColor}`}>
          <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={icon} />
          </svg>
        </div>
        <div className="text-left">
          <p className="text-base font-black text-slate-800">{title}</p>
          <p className="text-xs font-semibold text-slate-500">{subtitle}</p>
        </div>
      </div>
      <svg className="w-5 h-5 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
      </svg>
    </button>
  )
}
