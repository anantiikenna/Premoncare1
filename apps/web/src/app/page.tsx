import Link from "next/link";
import Image from "next/image";
import { Button } from "@/components/ui/button";
import { 
  HeartPulse, 
  ArrowRight, 
  Stethoscope, 
  Activity, 
  Menu,
  User,
  Baby, 
  Bone, 
  Brain, 
  ShieldAlert,
  CheckCircle2,
  Mail,
  Phone,
  MapPin,
  Facebook,
  Twitter,
  Instagram,
  Linkedin
} from "lucide-react";
import { getDoctorsWithRatings } from "@/lib/queries-base";
import { createClient } from "@/lib/supabase-server";
import { Header } from "@/components/layout/header";

interface DoctorListing {
  id: string;
  full_name: string;
  avatar_url?: string;
  specialty?: string;
  experience_years?: number;
  clinic_address?: string;
  consultation_fee?: number;
  reviews?: { rating: number }[];
}

export default async function Home() {
  const supabase = await createClient();
  const { data: doctors } = await getDoctorsWithRatings(supabase);
  const featuredDoctors = doctors?.slice(0, 3) || [];

  const doctorPortraits = [
    "/doctor_portrait_01_1775234120792.png",
    "/doctor_portrait_02_1775234163903.png",
    "/doctor_portrait_01_1775234120792.png" // Fallback/Repeated for demo
  ];

  return (
    <div className="flex flex-col min-h-screen bg-background font-sans overflow-x-hidden">
      <Header />

      <main className="flex-1">
        {/* Hero Section */}
        <section className="relative min-h-[85vh] flex items-center px-6 lg:px-20 py-12 md:py-20 overflow-hidden">
          {/* Decorative mesh background */}
          <div className="absolute inset-0 bg-mesh opacity-60 -z-10" />
          <div className="absolute top-[-10%] right-[-5%] w-[300px] h-[300px] md:w-[500px] md:h-[500px] bg-primary/10 rounded-full blur-[80px] md:blur-[120px] -z-10" />
          <div className="absolute bottom-[0%] left-[-5%] w-[250px] h-[250px] md:w-[400px] md:h-[400px] bg-accent/10 rounded-full blur-[70px] md:blur-[100px] -z-10" />

          <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center max-w-7xl mx-auto w-full">
            <div className="space-y-8 md:space-y-10 text-center lg:text-left">
              <div className="inline-flex items-center gap-3 px-5 py-2.5 rounded-full bg-primary/5 border border-primary/20 text-primary text-[10px] md:text-[11px] font-black uppercase tracking-[0.3em] shadow-[0_0_30px_-5px_rgba(79,70,229,0.3)] mx-auto lg:mx-0">
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
                </span>
                Next-Gen Healthcare Ecosystem
              </div>
              <h1 className="text-5xl md:text-7xl lg:text-8xl font-black leading-[0.95] tracking-tighter py-4 flex flex-col gap-1">
                <span className="text-slate-900 dark:text-slate-100">Premium</span>
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary via-indigo-500 to-accent inline-block">
                  Care.
                </span>
              </h1>
              <p className="text-lg md:text-xl text-slate-600 dark:text-slate-400 leading-relaxed max-w-lg font-medium mx-auto lg:mx-0">
                Experience world-class healthcare powered by AI and human compassion. Seamless, secure, and centered around you.
              </p>
              <div className="flex flex-wrap justify-center lg:justify-start gap-5 pt-4">
                <Link href="/register">
                  <Button size="lg" className="group relative h-14 md:h-16 w-52 md:w-56 rounded-[2rem] bg-slate-900 text-white font-black overflow-hidden shadow-2xl hover:scale-105 transition-all duration-300 dark:bg-white dark:text-slate-900">
                    <div className="absolute inset-0 bg-gradient-to-r from-primary to-accent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
                    <span className="relative z-10 flex items-center justify-center gap-2 tracking-widest uppercase text-sm">
                      Get Started <ArrowRight className="h-5 w-5 group-hover:translate-x-1 transition-transform" />
                    </span>
                  </Button>
                </Link>
                <Link href="/emergency">
                  <Button variant="outline" size="lg" className="group relative h-14 md:h-16 w-52 md:w-56 rounded-[2rem] border-red-500/50 text-red-600 font-black overflow-hidden hover:bg-red-50 transition-all duration-300 shadow-xl">
                    <span className="relative z-10 flex items-center justify-center gap-3 tracking-widest uppercase text-sm">
                      <ShieldAlert className="h-5 w-5 animate-pulse shrink-0" /> Emergency Consult
                    </span>
                  </Button>
                </Link>
                <div className="flex items-center gap-4 px-6 py-2 glass-panel rounded-3xl">
                  <div className="flex -space-x-4">
                    {doctorPortraits.map((src, i) => (
                      <div key={i} className="h-10 w-10 md:h-12 md:w-12 rounded-full border-4 border-background bg-muted overflow-hidden relative">
                        <Image src={src} alt="User" fill className="object-cover" />
                      </div>
                    ))}
                  </div>
                  <div className="text-xs md:text-sm font-bold text-foreground">
                    50k+ Happy Patients
                  </div>
                </div>
              </div>
            </div>
            
            <div className="relative group mt-8 lg:mt-0">
              <div className="absolute inset-0 bg-primary/20 blur-3xl opacity-0 group-hover:opacity-40 transition-opacity duration-700 -z-10" />
              <div className="relative aspect-square rounded-[3rem] md:rounded-[4rem] overflow-hidden shadow-[0_50px_100px_-20px_rgba(30,41,59,0.3)] border-4 md:border-8 border-white/50 transform rotate-1 lg:rotate-2 group-hover:rotate-0 transition-all duration-700 max-w-[500px] mx-auto">
                <Image 
                  src="/hero_doctors_1775233503106.png" 
                  alt="Premon Care Medical Team" 
                  fill 
                  className="object-cover scale-110 group-hover:scale-100 transition-transform duration-1000"
                  priority
                />
              </div>
              {/* Floating Stat Card - Hidden on extra small mobile */}
              <div className="hidden xs:flex absolute bottom-6 md:bottom-10 -left-6 md:-left-10 glass-panel p-4 md:p-6 rounded-[1.5rem] md:rounded-[2rem] shadow-2xl animate-bounce-slow">
                <div className="flex items-center gap-3 md:gap-4">
                  <div className="h-10 w-10 md:h-12 md:w-12 rounded-xl md:rounded-2xl bg-accent/20 flex items-center justify-center text-accent">
                    <Activity className="h-5 w-5 md:h-6 md:w-6" />
                  </div>
                  <div>
                    <div className="text-xl md:text-2xl font-black">99.9%</div>
                    <div className="text-[10px] font-bold text-muted-foreground uppercase tracking-widest">Uptime Care</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Services Section */}
        <section id="services" className="section-padding px-6 lg:px-20 bg-white/50 relative overflow-hidden">
          <div id="doctors" className="absolute top-0 left-0 w-full h-0 invisible" />
          <div className="max-w-7xl mx-auto">
            <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 md:mb-20 gap-8 text-center md:text-left">
              <div className="space-y-4 md:space-y-6">
                <h2 className="text-4xl md:text-5xl font-black text-foreground tracking-tight">Our Core Specialties</h2>
                <p className="text-muted-foreground max-w-xl text-base md:text-lg font-medium mx-auto md:mx-0">Precision medicine combined with digital convenience to provide a healthcare experience unlike any other.</p>
              </div>
              <Button variant="outline" className="rounded-full px-8 h-12 font-bold border-2 mx-auto md:mx-0">Explore All Services</Button>
            </div>

            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
              {[
                { 
                  title: "Telemedicine", 
                  image: "/telemedicine_session_1775233930643.png", 
                  desc: "Connect with specialists instantly through our encrypted HD video platform.",
                },
                { 
                  title: "Advanced Screening", 
                  image: "/adv_health_screening_1775233986455.png", 
                  desc: "AI-driven diagnostics for early detection and personalized health mapping.",
                },
                { 
                  title: "Clinical Records", 
                  image: "/medical_center_interior_1775233843959.png", 
                  desc: "Your entire medical history, secured by blockchain-grade encryption.",
                }
              ].map((service, i) => (
                <div key={i} className="group relative overflow-hidden rounded-[2.5rem] md:rounded-[3rem] bg-card border border-border/50 hover:shadow-2xl transition-all duration-500 h-[400px] md:h-[500px]">
                  <Image src={service.image} alt={service.title} fill className="object-cover group-hover:scale-110 transition-transform duration-700" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent" />
                  <div className="absolute bottom-0 left-0 right-0 p-8 md:p-10 space-y-4">
                    <h3 className="text-2xl md:text-3xl font-black text-white">{service.title}</h3>
                    <p className="text-white/70 text-sm md:text-base font-medium leading-relaxed italic">{service.desc}</p>
                    <div className="pt-2 md:pt-4 flex items-center justify-between">
                      <Button variant="outline" className="bg-white/10 backdrop-blur-md border-white/20 text-white rounded-full px-6 hover:bg-white hover:text-black transition-colors">
                        Learn More
                      </Button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Mission Section */}
        <section id="about" className="section-padding px-6 lg:px-20 overflow-hidden">
          <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 lg:gap-24 items-center">
            <div className="relative">
              <div className="relative aspect-[4/5] rounded-[3rem] md:rounded-[4rem] overflow-hidden shadow-2xl max-w-[500px] mx-auto lg:mx-0">
                <Image 
                  src="/medical_center_interior_1775233843959.png" 
                  alt="Premon Care Center" 
                  fill 
                  className="object-cover"
                />
              </div>
              <div className="absolute -top-10 -right-10 w-48 h-48 md:w-64 md:h-64 bg-accent/20 rounded-full blur-[60px] md:blur-[80px] -z-10" />
            </div>
            <div className="space-y-8 md:space-y-12 text-center lg:text-left">
              <div className="space-y-4 md:space-y-6">
                <h2 className="text-4xl md:text-6xl font-black text-foreground leading-tight tracking-tight">
                  Modern Medicine. <br />
                  <span className="text-primary italic text-6xl md:text-8xl">Human Heart.</span>
                </h2>
                <p className="text-lg md:text-xl text-muted-foreground leading-relaxed font-medium">
                  At Premon Care, we believe that the best healthcare is not just about state-of-the-art technology, but about truly understanding the patient. We've built an ecosystem where innovation serves empathy.
                </p>
              </div>
              <div className="grid grid-cols-2 gap-6 md:gap-10">
                {[
                  { label: "Precision Care", icon: HeartPulse },
                  { label: "Global Access", icon: Activity },
                  { label: "Data Security", icon: ShieldAlert },
                  { label: "Expert Support", icon: User }
                ].map((item, i) => (
                  <div key={i} className="flex flex-col md:flex-row items-center gap-3 md:gap-5">
                    <div className="h-12 w-12 md:h-14 md:w-14 rounded-2xl bg-secondary flex items-center justify-center text-primary group hover:bg-primary hover:text-white transition-colors duration-300 shadow-sm">
                      <item.icon className="h-6 w-6 md:h-7 md:w-7" />
                    </div>
                    <span className="text-base md:text-lg font-black text-foreground">{item.label}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* CTA Section */}
        <section className="px-6 lg:px-20 py-12 md:py-20">
          <div className="max-w-7xl mx-auto py-16 md:py-24 px-8 md:px-20 rounded-[3rem] md:rounded-[4rem] bg-slate-900 overflow-hidden relative text-center">
            <div className="absolute inset-0 bg-primary/20 pointer-events-none" />
            <div className="absolute top-0 right-0 w-full lg:w-1/2 h-full bg-gradient-to-l from-primary/10 to-transparent" />
            
            <div className="relative z-10 flex flex-col lg:flex-row items-center justify-between gap-12 lg:gap-16">
              <div className="max-w-2xl space-y-6 md:space-y-8">
                <h2 className="text-4xl md:text-6xl font-black text-white leading-tight">Your Health, <br /> Personalized.</h2>
                <p className="text-white/60 text-lg md:text-xl font-medium leading-relaxed">
                  Join Premon Care today and take the first step towards a smarter, healthier future. Expert care is just a click away.
                </p>
              </div>
              <div className="flex flex-col sm:flex-row gap-5 w-full lg:w-auto">
                <Link href="/register" className="w-full sm:w-auto">
                  <Button size="lg" className="h-16 md:h-20 w-full sm:px-12 rounded-[2.5rem] bg-white text-slate-900 hover:bg-white/90 text-lg md:text-xl font-black shadow-2xl transition-transform hover:scale-105">
                    Join the Future
                  </Button>
                </Link>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="bg-white py-20 md:py-32 px-6 lg:px-20 border-t border-border/50">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between gap-16 md:gap-20">
          <div className="space-y-8 md:space-y-10 max-w-sm text-center md:text-left mx-auto md:mx-0">
            <div className="flex items-center justify-center md:justify-start">
              <div className="relative h-24 w-64 md:h-32 md:w-80">
                <Image 
                  src="/logo-vertical.png" 
                  alt="Premon Care" 
                  fill 
                  className="object-contain"
                />
              </div>
            </div>
            <p className="text-muted-foreground font-medium leading-relaxed opacity-80 italic">
              Empowering wellness through precision digital medicine and compassionate care.
            </p>
            <div className="flex justify-center md:justify-start gap-4">
              {[Facebook, Twitter, Instagram, Linkedin].map((Icon, i) => (
                <Link key={i} href="#" className="h-12 w-12 md:h-14 md:w-14 rounded-2xl bg-secondary flex items-center justify-center hover:bg-primary hover:text-white transition-all duration-300 shadow-sm">
                  <Icon className="h-5 w-5 md:h-6 md:w-6" />
                </Link>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-3 gap-10 md:gap-16 text-center md:text-left">
            <div className="space-y-6 md:space-y-8">
              <h4 className="text-[10px] md:text-xs font-black text-foreground uppercase tracking-widest opacity-60">Platform</h4>
              <ul className="space-y-4 md:space-y-5 font-bold text-sm md:text-base text-muted-foreground">
                {['Specialties', 'Technology', 'Pricing', 'Security'].map(l => (
                  <li key={l}><Link href="#" className="hover:text-primary transition-colors">{l}</Link></li>
                ))}
              </ul>
            </div>
            <div className="space-y-6 md:space-y-8">
              <h4 className="text-[10px] md:text-xs font-black text-foreground uppercase tracking-widest opacity-60">Company</h4>
              <ul className="space-y-4 md:space-y-5 font-bold text-sm md:text-base text-muted-foreground">
                {['Our Vision', 'Partners', 'Careers', 'Press'].map(l => (
                  <li key={l}><Link href="#" className="hover:text-primary transition-colors">{l}</Link></li>
                ))}
              </ul>
            </div>
            <div className="space-y-6 md:space-y-8 col-span-2 md:col-span-1">
              <h4 className="text-[10px] md:text-xs font-black text-foreground uppercase tracking-widest opacity-60">Support</h4>
              <ul className="space-y-4 md:space-y-5 font-bold text-sm md:text-base text-muted-foreground">
                <li className="break-all"><a href="mailto:support@premoncare.com" className="hover:text-primary transition-colors">support@premoncare.com</a></li>
                <li>+234 1 234 5678</li>
                <li className="max-w-xs mx-auto md:mx-0">12 Admiralty Way, Lekki Phase 1, Lagos, Nigeria</li>
              </ul>
            </div>
          </div>
        </div>
        <div className="max-w-7xl mx-auto mt-20 md:mt-32 pt-10 border-t border-border/50 text-center text-[10px] md:text-sm font-bold text-muted-foreground/60 uppercase tracking-widest">
          © 2026 Premon Care - The Art of Modern Wellness
        </div>
      </footer>
    </div>
  );
}
