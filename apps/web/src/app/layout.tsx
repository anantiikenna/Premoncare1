import type { Metadata } from "next";
import { Outfit } from "next/font/google";
import "./globals.css";
import { QueryProvider } from "@/components/providers/query-provider";
import { PostHogProvider } from "@/components/providers/posthog-provider";
import { Toaster } from "sonner";
import { CookieConsent } from "@/components/layout/cookie-consent";

const outfit = Outfit({
  variable: "--font-outfit",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'https://premoncare.netlify.app'),
  title: "Premon Care | Premium Care",
  description: "Experience the future of healthcare. Secure appointment booking, personal health records, and a supportive community for patients and doctors.",
  keywords: ["healthcare", "medical records", "doctor appointments", "health community", "patient portal"],
  authors: [{ name: "Premon Care Team" }],
  openGraph: {
    title: "Premon Care | Premium Care",
    description: "Streamlined healthcare for the modern era.",
    url: "/",
    siteName: "Premon Care",
    images: [
      {
        url: "/og-image.jpg",
        width: 1200,
        height: 630,
        alt: "Premon Care Platform Overview",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Premon Care | Premium Care",
    description: "Streamlined healthcare for the modern era.",
    images: ["/og-image.jpg"],
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${outfit.variable} font-sans antialiased`}
      >
        <PostHogProvider>
          <QueryProvider>
            {children}
          </QueryProvider>
        </PostHogProvider>
        <Toaster position="top-center" richColors theme="light" />
        <CookieConsent />
      </body>
    </html>
  );
}
