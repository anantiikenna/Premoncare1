'use client'

import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase'
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Switch } from '@/components/ui/switch'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Loader2, Settings2, Save, Bell, Mail } from 'lucide-react'
import { Checkbox } from '@/components/ui/checkbox'
import { toast } from 'sonner'

export function AdminSettings() {
    const [enabled, setEnabled] = useState(false)
    const [delay, setDelay] = useState(0)
    const [paymentMethods, setPaymentMethods] = useState<'both' | 'digital' | 'manual'>('manual')
    const [manualInstructions, setManualInstructions] = useState('')
    const [loading, setLoading] = useState(true)
    const [saving, setSaving] = useState(false)
    const [adminSettings, setAdminSettings] = useState<{
        enabled: boolean,
        types: string[]
    }>({ enabled: true, types: [] })
    const [userId, setUserId] = useState<string | null>(null)
    const supabase = createClient()

    const fetchInitialData = useCallback(async () => {
        const { data: { user } } = await supabase.auth.getUser()
        if (user) setUserId(user.id)

        // 1. Global Settings
        const { data: globalData } = await supabase
            .from('system_settings')
            .select('*')
            .eq('id', 'default')
            .single()

        if (globalData) {
            setEnabled(globalData.auto_approve_enabled)
            setDelay(globalData.auto_approve_delay_minutes)
            setPaymentMethods(globalData.payment_methods_allowed || 'manual')
            setManualInstructions(globalData.manual_payment_instructions || '')
        }

        // 2. Personal Admin Settings
        if (user) {
            const { data: personalData } = await supabase
                .from('admin_notification_settings')
                .select('*')
                .eq('admin_id', user.id)
                .single()

            if (personalData) {
                setAdminSettings({
                    enabled: personalData.email_notifications_enabled,
                    types: personalData.alert_types || []
                })
            }
        }

        setLoading(false)
    }, [supabase])

    useEffect(() => {
        fetchInitialData()
    }, [fetchInitialData])

    const handleSave = async () => {
        setSaving(true)
        
        // Save Global
        const { error: globalError } = await supabase
            .from('system_settings')
            .update({
                auto_approve_enabled: enabled,
                auto_approve_delay_minutes: delay,
                payment_methods_allowed: paymentMethods,
                allow_doctor_pricing: true,
                base_consultation_fee: 0,
                manual_payment_instructions: manualInstructions
            })
            .eq('id', 'default')

        if (globalError) {
            toast.error('Failed to update platform settings: ' + globalError.message)
            setSaving(false)
            return
        }

        // Save Personal
        if (userId) {
            const { error: personalError } = await supabase
                .from('admin_notification_settings')
                .upsert({
                    admin_id: userId,
                    email_notifications_enabled: adminSettings.enabled,
                    alert_types: adminSettings.types || []
                })

            if (personalError) {
                toast.error('Failed to update notification preferences: ' + personalError.message)
            }
        }

        toast.success('Settings saved successfully')
        setSaving(false)
    }

    if (loading) {
        return (
            <Card className="shadow-sm border-primary/5">
                <CardHeader>
                    <div className="h-6 w-32 bg-muted animate-pulse rounded" />
                </CardHeader>
                <CardContent className="flex justify-center py-8">
                    <Loader2 className="h-6 w-6 animate-spin text-primary" />
                </CardContent>
            </Card>
        )
    }

    return (
        <Card className="shadow-2xl border-primary/10 overflow-hidden">
            <CardHeader className="bg-primary/5 border-b">
                <div className="flex items-center gap-3">
                    <div className="p-2 bg-primary/10 rounded-lg">
                        <Settings2 className="h-6 w-6 text-primary" />
                    </div>
                    <div>
                        <CardTitle className="text-2xl">Configuration Center</CardTitle>
                        <CardDescription>Master control for system behavior and policies.</CardDescription>
                    </div>
                </div>
            </CardHeader>
            <CardContent className="p-6 space-y-8 bg-mesh">
                <section className="space-y-4">
                    <h4 className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Verification Engine</h4>
                    <div className="flex items-center justify-between space-x-4 p-5 border rounded-2xl bg-background/50 backdrop-blur-sm shadow-sm">
                        <div className="flex-1 space-y-1">
                            <Label htmlFor="auto-approve" className="text-base font-bold">Auto-Approve Documents</Label>
                            <p className="text-sm text-muted-foreground leading-relaxed">
                                Enable instant identity verification for new users. Use with caution.
                            </p>
                        </div>
                        <Switch
                            id="auto-approve"
                            className="scale-125"
                            checked={enabled}
                            onCheckedChange={setEnabled}
                        />
                    </div>

                    {enabled && (
                        <div className="space-y-3 p-5 border rounded-2xl bg-primary/5 animate-in slide-in-from-top-2">
                            <Label htmlFor="delay" className="font-semibold">Approval Latency (Minutes)</Label>
                            <div className="flex items-center gap-4">
                                <Input
                                    id="delay"
                                    type="number"
                                    min="0"
                                    className="max-w-[120px] bg-background text-lg font-bold h-12"
                                    value={delay}
                                    onChange={(e) => setDelay(parseInt(e.target.value) || 0)}
                                />
                                <p className="text-sm text-muted-foreground italic">
                                    A slight delay is recommended for audit logging.
                                </p>
                            </div>
                        </div>
                    )}
                </section>

                <section className="space-y-4">
                    <h4 className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Financial Policies</h4>
                    <div className="space-y-6 p-5 border rounded-2xl bg-background/50 backdrop-blur-sm shadow-sm">
                        <div className="space-y-3">
                            <Label htmlFor="payment-methods" className="text-base font-bold">Gateway Strategy</Label>
                            <Select value={paymentMethods} onValueChange={(v: 'both' | 'digital' | 'manual') => setPaymentMethods(v)}>
                                <SelectTrigger id="payment-methods" className="h-12 text-base font-medium">
                                    <SelectValue placeholder="Select strategy" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="manual">Manual Processing Only (P2P Receipt)</SelectItem>
                                    <SelectItem value="both">Hybrid (Manual + Future Digital)</SelectItem>
                                    <SelectItem value="digital">Strictly Digital Payments</SelectItem>
                                </SelectContent>
                            </Select>
                            <p className="text-sm text-muted-foreground">
                                Controls the checkout experience for patient services. Currently set to manual P2P receipt verification.
                            </p>
                        </div>

                        <div className="space-y-4 pt-6 mt-4 border-t border-dashed opacity-50 bg-muted/20 p-4 rounded-xl cursor-not-allowed">
                            <div className="flex items-center justify-between">
                                <div className="space-y-0.5">
                                    <Label className="text-base font-bold">Practitioner Pricing Control</Label>
                                    <p className="text-sm text-muted-foreground italic">Always enabled: Doctors now set their own rates for consultation sessions.</p>
                                </div>
                                <Switch checked={true} disabled />
                            </div>
                        </div>

                        {(paymentMethods === 'both' || paymentMethods === 'manual') && (
                            <div className="space-y-3 pt-4 border-t border-dashed animate-in fade-in">
                                <Label htmlFor="manual-instructions" className="text-base font-bold text-primary">Billing Instructions for Practitioner Subscriptions</Label>
                                <Textarea
                                    id="manual-instructions"
                                    className="min-h-[120px] bg-muted/50 border-primary/20 focus:border-primary text-sm leading-relaxed"
                                    placeholder="Enter bank details for practitioners to pay their subscription fees..."
                                    value={manualInstructions}
                                    onChange={(e) => setManualInstructions(e.target.value)}
                                />
                                <p className="text-xs text-muted-foreground bg-primary/10 p-2 rounded-md font-medium">
                                    💡 This text will be shown to practitioners in their subscription dashboard.
                                </p>
                            </div>
                        )}
                    </div>
                </section>

                <section className="space-y-4">
                    <h4 className="text-xs font-bold uppercase tracking-wider text-muted-foreground">My Administration Alerts</h4>
                    <div className="space-y-6 p-5 border rounded-2xl bg-primary/5 backdrop-blur-sm shadow-inner relative overflow-hidden">
                        <div className="absolute top-0 right-0 p-4 opacity-10">
                            <Bell className="h-12 w-12 text-primary" />
                        </div>
                        
                        <div className="flex items-center justify-between space-x-4">
                            <div className="flex-1 space-y-1">
                                <Label className="text-base font-bold flex items-center gap-2">
                                    <Mail className="h-4 w-4 text-primary" />
                                    Email Notifications
                                </Label>
                                <p className="text-sm text-muted-foreground">Receive real-time alerts for critical platform events.</p>
                            </div>
                            <Switch 
                                checked={adminSettings.enabled} 
                                onCheckedChange={(v) => setAdminSettings({...adminSettings, enabled: v})} 
                            />
                        </div>

                        <div className="space-y-3 pt-4 border-t border-dashed">
                            <Label className="text-sm font-semibold">Subscribe to Alert Types</Label>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mt-2">
                                {[
                                    { id: 'payment_verified', label: 'Payment Verifications' },
                                    { id: 'doctor_requested', label: 'Practitioner Induction Requests' },
                                    { id: 'doctor_verified', label: 'Practitioner Activations' },
                                    { id: 'system_alert', label: 'System Health & Security' }
                                ].map((type) => (
                                    <div key={type.id} className="flex items-center space-x-2 py-1 px-2 hover:bg-background/40 rounded-lg transition-colors cursor-pointer">
                                        <Checkbox 
                                            id={type.id} 
                                            checked={adminSettings.types.includes(type.id)}
                                            onCheckedChange={(checked) => {
                                                const newTypes = checked 
                                                    ? [...adminSettings.types, type.id]
                                                    : adminSettings.types.filter(t => t !== type.id)
                                                setAdminSettings({...adminSettings, types: newTypes})
                                            }}
                                        />
                                        <label htmlFor={type.id} className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 cursor-pointer">
                                            {type.label}
                                        </label>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                </section>
            </CardContent>
            <CardFooter className="p-6 bg-muted/30 border-t">
                <Button onClick={handleSave} disabled={saving} size="lg" className="w-full gap-3 font-extrabold text-lg h-16 shadow-xl shadow-primary/20 rounded-2xl">
                    {saving ? <Loader2 className="h-6 w-6 animate-spin" /> : <Save className="h-6 w-6" />}
                    Deploy Changes
                </Button>
            </CardFooter>
        </Card>
    )
}
