import Image from "next/image";

export default function Home() {
  return (
    <main className="flex min-h-dvh flex-col items-center justify-center px-6 text-center">
      <Image
        src="/KidLink Logo.png"
        alt="KidLink"
        width={96}
        height={96}
        className="mb-6"
        priority
      />
      <h1 className="mb-4 text-3xl font-bold text-gray-900">KidLink</h1>
      <p className="max-w-sm text-gray-600">
        Escanea el código QR o NFC del llavero o pulsera del niño para ver su
        información de emergencia.
      </p>
    </main>
  );
}
