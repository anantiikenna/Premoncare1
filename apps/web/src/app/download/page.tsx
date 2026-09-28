import type { Metadata } from "next";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Header } from "@/components/layout/header";
import {
  androidDownload,
  androidDownloadSizeLabel,
  hasAndroidDownload,
} from "@/lib/android-download";
import { Download, ShieldCheck, Smartphone, CheckCircle2, ArrowLeft } from "lucide-react";

export const metadata: Metadata = {
  title: "Download Premoncare for Android",
  description:
    "Get the Premoncare Android app. Direct APK download with version, size, and SHA-256 checksum to verify the file.",
};

const installSteps = [
  {
    title: "Download the APK",
    description: "Tap the download button. Your browser saves the file to your device.",
  },
  {
    title: "Allow this source",
    description:
      "Open the file. Android asks permission to install from your browser (Chrome, Files, etc.) - toggle Allow from this source.",
  },
  {
    title: "Install and sign in",
    description: "Confirm the install, open Premoncare, and log in with your existing account.",
  },
];

export default function DownloadPage() {
  return (
    <main className="min-h-screen bg-background">
      <Header />

      <section className="px-6 lg:px-20 py-16 md:py-24">
        <div className="mx-auto max-w-4xl space-y-10">
          <div className="space-y-4 text-center">
            <div className="flex flex-wrap items-center justify-center gap-2">
              <div className="inline-flex items-center gap-2 rounded-full bg-primary/10 px-4 py-2 text-[10px] font-black uppercase tracking-widest text-primary">
                <Smartphone className="h-4 w-4" />
                Android App
              </div>
              <div className="inline-flex items-center gap-2 rounded-full border border-border/60 bg-secondary/60 px-4 py-2 text-[10px] font-black uppercase tracking-widest text-muted-foreground">
                iOS Coming Soon
              </div>
            </div>
            <h1 className="text-4xl md:text-6xl font-black tracking-tight text-foreground">
              Premoncare for Android
            </h1>
            <p className="mx-auto max-w-2xl text-base md:text-lg font-medium leading-relaxed text-muted-foreground">
              Book appointments, message your doctor, and manage your records from your phone.
              The app is distributed as a direct APK download, outside the Play Store.
            </p>
          </div>

          {hasAndroidDownload ? (
            <>
              <Card className="rounded-[2rem] border-border/50 shadow-xl">
                <CardContent className="flex flex-col gap-6 p-6 md:flex-row md:items-center md:justify-between md:p-8">
                  <div className="flex items-center gap-4">
                    <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-primary/10 text-primary">
                      <Smartphone className="h-7 w-7" />
                    </div>
                    <div className="min-w-0">
                      <p className="break-all font-black text-foreground">{androidDownload.fileName}</p>
                      <p className="text-sm font-bold text-muted-foreground">
                        Version {androidDownload.version} &middot; {androidDownloadSizeLabel}
                      </p>
                    </div>
                  </div>
                  <Button
                    asChild
                    size="lg"
                    className="h-14 w-full rounded-2xl bg-slate-900 font-black text-white shadow-xl hover:scale-105 transition-transform md:w-auto dark:bg-white dark:text-slate-900"
                  >
                    <a href={androidDownload.url}>
                      <Download className="mr-2 h-5 w-5" /> Download APK
                    </a>
                  </Button>
                </CardContent>
              </Card>

              <Card className="rounded-[2rem] border-border/50">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-lg font-black">
                    <ShieldCheck className="h-5 w-5 text-primary" />
                    Verify the file
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-2 p-6 pt-0">
                  <p className="text-sm font-medium text-muted-foreground">
                    SHA-256 checksum of {androidDownload.fileName}:
                  </p>
                  <p className="break-all rounded-2xl bg-secondary/60 p-4 font-mono text-xs leading-relaxed text-foreground">
                    {androidDownload.sha256}
                  </p>
                </CardContent>
              </Card>

              <Card className="rounded-[2rem] border-border/50">
                <CardHeader>
                  <CardTitle className="text-lg font-black">Install from this source</CardTitle>
                </CardHeader>
                <CardContent className="space-y-6 p-6 pt-0">
                  <ol className="space-y-5">
                    {installSteps.map((step, i) => (
                      <li key={step.title} className="flex gap-4">
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-sm font-black text-primary">
                          {i + 1}
                        </span>
                        <div>
                          <p className="font-black text-foreground">{step.title}</p>
                          <p className="text-sm font-medium leading-6 text-muted-foreground">
                            {step.description}
                          </p>
                        </div>
                      </li>
                    ))}
                  </ol>
                  <p className="flex items-start gap-2 rounded-2xl bg-secondary/50 p-4 text-xs font-medium leading-5 text-muted-foreground">
                    <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
                    Android 8.0 and newer only allow installations from sources you approve. This
                    APK is not on the Google Play Store. iOS coming soon.
                  </p>
                </CardContent>
              </Card>
            </>
          ) : (
            <Card className="rounded-[2rem] border-border/50">
              <CardContent className="p-8 text-center text-sm font-medium text-muted-foreground">
                The Android build is not available yet. Check back soon.
              </CardContent>
            </Card>
          )}

          <div className="text-center">
            <Button asChild variant="outline" className="rounded-2xl font-black">
              <Link href="/">
                <ArrowLeft className="mr-2 h-4 w-4" /> Back to home
              </Link>
            </Button>
          </div>
        </div>
      </section>
    </main>
  );
}
