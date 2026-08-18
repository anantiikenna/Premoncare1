'use client';

import React, { useState } from 'react';
import { 
  Shield, 
  CheckCircle, 
  Video, 
  MessageSquare, 
  FileText, 
  Download, 
  CreditCard, 
  Calendar,
  ChevronRight,
  TrendingUp,
  Headphones,
  ArrowUp,
  Zap,
  Gem,
  Rocket,
  Lock,
  Pause,
  XCircle,
  Clock
} from 'lucide-react';

export default function SubscriptionPage() {
  const [isExploring, setIsExploring] = useState(false);

  return (
    <div className="min-h-screen bg-[#F8FAFC] p-6 lg:p-10">
      <div className="max-w-6xl mx-auto">
        <header className="mb-10 text-center lg:text-left flex flex-col lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h1 className="text-3xl font-black text-[#1E293B] mb-2 tracking-tight">Subscription Management</h1>
            <p className="text-[#64748B] font-medium">Manage your plan, billing and premium benefits.</p>
          </div>
          <div className="mt-6 lg:mt-0 flex gap-4 justify-center">
            <button className="p-3 rounded-xl bg-white border border-[#E2E8F0] text-[#1E293B] hover:bg-[#F1F5F9] transition-all cursor-pointer">
              <Headphones className="w-5 h-5" />
            </button>
            <button className="p-3 rounded-xl bg-white border border-[#E2E8F0] text-[#1E293B] hover:bg-[#F1F5F9] transition-all cursor-pointer">
              <Calendar className="w-5 h-5" />
            </button>
          </div>
        </header>

        {isExploring ? (
          <ExplorePlansView onBack={() => setIsExploring(false)} />
        ) : (
          <ManageSubscriptionView onUpgrade={() => setIsExploring(true)} />
        )}
      </div>
    </div>
  );
}

function ManageSubscriptionView({ onUpgrade }: { onUpgrade: () => void }) {
  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      {/* Hero Card */}
      <div className="relative overflow-hidden rounded-[2.5rem] bg-linear-to-br from-[#0F62FE] via-[#0EA5E9] to-[#22D3EE] p-8 lg:p-12 text-white shadow-2xl shadow-blue-500/30">
        <div className="relative z-10 grid lg:grid-cols-2 gap-10 items-center">
          <div className="space-y-6">
            <span className="inline-block px-4 py-1.5 bg-white/20 backdrop-blur-md rounded-full text-xs font-bold uppercase tracking-wider">
              Current Plan
            </span>
            <div className="flex items-center gap-4">
              <h2 className="text-4xl lg:text-5xl font-black">Premium Plan</h2>
              <CheckCircle className="w-8 h-8 text-[#22C55E] fill-[#22C55E]/20" />
            </div>
            <p className="text-white/80 text-lg font-medium leading-relaxed max-w-md">
              All-in-one access to premium healthcare features for high-performance practitioners.
            </p>
            <div className="space-y-1">
              <span className="text-white/60 text-sm font-semibold">Price</span>
              <div className="text-3xl font-black">₦15,000 <span className="text-xl font-medium text-white/60">/ month</span></div>
            </div>
            <div className="inline-flex items-center gap-3 px-5 py-3 bg-white/10 backdrop-blur-lg rounded-2xl border border-white/10">
              <Calendar className="w-4 h-4" />
              <span className="text-sm font-bold">Next billing date: 15 June 2025</span>
            </div>
          </div>

          <div className="hidden lg:flex justify-end">
            <div className="relative">
              <div className="absolute inset-0 bg-white/20 blur-3xl rounded-full scale-150"></div>
              <div className="relative w-64 h-64 bg-white/10 backdrop-blur-2xl rounded-full border border-white/20 flex items-center justify-center">
                <Shield className="w-32 h-32 text-white/30" />
                <span className="absolute text-6xl font-black">P</span>
              </div>
            </div>
          </div>
        </div>
        
        {/* Background Decorative Elements */}
        <div className="absolute top-0 right-0 w-96 h-96 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/3 blur-3xl"></div>
        <div className="absolute bottom-0 left-0 w-64 h-64 bg-cyan-400/20 rounded-full translate-y-1/2 -translate-x-1/4 blur-3xl"></div>
      </div>

      {/* Feature Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-6">
        {[
          { icon: Video, label: "Unlimited", sub: "Video Consults" },
          { icon: MessageSquare, label: "Priority", sub: "Support" },
          { icon: Shield, label: "Secure", sub: "Health Data" },
          { icon: Zap, label: "Exclusive", sub: "Discounts" },
        ].map((item, i) => (
          <div key={i} className="glass-panel p-6 rounded-3xl flex flex-col items-center text-center group hover:scale-105 transition-all duration-300">
            <div className="p-4 bg-[#0F62FE]/10 rounded-2xl text-[#0F62FE] mb-4 group-hover:bg-[#0F62FE] group-hover:text-white transition-colors">
              <item.icon className="w-6 h-6" />
            </div>
            <div className="font-black text-[#1E293B] text-sm">{item.label}</div>
            <div className="text-[#64748B] text-xs font-semibold">{item.sub}</div>
          </div>
        ))}
      </div>

      <div className="grid lg:grid-cols-3 gap-8">
        {/* Billing & Payment */}
        <div className="lg:col-span-2 space-y-6">
          <div className="flex items-center justify-between">
            <h3 className="text-xl font-black text-[#1E293B]">Billing & Payment</h3>
            <button className="text-[#0F62FE] text-sm font-bold flex items-center gap-1 hover:underline cursor-pointer">
              View History <ChevronRight className="w-4 h-4" />
            </button>
          </div>
          <div className="glass-panel rounded-3xl p-6 space-y-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="p-3 bg-[#F1F5F9] rounded-xl text-[#0F62FE]">
                  <FileText className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-[10px] uppercase tracking-wider font-black text-[#94A3B8]">Billing Cycle</div>
                  <div className="text-lg font-black text-[#1E293B]">Monthly</div>
                </div>
              </div>
              <div className="text-xl font-black text-[#1E293B]">₦15,000</div>
            </div>
            <div className="h-px bg-[#F1F5F9]"></div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <div className="p-3 bg-[#F1F5F9] rounded-xl text-[#0F62FE]">
                  <CreditCard className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-[10px] uppercase tracking-wider font-black text-[#94A3B8]">Payment Method</div>
                  <div className="flex items-center gap-2">
                    <span className="text-lg font-black text-[#1E293B]">•••• 4242</span>
                    <span className="px-2 py-0.5 bg-[#DCFCE7] text-[#166534] text-[10px] font-black rounded-md uppercase">Default</span>
                  </div>
                </div>
              </div>
              <ChevronRight className="w-6 h-6 text-[#94A3B8]" />
            </div>
          </div>

          {/* Manage Subscription Actions */}
          <div className="space-y-4">
             <h3 className="text-xl font-black text-[#1E293B]">Manage Subscription</h3>
             <div className="space-y-3">
                <ActionTile 
                  icon={ArrowUp} 
                  title="Upgrade Plan" 
                  sub="Get more benefits and features for your practice" 
                  color="blue"
                  onClick={onUpgrade}
                />
                <ActionTile 
                  icon={Pause} 
                  title="Pause Subscription" 
                  sub="Temporarily pause your plan and benefits" 
                  color="indigo"
                />
                <ActionTile 
                  icon={XCircle} 
                  title="Cancel Subscription" 
                  sub="Cancel your plan and stop future billing cycles" 
                  color="red"
                />
             </div>
          </div>
        </div>

        {/* Plan Usage */}
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <h3 className="text-xl font-black text-[#1E293B]">Plan Usage</h3>
            <span className="text-[10px] font-black text-[#94A3B8] uppercase">Resets 15 June</span>
          </div>
          <div className="glass-panel rounded-[2rem] p-8 space-y-8">
            <UsageCircle progress={65} icon={Video} label="Video Consults" val="12 / ∞" sub="Unlimited" />
            <UsageCircle progress={40} icon={MessageSquare} label="Chat Consults" val="28 / ∞" sub="Unlimited" />
            <UsageCircle progress={40} icon={FileText} label="Health Records" val="8 / 20" sub="40% used" />
            <UsageCircle progress={30} icon={Download} label="Reports" val="3 / 10" sub="30% used" />
          </div>
          
          <div className="p-6 rounded-3xl bg-[#F0FDF4] border border-[#DCFCE7] flex gap-4 items-center">
            <div className="p-3 bg-[#DCFCE7] rounded-full text-[#16A34A]">
               <TrendingUp className="w-6 h-6" />
            </div>
            <div>
              <div className="font-black text-[#166534]">Great progress!</div>
              <div className="text-xs font-medium text-[#166534]/80">Your usage is within limits for your current plan.</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ExplorePlansView({ onBack }: { onBack: () => void }) {
  return (
    <div className="space-y-12 animate-in fade-in slide-in-from-right-4 duration-700">
      <button onClick={onBack} className="flex items-center gap-2 text-[#0F62FE] font-black hover:translate-x-[-4px] transition-transform cursor-pointer">
        <ChevronRight className="w-5 h-5 rotate-180" /> Back to Manage
      </button>

      <div className="text-center space-y-4">
        <h2 className="text-4xl font-black text-[#1E293B]">Choose the Perfect Plan</h2>
        <p className="text-[#64748B] max-w-2xl mx-auto font-medium">Unlock advanced features and grow your clinical practice with our premium subscription tiers.</p>
      </div>

      <div className="grid lg:grid-cols-3 gap-8 pb-10">
        <PlanCard 
          name="Basic" 
          price="5,000" 
          icon={Zap} 
          perks={[
            "10 consultations / month",
            "Standard support",
            "Consultation credits (₦2,000)",
            "Family account (N/A)"
          ]}
        />
        <PlanCard 
          name="Premium" 
          price="15,000" 
          icon={Gem} 
          isPopular 
          isCurrent 
          perks={[
            "Unlimited consultations",
            "Priority support",
            "Consultation credits (₦7,500)",
            "Family account (up to 5)"
          ]}
        />
        <PlanCard 
          name="Pro" 
          price="30,000" 
          icon={Rocket} 
          perks={[
            "Unlimited consultations",
            "VIP support",
            "Consultation credits (₦20,000)",
            "Family account (up to 10)"
          ]}
        />
      </div>

      {/* Secure Footer */}
      <div className="glass-panel p-8 rounded-[2.5rem] bg-[#F0FDF4]/50 border-[#DCFCE7] flex flex-col lg:flex-row items-center gap-8 text-center lg:text-left">
        <div className="relative">
          <div className="w-20 h-20 bg-[#DCFCE7] rounded-full flex items-center justify-center">
            <Shield className="w-10 h-10 text-[#22C55E]" />
            <Lock className="absolute w-4 h-4 text-white" />
          </div>
        </div>
        <div className="flex-1">
          <h3 className="text-2xl font-black text-[#166534] mb-2">Secure & Hassle-free</h3>
          <p className="text-[#166534]/80 font-medium">Your payment information is encrypted with industry-standard protocols. Your clinical data and privacy are always our top priority.</p>
        </div>
        <div className="flex gap-4">
           <img src="https://upload.wikimedia.org/wikipedia/commons/5/5e/Visa_Inc._logo.svg" className="h-6 opacity-40" alt="Visa" />
           <img src="https://upload.wikimedia.org/wikipedia/commons/2/2a/Mastercard-logo.svg" className="h-6 opacity-40" alt="Mastercard" />
        </div>
      </div>
    </div>
  );
}

function ActionTile({ icon: Icon, title, sub, color, onClick }: any) {
  const colors: any = {
    blue: "bg-blue-50 text-blue-600 border-blue-100",
    indigo: "bg-indigo-50 text-indigo-600 border-indigo-100",
    red: "bg-red-50 text-red-600 border-red-100"
  };

  return (
    <button 
      onClick={onClick}
      className="w-full flex items-center gap-5 p-5 bg-white border border-[#F1F5F9] rounded-2xl hover:border-blue-400 hover:shadow-xl hover:shadow-blue-500/5 transition-all group text-left cursor-pointer"
    >
      <div className={`p-3 rounded-xl transition-all group-hover:scale-110 ${colors[color]}`}>
        <Icon className="w-5 h-5" />
      </div>
      <div className="flex-1">
        <div className="font-black text-[#1E293B] group-hover:text-[#0F62FE] transition-colors">{title}</div>
        <div className="text-xs font-semibold text-[#64748B]">{sub}</div>
      </div>
      <ChevronRight className="w-5 h-5 text-[#94A3B8] group-hover:text-[#0F62FE] transition-colors" />
    </button>
  );
}

function UsageCircle({ progress, icon: Icon, label, val, sub }: any) {
  return (
    <div className="flex items-center gap-6">
      <div className="relative w-16 h-16 flex items-center justify-center">
        <svg className="w-full h-full -rotate-90">
          <circle cx="32" cy="32" r="28" fill="transparent" stroke="#F1F5F9" strokeWidth="6" />
          <circle 
            cx="32" cy="32" r="28" fill="transparent" stroke="#0F62FE" strokeWidth="6" 
            strokeDasharray={`${2 * Math.PI * 28}`} 
            strokeDashoffset={`${2 * Math.PI * 28 * (1 - progress / 100)}`}
            strokeLinecap="round"
          />
        </svg>
        <Icon className="absolute w-5 h-5 text-[#0F62FE]" />
      </div>
      <div>
        <div className="text-[10px] font-black text-[#94A3B8] uppercase tracking-wider">{label}</div>
        <div className="text-lg font-black text-[#1E293B]">{val}</div>
        <div className={`text-[10px] font-black uppercase ${sub === 'Unlimited' ? 'text-[#22C55E]' : 'text-[#94A3B8]'}`}>{sub}</div>
      </div>
    </div>
  );
}

function PlanCard({ name, price, icon: Icon, perks, isPopular, isCurrent }: any) {
  return (
    <div className={`relative flex flex-col p-8 rounded-[2.5rem] bg-white border-2 transition-all hover:shadow-2xl hover:shadow-blue-500/10 ${isPopular ? 'border-[#0F62FE] scale-105 z-10' : 'border-[#F1F5F9]'}`}>
      {isPopular && (
        <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 px-4 py-1.5 bg-[#0EA5E9] text-white text-[10px] font-black uppercase tracking-widest rounded-full flex items-center gap-2 shadow-lg shadow-blue-500/20">
          <TrendingUp className="w-3 h-3" /> Most Popular
        </div>
      )}
      
      <div className="p-4 bg-[#0F62FE]/10 rounded-2xl text-[#0F62FE] w-fit mb-8">
        <Icon className="w-8 h-8" />
      </div>

      <h3 className="text-2xl font-black text-[#1E293B] mb-2">{name}</h3>
      <div className="text-2xl font-black text-[#1E293B] mb-8">
        ₦{price} <span className="text-sm font-medium text-[#64748B]">/ month</span>
      </div>

      <div className="space-y-4 mb-10 flex-1">
        {perks.map((perk: string, i: number) => (
          <div key={i} className="flex items-center gap-3">
            <CheckCircle className={`w-5 h-5 ${perk.includes('N/A') ? 'text-[#E2E8F0]' : 'text-[#22C55E] fill-[#22C55E]/10'}`} />
            <span className={`text-sm font-semibold ${perk.includes('N/A') ? 'text-[#94A3B8]' : 'text-[#64748B]'}`}>{perk}</span>
          </div>
        ))}
      </div>

      <button 
        disabled={isCurrent}
        className={`w-full py-4 rounded-2xl font-black text-sm transition-all ${isCurrent ? 'bg-[#F1F5F9] text-[#94A3B8] cursor-default' : 'bg-[#0F62FE] text-white hover:bg-[#0056e0] shadow-lg shadow-blue-500/20'}`}
      >
        {isCurrent ? 'Current Plan' : 'Choose Plan'}
      </button>
    </div>
  );
}
