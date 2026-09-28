'use client'

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { Button } from "@/components/ui/button";
import { HeartPulse, Menu, X, Download } from "lucide-react";
import { cn } from "@/lib/utils";
import { hasAndroidDownload } from "@/lib/android-download";

export function Header() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const navLinks = [
    { name: 'Home', href: '/' },
    { name: 'Services', href: '#services' },
    { name: 'About', href: '#about' },
    { name: 'Doctors', href: '#doctors' },
    { name: 'Community', href: '/patient/forum' },
    ...(hasAndroidDownload ? [{ name: 'Get App', href: '/download' }] : []),
  ];

  return (
    <>
      <header className="px-6 lg:px-20 h-20 flex items-center justify-between glass-panel sticky top-0 z-50 border-b border-border/50 shadow-sm">
      <Link href="/" className="flex items-center group cursor-pointer">
        <div className="relative h-10 w-40 md:h-14 md:w-56 group-hover:scale-105 transition-all duration-500 ease-out">
          <div className="absolute inset-0 bg-primary/10 blur-xl rounded-full opacity-0 group-hover:opacity-100 transition-opacity" />
          <Image 
            src="/logo-horizontal.png" 
            alt="Premon Care" 
            fill 
            className="object-contain relative z-10"
          />
        </div>
      </Link>

      {/* Desktop Navigation */}
      <nav className="hidden xl:flex gap-12 items-center text-sm font-bold text-muted-foreground">
        {navLinks.map((link) => (
          <Link 
            key={link.name} 
            href={link.href} 
            className="hover:text-primary transition-all relative group"
          >
            {link.name}
            <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-primary transition-all group-hover:w-full" />
          </Link>
        ))}
      </nav>
      
      <div className="flex items-center gap-4">
        {hasAndroidDownload && (
          <Link href="/download" className="hidden sm:flex items-center gap-2 rounded-xl bg-primary/10 px-3 py-2 text-primary hover:bg-primary hover:text-white transition-colors font-bold text-sm shadow-sm" aria-label="Download the mobile app">
            <Download className="h-4 w-4 shrink-0" />
            <span className="hidden md:inline">Get App</span>
          </Link>
        )}
        <Link href="/login" className="hidden sm:block">
          <Button variant="ghost" className="font-bold text-muted-foreground hover:text-primary hover:bg-primary/5 rounded-xl">
            Sign In
          </Button>
        </Link>
        <Link href="/register" className="hidden xs:block">
          <Button className="rounded-2xl px-6 md:px-8 bg-primary hover:bg-primary/90 font-bold shadow-xl shadow-primary/30 h-12">
            Book Appointment
          </Button>
        </Link>
        
        {/* Mobile Menu Toggle */}
        <Button 
          variant="ghost" 
          size="icon" 
          className="xl:hidden rounded-xl hover:bg-primary/5" 
          onClick={() => setIsMenuOpen(!isMenuOpen)}
        >
          {isMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </Button>
      </div>

      </header>
      
      {/* Mobile Navigation Drawer */}
      {isMenuOpen && (
        <div 
          className="xl:hidden fixed inset-0 top-24 z-[100] glass-panel animate-in-fade border-t border-border/50 shadow-2xl"
        >
          <nav className="flex flex-col p-8 gap-6 h-full overflow-y-auto no-scrollbar">
            {navLinks.map((link) => (
              <Link 
                key={link.name} 
                href={link.href} 
                onClick={() => setIsMenuOpen(false)}
                className="text-2xl font-black tracking-tight text-foreground hover:text-primary transition-colors flex items-center justify-between"
              >
                {link.name}
                <HeartPulse className="h-5 w-5 opacity-0 group-hover:opacity-100 text-primary" />
              </Link>
            ))}
            <div className="mt-auto pt-8 border-t border-border/50 flex flex-col gap-4">
              <Link href="/login" onClick={() => setIsMenuOpen(false)}>
                <Button variant="outline" className="w-full h-14 rounded-2xl font-bold text-lg">
                  Sign In
                </Button>
              </Link>
              <Link href="/register" onClick={() => setIsMenuOpen(false)}>
                <Button className="w-full h-14 rounded-2xl font-bold text-lg bg-primary shadow-xl shadow-primary/20">
                  Book Appointment
                </Button>
              </Link>
            </div>
          </nav>
        </div>
      )}
    </>
  );
}
