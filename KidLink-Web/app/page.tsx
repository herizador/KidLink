import Image from "next/image";

export default function Home() {
  return (
    <main className="flex min-h-dvh flex-col items-center justify-center px-6 text-center bg-gradient-to-b from-slate-50 to-white">
      <div className="mb-6 rounded-2xl bg-white p-4 shadow-sm ring-1 ring-slate-200">
        <Image
          src="/KidLink Logo.png"
          alt="KidLink"
          width={96}
          height={96}
          priority
        />
      </div>
      <h1 className="mb-4 text-3xl font-bold text-gray-900">KidLink</h1>
      <p className="max-w-sm text-gray-600">
        Escanea el código QR o NFC del llavero o pulsera del niño para ver su
        información de emergencia.
      </p>
    </main>
  );
}
