'use client';
import React, { useState, useEffect, useMemo } from 'react';
import { createClient } from '@/lib/supabase';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Users, UserCheck, Calendar, DollarSign,
  TrendingUp, Download, BarChart3, RefreshCw
} from 'lucide-react';

type TimeRange = 'today' | 'week' | 'month';
type AppointmentStatus = 'pending' | 'approved' | 'completed' | 'cancelled' | 'rejected';

interface KPIData {
  totalUsers: number;
  totalDoctors: number;
  totalAppointments: number;
  totalRevenue: number;
  appointmentsByStatus: Record<string, number>;
  dailyRegistrations: { date: string; count: number }[];
  doctorActivity: {
    id: string;
    name: string;
    specialty: string;
    total: number;
    completed: number;
  }[];
}

export default function AdminReportsPage() {
  const [selectedRange, setSelectedRange] = useState<TimeRange>('month');
  const [data, setData] = useState<KPIData | null>(null);
  const [loading, setLoading] = useState(true);
  const [hoverX, setHoverX] = useState<number | null>(null);

  const supabase = useMemo(() => createClient(), []);

  const fetchData = async () => {
    setLoading(true);
    const now = new Date();
    let startDate = new Date();

    switch (selectedRange) {
      case 'today':
        startDate.setHours(0, 0, 0, 0);
        break;
      case 'week':
        startDate.setDate(now.getDate() - 7);
        break;
      case 'month':
        startDate.setMonth(now.getMonth() - 1);
        break;
    }

    const startISO = startDate.toISOString();

    // Parallel queries
    const [
      usersRes,
      doctorsRes,
      appointmentsRes,
      paymentsRes,
      registrationsRes,
      doctorActivityRes
    ] = await Promise.all([
      supabase.from('profiles').select('id', { count: 'exact', head: true }),
      supabase.from('profiles')
        .select('id', { count: 'exact', head: true })
        .eq('role', 'doctor')
        .eq('verification_status', 'approved'),
      supabase.from('appointments')
        .select('id, status, created_at, doctor_id, doctor:profiles!appointments_doctor_id_fkey(id, full_name, specialty)')
        .gte('created_at', startISO),
      supabase.from('payments')
        .select('amount')
        .eq('status', 'approved')
        .gte('created_at', startISO),
      supabase.from('profiles')
        .select('created_at')
        .gte('created_at', startISO),
      supabase.from('appointments')
        .select(`
          id, status,
          doctor:profiles!appointments_doctor_id_fkey(id, full_name, specialty)
        `)
        .gte('created_at', startISO)
    ]);

    // Process KPI data
    const totalUsers = usersRes.count || 0;
    const totalDoctors = doctorsRes.count || 0;
    const totalAppointments = appointmentsRes.data?.length || 0;
    const totalRevenue = paymentsRes.data?.reduce((sum, p) => sum + (Number(p.amount) || 0), 0) || 0;

    // Appointments by status
    const appointmentsByStatus: Record<string, number> = {};
    for (const apt of appointmentsRes.data || []) {
      appointmentsByStatus[apt.status] = (appointmentsByStatus[apt.status] || 0) + 1;
    }

    // Daily registrations (last 30 days)
    const dailyRegistrations: { date: string; count: number }[] = [];
    const regByDay: Record<string, number> = {};
    for (const reg of registrationsRes.data || []) {
      const day = reg.created_at.split('T')[0];
      regByDay[day] = (regByDay[day] || 0) + 1;
    }
    for (let i = 29; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const key = d.toISOString().split('T')[0];
      dailyRegistrations.push({ date: key, count: regByDay[key] || 0 });
    }

    // Doctor activity
    const doctorMap = new Map<string, { id: string; name: string; specialty: string; total: number; completed: number }>();
    for (const apt of doctorActivityRes.data || []) {
      const doc = Array.isArray(apt.doctor) ? apt.doctor[0] : apt.doctor;
      if (!doc?.id) continue;
      const existing = doctorMap.get(doc.id);
      if (existing) {
        existing.total++;
        if (apt.status === 'completed') existing.completed++;
      } else {
        doctorMap.set(doc.id, {
          id: doc.id,
          name: doc.full_name,
          specialty: doc.specialty || 'General',
          total: 1,
          completed: apt.status === 'completed' ? 1 : 0
        });
      }
    }
    const doctorActivity = Array.from(doctorMap.values())
      .sort((a, b) => b.total - a.total)
      .slice(0, 5);

    setData({
      totalUsers,
      totalDoctors,
      totalAppointments,
      totalRevenue,
      appointmentsByStatus,
      dailyRegistrations,
      doctorActivity
    });
    setLoading(false);
  };

  useEffect(() => {
    fetchData();
  }, [selectedRange]);

  const formatCurrency = (amount: number) => {
    if (amount >= 1_000_000) return `₦${(amount / 1_000_000).toFixed(1)}M`;
    if (amount >= 1_000) return `₦${(amount / 1_000).toFixed(1)}K`;
    return `₦${amount.toLocaleString()}`;
  };

  const exportCSV = () => {
    if (!data) return;
    const rows = [
      ['Metric', 'Value'],
      ['Total Users', data.totalUsers],
      ['Active Doctors', data.totalDoctors],
      ['Total Appointments', data.totalAppointments],
      ['Total Revenue', formatCurrency(data.totalRevenue)],
      [''],
      ['Status', 'Count'],
      ...Object.entries(data.appointmentsByStatus).map(([s, c]) => [s, c]),
      [''],
      ['Date', 'Registrations'],
      ...data.dailyRegistrations.map(d => [d.date, d.count]),
    ];
    const csv = rows.map(r => r.join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `report-${selectedRange}-${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  // Line chart helpers
  const maxDaily = Math.max(...(data?.dailyRegistrations.map(d => d.count) || [1]), 1);
  const chartWidth = 800;
  const chartHeight = 200;
  const chartPadding = 40;

  const buildLinePath = (values: number[]) => {
    if (values.length === 0) return '';
    const step = (chartWidth - chartPadding * 2) / (values.length - 1);
    return values
      .map((v, i) => {
        const x = chartPadding + i * step;
        const y = chartHeight - chartPadding - (v / maxDaily) * (chartHeight - chartPadding * 2);
        return `${i === 0 ? 'M' : 'L'} ${x} ${y}`;
      })
      .join(' ');
  };

  const registrationValues = data?.dailyRegistrations.map(d => d.count) || [];
  const linePath = buildLinePath(registrationValues);

  // Donut chart
  const statusEntries = Object.entries(data?.appointmentsByStatus || {});
  const totalStatusApts = statusEntries.reduce((sum, [, v]) => sum + v, 0) || 1;
  const statusColors: Record<string, string> = {
    completed: '#10B981',
    pending: '#F59E0B',
    approved: '#3B82F6',
    cancelled: '#EF4444',
    rejected: '#94A3B8'
  };

  let donutOffset = 0;
  const donutSegments = statusEntries.map(([status, count]) => {
    const pct = count / totalStatusApts;
    const dashArray = `${pct * 100} ${100 - pct * 100}`;
    const dashOffset = -donutOffset;
    donutOffset += pct * 100;
    return { status, count, pct, dashArray, dashOffset, color: statusColors[status] || '#CBD5E1' };
  });

  const ranges: { key: TimeRange; label: string }[] = [
    { key: 'today', label: 'Today' },
    { key: 'week', label: 'This Week' },
    { key: 'month', label: 'This Month' },
  ];

  return (
    <div className="min-h-screen bg-slate-50 p-6 md:p-12">
      <div className="max-w-6xl mx-auto space-y-8">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div>
            <h1 className="text-2xl font-black text-slate-800 tracking-tight">Reports & Insights Center</h1>
            <p className="text-sm font-semibold text-slate-500">Track performance, usage and key metrics in real-time</p>
          </div>
          <div className="flex items-center gap-3">
            <Button
              variant="outline"
              size="sm"
              onClick={fetchData}
              disabled={loading}
              className="rounded-xl"
            >
              <RefreshCw className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
              Refresh
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={exportCSV}
              className="rounded-xl"
            >
              <Download className="w-4 h-4 mr-2" />
              Export Report
            </Button>
          </div>
        </div>

        {/* Filter Chips */}
        <div className="flex flex-wrap items-center gap-2">
          {ranges.map((r) => (
            <button
              key={r.key}
              onClick={() => setSelectedRange(r.key)}
              className={`px-4 py-2 rounded-full text-sm font-bold transition-all ${
                selectedRange === r.key
                  ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/30'
                  : 'bg-white text-slate-500 border border-slate-200 hover:bg-slate-50'
              }`}
            >
              {r.label}
            </button>
          ))}
        </div>

        {/* KPI Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <KPICard
            title="Total Users"
            value={loading ? '...' : data?.totalUsers.toLocaleString() || '0'}
            icon={<Users className="w-5 h-5" />}
            color="emerald"
          />
          <KPICard
            title="Active Doctors"
            value={loading ? '...' : data?.totalDoctors.toLocaleString() || '0'}
            icon={<UserCheck className="w-5 h-5" />}
            color="blue"
          />
          <KPICard
            title="Total Appointments"
            value={loading ? '...' : data?.totalAppointments.toLocaleString() || '0'}
            icon={<Calendar className="w-5 h-5" />}
            color="violet"
          />
          <KPICard
            title="Total Revenue"
            value={loading ? '...' : formatCurrency(data?.totalRevenue || 0)}
            icon={<DollarSign className="w-5 h-5" />}
            color="amber"
          />
        </div>

        {/* Line Chart - Registrations Over Time */}
        <Card className="bg-white rounded-3xl border border-slate-200 shadow-sm">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-black text-slate-800">User Registrations (Last 30 Days)</h3>
              <Badge variant="outline" className="text-xs">
                {data?.dailyRegistrations.reduce((s, d) => s + d.count, 0) || 0} new users
              </Badge>
            </div>
            {loading ? (
              <div className="h-64 flex items-center justify-center text-slate-400">Loading...</div>
            ) : (
              <div className="relative h-64">
                <svg
                  viewBox={`0 0 ${chartWidth} ${chartHeight}`}
                  className="w-full h-full"
                  preserveAspectRatio="none"
                >
                  {/* Grid lines */}
                  {[0, 0.25, 0.5, 0.75, 1].map((pct) => {
                    const y = chartHeight - chartPadding - pct * (chartHeight - chartPadding * 2);
                    return (
                      <g key={pct}>
                        <line
                          x1={chartPadding}
                          y1={y}
                          x2={chartWidth - chartPadding}
                          y2={y}
                          stroke="#E2E8F0"
                          strokeWidth="1"
                        />
                        <text
                          x={chartPadding - 8}
                          y={y + 4}
                          textAnchor="end"
                          className="text-[10px] fill-slate-400"
                        >
                          {Math.round(pct * maxDaily)}
                        </text>
                      </g>
                    );
                  })}
                  {/* Line */}
                  {linePath && (
                    <path
                      d={linePath}
                      fill="none"
                      stroke="#3B82F6"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  )}
                  {/* X-axis labels */}
                  {registrationValues.length > 0 && (
                    <>
                      <text
                        x={chartPadding}
                        y={chartHeight - 10}
                        className="text-[10px] fill-slate-400"
                      >
                        30d ago
                      </text>
                      <text
                        x={chartWidth - chartPadding}
                        y={chartHeight - 10}
                        textAnchor="end"
                        className="text-[10px] fill-slate-400"
                      >
                        Today
                      </text>
                    </>
                  )}
                </svg>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Secondary Charts */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Donut Chart - Appointment Status */}
          <Card className="bg-white rounded-3xl border border-slate-200 shadow-sm">
            <CardContent className="p-6">
              <h3 className="text-lg font-black text-slate-800 mb-6">Appointments by Status</h3>
              {loading ? (
                <div className="h-48 flex items-center justify-center text-slate-400">Loading...</div>
              ) : (
                <div className="flex items-center gap-8">
                  <div className="relative w-40 h-40 shrink-0">
                    <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
                      {donutSegments.map((seg, i) => (
                        <circle
                          key={i}
                          cx="50"
                          cy="50"
                          r="40"
                          fill="none"
                          stroke={seg.color}
                          strokeWidth="15"
                          strokeDasharray={seg.dashArray}
                          strokeDashoffset={seg.dashOffset}
                        />
                      ))}
                    </svg>
                    <div className="absolute inset-0 flex flex-col items-center justify-center">
                      <span className="text-xl font-black text-slate-800">{totalStatusApts}</span>
                      <span className="text-[10px] font-bold text-slate-500">Total</span>
                    </div>
                  </div>
                  <div className="space-y-3 flex-1">
                    {donutSegments.map((seg) => (
                      <div key={seg.status} className="flex items-center gap-3">
                        <div
                          className="w-3 h-3 rounded-full shrink-0"
                          style={{ backgroundColor: seg.color }}
                        />
                        <div className="flex-1">
                          <p className="text-sm font-bold text-slate-800 capitalize">{seg.status}</p>
                          <p className="text-xs text-slate-500">
                            {seg.count} ({Math.round(seg.pct * 100)}%)
                          </p>
                        </div>
                      </div>
                    ))}
                    {donutSegments.length === 0 && (
                      <p className="text-sm text-slate-400">No appointments found</p>
                    )}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Top Doctors Table */}
          <Card className="bg-white rounded-3xl border border-slate-200 shadow-sm">
            <CardContent className="p-6">
              <h3 className="text-lg font-black text-slate-800 mb-6">Top Performing Doctors</h3>
              {loading ? (
                <div className="h-48 flex items-center justify-center text-slate-400">Loading...</div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left">
                    <thead>
                      <tr className="text-xs font-bold text-slate-400 border-b border-slate-100">
                        <th className="pb-3 font-bold">Doctor</th>
                        <th className="pb-3 text-center font-bold">Appointments</th>
                        <th className="pb-3 text-center font-bold">Completed</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {(data?.doctorActivity || []).map((doc) => (
                        <tr key={doc.id}>
                          <td className="py-3">
                            <p className="text-sm font-bold text-slate-800">{doc.name}</p>
                            <p className="text-xs text-slate-500">{doc.specialty}</p>
                          </td>
                          <td className="py-3 text-center text-sm font-bold text-slate-800">{doc.total}</td>
                          <td className="py-3 text-center">
                            <span className="text-sm font-bold text-slate-800">{doc.completed}</span>
                            <span className="text-xs text-emerald-500 ml-1">
                              ({doc.total > 0 ? Math.round((doc.completed / doc.total) * 100) : 0}%)
                            </span>
                          </td>
                        </tr>
                      ))}
                      {(data?.doctorActivity || []).length === 0 && (
                        <tr>
                          <td colSpan={3} className="py-8 text-center text-sm text-slate-400">
                            No doctor activity in this period
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}

function KPICard({
  title,
  value,
  icon,
  color
}: {
  title: string;
  value: string;
  icon: React.ReactNode;
  color: 'emerald' | 'blue' | 'violet' | 'amber';
}) {
  const colorMap = {
    emerald: { bg: 'bg-emerald-500/10', text: 'text-emerald-500' },
    blue: { bg: 'bg-blue-500/10', text: 'text-blue-500' },
    violet: { bg: 'bg-violet-500/10', text: 'text-violet-500' },
    amber: { bg: 'bg-amber-500/10', text: 'text-amber-500' },
  };
  const c = colorMap[color];

  return (
    <Card className="bg-white rounded-2xl border border-slate-200 shadow-sm">
      <CardContent className="p-5">
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${c.bg} ${c.text} mb-4`}>
          {icon}
        </div>
        <p className="text-xs font-bold text-slate-500 mb-1">{title}</p>
        <h3 className="text-2xl font-black text-slate-800">{value}</h3>
      </CardContent>
    </Card>
  );
}
