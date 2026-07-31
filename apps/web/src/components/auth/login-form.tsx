"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Loader2 } from "lucide-react";
import { OTPForm } from "./otp-form";
import { getUserFacingError } from "@/lib/user-facing-errors";

export function LoginForm() {
  const [email, setEmail] = useState("");
  const [otpSent, setOtpSent] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();
  const supabase = createClient();

  const redirectAfterLogin = async () => {
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();
    if (userError) throw userError;
    if (!user) throw new Error("Unable to load authenticated user");

    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (profileError) throw profileError;

    const role = profile?.role;
    if (role === "admin") {
      router.push("/admin/dashboard");
    } else if (role === "doctor") {
      router.push("/doctor/dashboard");
    } else {
      router.push("/patient/dashboard");
    }

    router.refresh();
  };

  const handleSendOtp = async (e?: React.FormEvent) => {
    e?.preventDefault();
    setLoading(true);
    setError(null);

    try {
      // Check rate limit before sending OTP (non-blocking if table doesn't exist)
      try {
        const { data: limitResult } = await supabase.rpc('check_otp_rate_limit', {
          p_email: email,
        });

        if (limitResult && !limitResult.allowed) {
          setError('Too many failed attempts. Please try again later.');
          setLoading(false);
          return;
        }
      } catch (_) {}

      // Record the attempt (non-blocking)
      try {
        await supabase.rpc('record_otp_attempt', { p_email: email });
      } catch (_) {}

      const { error: otpError } = await supabase.auth.signInWithOtp({
        email,
        options: { shouldCreateUser: false },
      });

      if (otpError) throw otpError;
      setOtpSent(true);
      toast.success("Verification code sent to your email");
    } catch (err: unknown) {
      console.error("Email code send failed", err);
      setError(
        getUserFacingError(
          err,
          "We could not send the verification code. Please try again.",
        ),
      );
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async (otp: string) => {
    const { error: verifyError } = await supabase.auth.verifyOtp({
      email,
      token: otp,
      type: "email",
    });

    if (verifyError) throw verifyError;
    await redirectAfterLogin();
  };

  const handleResendOtp = async () => {
    const { error: otpError } = await supabase.auth.signInWithOtp({
      email,
      options: { shouldCreateUser: false },
    });

    if (otpError) throw otpError;
    toast.success("New verification code sent");
  };

  if (otpSent) {
    return (
      <OTPForm
        email={email}
        onVerify={handleVerifyOtp}
        onResend={handleResendOtp}
      />
    );
  }

  return (
    <Card className="w-full max-w-md glass-panel border-none shadow-2xl rounded-[2.5rem] overflow-hidden p-4">
      <CardHeader className="space-y-4 pb-8">
        <CardTitle className="text-4xl font-black tracking-tighter text-gradient text-center">
          Welcome Back
        </CardTitle>
        <CardDescription className="text-center font-bold text-muted-foreground/60 uppercase tracking-widest text-[10px]">
          Sign in to your secure health portal
        </CardDescription>
      </CardHeader>
      <form onSubmit={(e) => handleSendOtp(e)}>
        <CardContent className="space-y-6">
          <div className="space-y-3">
            <Label
              htmlFor="email"
              className="text-xs font-black uppercase tracking-widest ml-1"
            >
              Email Address
            </Label>
            <Input
              id="email"
              type="email"
              placeholder="name@provider.com"
              required
              className="h-14 rounded-2xl bg-background/50 border-border/50 focus:ring-primary/20 transition-all font-bold"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
          <div className="rounded-2xl border border-primary/10 bg-primary/5 p-4 text-xs font-bold leading-relaxed text-muted-foreground">
            We will send a seven digit verification code to sign in to your
            Premon Care account.
          </div>
          {error && (
            <div className="p-4 text-[13px] bg-destructive/5 text-destructive rounded-2xl border border-destructive/10 font-bold animate-shake text-center">
              {error}
            </div>
          )}
        </CardContent>
        <CardFooter className="pt-6 pb-2 flex flex-col gap-4">
          <Button
            className="w-full h-16 rounded-3xl text-lg font-black shadow-xl shadow-primary/30 hover:scale-[1.02] transition-transform"
            type="submit"
            disabled={loading}
          >
            {loading ? (
              <Loader2 className="h-6 w-6 animate-spin" />
            ) : (
              "Send Email Code"
            )}
          </Button>
        </CardFooter>
        <div className="px-6 pb-6 space-y-3">
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <span className="w-full border-t border-muted-foreground/20" />
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-card px-2 text-muted-foreground/60 font-bold tracking-widest">
                Or continue with
              </span>
            </div>
          </div>
          <div className="flex gap-3">
            <Button
              variant="outline"
              type="button"
              className="w-full h-12 rounded-2xl justify-center font-bold border-muted-foreground/20 hover:bg-muted/50"
              onClick={() => toast.info("Google Sign-In is not yet enabled. Please use your email to sign in.")}
            >
              <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24">
                <path
                  fill="currentColor"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="currentColor"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="currentColor"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                />
                <path
                  fill="currentColor"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
              Continue with Google
            </Button>
          </div>
        </div>
        <div className="px-6 pb-8 text-center text-[13px] font-bold text-muted-foreground/60 uppercase tracking-widest">
          New Participant?{" "}
          <button
            type="button"
            onClick={() => router.push("/register")}
            className="text-primary hover:underline"
          >
            Sign Up Here
          </button>
        </div>
      </form>
    </Card>
  );
}
