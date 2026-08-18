"use client";

import { createContext, useContext, useEffect, useState, useRef, ReactNode } from "react";
import { createClient } from "@/lib/supabase";
import { useRouter } from "next/navigation";
import { Session } from "@supabase/supabase-js";

interface InactivityContextType {}
const InactivityContext = createContext<InactivityContextType>({});

export function InactivityProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [showWarning, setShowWarning] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  const INACTIVITY_LIMIT = 15 * 60 * 1000; // 15 minutes
  const WARNING_TIME = 14 * 60 * 1000; // 14 minutes
  
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const warningTimerRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, [supabase]);

  const resetTimers = () => {
    if (!session) return;
    
    if (timerRef.current) clearTimeout(timerRef.current);
    if (warningTimerRef.current) clearTimeout(warningTimerRef.current);
    
    setShowWarning(false);

    warningTimerRef.current = setTimeout(() => {
      setShowWarning(true);
    }, WARNING_TIME);

    timerRef.current = setTimeout(async () => {
      await supabase.auth.signOut();
      router.push('/login?reason=inactivity');
    }, INACTIVITY_LIMIT);
  };

  useEffect(() => {
    if (!session) {
      if (timerRef.current) clearTimeout(timerRef.current);
      if (warningTimerRef.current) clearTimeout(warningTimerRef.current);
      setShowWarning(false);
      return;
    }

    resetTimers();

    const events = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'];
    
    const handleActivity = () => {
      // Throttle timer resets to avoid performance issues
      if (!showWarning) {
        resetTimers();
      }
    };

    events.forEach(event => window.addEventListener(event, handleActivity, { passive: true }));

    return () => {
      events.forEach(event => window.removeEventListener(event, handleActivity));
      if (timerRef.current) clearTimeout(timerRef.current);
      if (warningTimerRef.current) clearTimeout(warningTimerRef.current);
    };
  }, [session, showWarning]); // include showWarning so we don't reset if warning is showing unless explicitly requested

  const handleStayLoggedIn = () => {
    resetTimers();
  };

  return (
    <InactivityContext.Provider value={{}}>
      {children}
      
      {showWarning && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl shadow-xl max-w-sm w-full p-6 text-center animate-in fade-in zoom-in duration-200">
            <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-amber-100 mb-4">
              <svg className="h-6 w-6 text-amber-600" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
            </div>
            <h3 className="text-lg font-bold text-slate-900 mb-2">Session Expiring Soon</h3>
            <p className="text-sm text-slate-500 mb-6">
              For your security, you will be logged out in 1 minute due to inactivity.
            </p>
            <button
              onClick={handleStayLoggedIn}
              className="w-full bg-[#0F62FE] hover:bg-indigo-700 text-white font-semibold py-2.5 px-4 rounded-xl transition-colors cursor-pointer"
            >
              Stay Logged In
            </button>
          </div>
        </div>
      )}
    </InactivityContext.Provider>
  );
}
