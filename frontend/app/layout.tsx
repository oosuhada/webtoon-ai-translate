import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { ReactNode } from "react";

import "./globals.css";
import { Providers } from "./providers";
import { cn } from "@/lib/utils";

const inter = Inter({ subsets: ["latin"], variable: "--font-sans" });

export const metadata: Metadata = {
  title: "AI Losy",
  description: "Professional webtoon translation assistant",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="ko" className={cn("font-sans", inter.variable)}>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
