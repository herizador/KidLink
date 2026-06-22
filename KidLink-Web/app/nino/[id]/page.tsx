"use client";

import { useEffect, useRef, useState } from "react";
import { useParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

type TagData = {
  id_tag: string;
  nombre_nino: string;
  informacion_medica: string;
  contacto_alternativo: string | null;
  telefono_contacto: string;
  url_foto: string | null;
  activo: boolean;
};

type PageState = "loading" | "found" | "not_found" | "inactive";

function detectDevice(): string {
  if (typeof navigator === "undefined") return "Web";
  const ua = navigator.userAgent;
  if (/android/i.test(ua)) return "Android";
  if (/iphone|ipad|ipod/i.test(ua)) return "iOS";
  return "Web";
}

function Skeleton() {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center gap-6 px-6 animate-pulse">
      <div className="size-32 rounded-full bg-gray-200" />
      <div className="h-8 w-48 rounded bg-gray-200" />
      <div className="h-4 w-64 rounded bg-gray-200" />
      <div className="mt-4 flex w-full max-w-sm flex-col gap-3">
        <div className="h-14 w-full rounded-xl bg-gray-200" />
        <div className="h-14 w-full rounded-xl bg-gray-200" />
      </div>
    </div>
  );
}

function ErrorScreen({ title, message }: { title: string; message: string }) {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center px-6 text-center">
      <div className="mb-4 text-6xl">⚠️</div>
      <h1 className="mb-2 text-2xl font-bold text-gray-900">{title}</h1>
      <p className="text-gray-600">{message}</p>
    </div>
  );
}

export default function NinoPage() {
  const params = useParams<{ id: string }>();
  const idTag = params.id;
  const insertedRef = useRef(false);

  const [pageState, setPageState] = useState<PageState>("loading");
  const [tag, setTag] = useState<TagData | null>(null);
  const [gpsDenied, setGpsDenied] = useState(false);

  useEffect(() => {
    if (!idTag) {
      setPageState("not_found");
      return;
    }

    const supabase = createClient();
    let cancelled = false;

    async function load() {
      const { data, error } = await supabase
        .from("ninos_tags")
        .select("*")
        .eq("id_tag", idTag)
        .single();

      if (cancelled) return;

      if (error || !data) {
        setPageState("not_found");
        return;
      }

      if (!data.activo) {
        setPageState("inactive");
        return;
      }

      setTag(data);
      setPageState("found");

      navigator.geolocation.getCurrentPosition(
        (position) => {
          if (cancelled || insertedRef.current) return;
          insertedRef.current = true;
          supabase.from("alertas_escaneo").insert({
            id_tag: idTag,
            latitud: position.coords.latitude,
            longitud: position.coords.longitude,
            gps_activo: true,
            dispositivo_origen: detectDevice(),
          }).then(undefined, () => {});
        },
        () => {
          if (cancelled || insertedRef.current) return;
          insertedRef.current = true;
          setGpsDenied(true);
          supabase.from("alertas_escaneo").insert({
            id_tag: idTag,
            latitud: null,
            longitud: null,
            gps_activo: false,
            dispositivo_origen: detectDevice(),
          }).then(undefined, () => {});
        },
        { timeout: 10000, enableHighAccuracy: false },
      );
    }

    load();

    return () => {
      cancelled = true;
    };
  }, [idTag]);

  if (pageState === "loading") return <Skeleton />;
  if (pageState === "not_found") {
    return (
      <ErrorScreen
        title="Tag no encontrado"
        message="El código que escaneaste no corresponde a ningún registro activo en KidLink."
      />
    );
  }
  if (pageState === "inactive") {
    return (
      <ErrorScreen
        title="Tag desactivado"
        message="Este tag ha sido desactivado por el padre o tutor. No se puede mostrar información."
      />
    );
  }

  return (
    <main className="flex min-h-dvh flex-col items-center px-6 py-8">
      {gpsDenied && (
        <div className="mb-6 w-full max-w-md rounded-xl bg-amber-50 px-4 py-3 text-center text-sm text-amber-800 ring-1 ring-amber-200">
          Activa el GPS de tu celular y recarga la página para ayudar a los
          padres a localizar al niño.
        </div>
      )}

      <div className="flex w-full max-w-md flex-col items-center">
        <div className="mb-4 size-32 overflow-hidden rounded-full ring-4 ring-blue-100">
          {tag?.url_foto ? (
            <img
              src={tag.url_foto}
              alt={tag.nombre_nino}
              className="size-full object-cover"
            />
          ) : (
            <div className="flex size-full items-center justify-center bg-blue-50 text-4xl text-blue-400">
              👤
            </div>
          )}
        </div>

        <h1 className="mb-6 text-3xl font-bold text-gray-900">
          {tag?.nombre_nino}
        </h1>

        {tag?.informacion_medica && (
          <section className="mb-8 w-full rounded-2xl bg-red-50 p-5 ring-1 ring-red-200">
            <h2 className="mb-2 flex items-center gap-2 text-lg font-semibold text-red-800">
              <span>⚠️</span> Información médica importante
            </h2>
            <p className="whitespace-pre-wrap text-red-700">
              {tag.informacion_medica}
            </p>
          </section>
        )}

        <div className="flex w-full flex-col gap-3">
          <a
            href={`tel:${tag?.telefono_contacto}`}
            className="flex items-center justify-center gap-2 rounded-2xl bg-green-600 px-6 py-4 text-lg font-bold text-white shadow-lg transition active:scale-[0.97] active:bg-green-700"
          >
            <span>📞</span> Llamar al Padre
          </a>

          {tag?.contacto_alternativo && (
            <a
              href={`tel:${tag.contacto_alternativo}`}
              className="flex items-center justify-center gap-2 rounded-2xl bg-blue-600 px-6 py-4 text-lg font-bold text-white shadow-lg transition active:scale-[0.97] active:bg-blue-700"
            >
              <span>👤</span> Contacto Alternativo
            </a>
          )}
        </div>

        <p className="mt-8 text-center text-xs text-gray-400">
          KidLink — Seguridad Infantil
        </p>
      </div>
    </main>
  );
}
