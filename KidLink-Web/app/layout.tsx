import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "KidLink - Emergencia",
  description:
    "Información de emergencia y contacto para ayudar a un niño perdido",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body className="min-h-dvh bg-white antialiased">{children}</body>
    </html>
  );
}
