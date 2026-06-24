"use client";

import { useEffect, useRef, useState } from "react";
import { useParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { PhoneIcon, UserIcon, ExclamationTriangleIcon, MapPinIcon } from "@heroicons/react/24/solid";

type TagData = {
  id_tag: string;
  nombre_nino: string;
  informacion_medica: string;
  contacto_alternativo: string | null;
  telefono_contacto: string;
  url_foto: string | null;
  activo: boolean;
};

type PageState = "loading" | "found" | "not_found" | "inactive" | "connection_error";

function detectDevice(): string {
  if (typeof navigator === "undefined") return "Web";
  const ua = navigator.userAgent;
  if (/android/i.test(ua)) return "Android";
  if (/iphone|ipad|ipod/i.test(ua)) return "iOS";
  return "Web";
}

function Skeleton() {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center gap-6 px-6 animate-pulse bg-slate-50">
      <div className="size-32 rounded-full bg-gray-200" />
      <div className="h-8 w-48 rounded bg-gray-200" />
      <div className="h-4 w-64 rounded bg-gray-200" />
      <div className="mt-4 flex w-full max-w-sm flex-col gap-3">
        <div className="h-14 w-full rounded-3xl bg-gray-200" />
        <div className="h-14 w-full rounded-3xl bg-gray-200" />
      </div>
    </div>
  );
}

function ErrorScreen({ title, message }: { title: string; message: string }) {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center px-6 text-center bg-slate-50">
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
  const [gpsActivo, setGpsActivo] = useState<boolean | null>(null);

  useEffect(() => {
    if (!idTag) {
      setPageState("not_found");
      return;
    }

    const supabase = createClient();
    let cancelled = false;

    async function load() {
      let data: TagData | null = null;

      try {
        const result = await supabase
          .from("ninos_tags")
          .select("*")
          .eq("id_tag", idTag)
          .single();

        if (cancelled) return;

        if (result.error) {
          console.error("Supabase error:", result.error);
          setPageState(
            result.error.code === "PGRST301" || result.error.code === "406"
              ? "not_found"
              : "connection_error",
          );
          return;
        }

        data = result.data;

        if (!data) {
          setPageState("not_found");
          return;
        }
      } catch (e) {
        if (cancelled) return;
        console.error("Error inesperado:", e);
        setPageState("connection_error");
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
          setGpsActivo(true);
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
          setGpsActivo(false);
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
  if (pageState === "connection_error") {
    return (
      <ErrorScreen
        title="Error de conexión"
        message="No se pudo conectar con el servidor de KidLink. Verifica tu conexión a internet e intenta de nuevo."
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
    <main className="flex min-h-dvh flex-col items-center bg-slate-50 px-4 py-6">
      <div className="flex w-full max-w-md flex-col items-center rounded-3xl bg-white px-4 py-6 shadow-md">

        {gpsActivo === true && (
          <div className="mb-6 w-full rounded-xl bg-emerald-50 px-4 py-3 text-center text-sm font-medium text-emerald-700 ring-1 ring-emerald-200">
            <MapPinIcon className="inline-block mr-1.5 size-5 -mt-0.5 text-emerald-500" />
            Ubicación compartida con los padres
          </div>
        )}

        {gpsActivo === false && (
          <div className="mb-6 w-full rounded-xl bg-amber-50 px-4 py-3 text-center text-sm text-amber-800 ring-1 ring-amber-200">
            <ExclamationTriangleIcon className="inline-block mr-1.5 size-5 -mt-0.5 text-amber-500 animate-pulse" />
            Activa el GPS de tu celular y recarga la página para ayudar a los
            padres a localizar al niño.
          </div>
        )}

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
          <section className="mb-8 w-full rounded-2xl border border-red-100 bg-white p-5">
            <h2 className="mb-2 flex items-center gap-2 text-base font-semibold text-red-800">
              <ExclamationTriangleIcon className="size-5 text-red-500" />
              Información médica importante
            </h2>
            <p className="whitespace-pre-wrap text-base leading-relaxed text-red-700">
              {tag.informacion_medica}
            </p>
          </section>
        )}

        <div className="flex w-full flex-col gap-3">
          <a
            href={`tel:${tag?.telefono_contacto}`}
            className="flex items-center justify-center gap-3 rounded-full bg-green-600 px-6 py-4 text-lg font-bold text-white shadow-lg transition-all active:scale-95 active:bg-green-700"
          >
            <PhoneIcon className="size-6" />
            Llamar al Padre
          </a>

          {tag?.contacto_alternativo && (
            <a
              href={`tel:${tag.contacto_alternativo}`}
              className="flex items-center justify-center gap-3 rounded-full bg-blue-600 px-6 py-4 text-lg font-bold text-white shadow-lg transition-all active:scale-95 active:bg-blue-700"
            >
              <UserIcon className="size-6" />
              Contacto Alternativo
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
