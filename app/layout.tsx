import type { Metadata } from 'next';
import { Syne, DM_Sans, IBM_Plex_Mono } from 'next/font/google';
import './globals.css';

const display = Syne({
  subsets: ['latin'],
  variable: '--font-display',
  weight: ['600', '700', '800'],
});

const body = DM_Sans({
  subsets: ['latin'],
  variable: '--font-body',
  weight: ['400', '500', '700'],
});

const mono = IBM_Plex_Mono({
  subsets: ['latin'],
  variable: '--font-mono',
  weight: ['400', '500'],
});

export const metadata: Metadata = {
  title: 'Grantpath — Path to Claude Max & Codex OSS access',
  description:
    'A honest playbook and tracker to qualify for Anthropic Claude for Open Source and OpenAI Codex for Open Source.',
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${display.variable} ${body.variable} ${mono.variable}`}>
      <body className="min-h-screen bg-paper font-body antialiased">{children}</body>
    </html>
  );
}
