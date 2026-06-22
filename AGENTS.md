# KidLink — Guía para el agente

## Estructura del repo

```
KidLink-App/        App Flutter (futura) — solo placeholders
KidLink-Web/        Web Next.js 14+ (activa) — ya scaffolded
prompt.txt          Especificación completa del proyecto (ES)
```

## Stack obligatorio

- **Web**: Next.js 14+ (App Router), React 18, Tailwind CSS 3, TypeScript 5. Vercel para deploy.
- **App** (futura): Flutter / Dart.
- **Backend/DB**: Supabase (PostgreSQL, Auth, Storage, Realtime).
- No agregar librerías sin aprobación explícita.

## Punto de entrada único

`KidLink-Web/app/nino/[id]/page.tsx` — Página pública de emergencia. Componente cliente (`"use client"`) que:
1. Consulta `ninos_tags` por `id_tag` de la URL.
2. Si `activo == false` o no existe, muestra pantalla de error.
3. Inserta siempre una fila en `alertas_escaneo` (incluso si el usuario deniega GPS).
4. Muestra foto, nombre, info médica y botones `tel:`.

## Scripts (desde `KidLink-Web/`)

```bash
npm run dev       # next dev
npm run build     # next build
npm run start     # next start
npm run lint      # next lint
```

## Configuración y secretos

- `KidLink-Web/.env.local` — gitignorado. Contiene `NEXT_PUBLIC_SUPABASE_*` y `NEXT_PUBLIC_APP_URL`. Copia de `KidLink-App/`.
- `KidLink-App/config.json` — gitignorado. Mismas credenciales.
- `.gitignore` cubre: `node_modules/`, `.next/`, `build/`, `.dart_tool/`, `.env*.local`, `config.json`.

## Esquema de BD

Definido en `prompt.txt`. Tablas existentes en Supabase:
- `public.perfiles_padres` — vinculada a `auth.users` por trigger.
- `public.ninos_tags` — `id_tag` (UUID, PK), `id_padre`, `nombre_nino`, `informacion_medica`, `contacto_alternativo`, `telefono_contacto`, `url_foto`, `activo`.
- `public.alertas_escaneo` — `id_alerta`, `id_tag`, `latitud`, `longitud`, `gps_activo`, `dispositivo_origen`, `fecha_hora`, `visto`.

## Peculiaridades del entorno

- **`npm install` no funciona** en `F:\Proyectos Personales\KidLink\KidLink-Web\` por los espacios en la ruta. Solución: usar `subst` para mapear la ruta a una letra de unidad sin espacios:
  ```bash
  subst X: "F:\Proyectos Personales\KidLink"
  cd /d X:\KidLink-Web
  npm install
  subst X: /D   # limpiar al terminar
  ```
- `node_modules/` y `package-lock.json` ya existen; no regenerar a menos que cambien las dependencias.

## Estado actual

- Commit único: `Estructura inicial de KidLink: Web y App`.
- Sin CI, sin linter configurado, sin Docker.
- `KidLink-Web/` está scaffolded con 3 rutas: raíz, layout y `nino/[id]`.
- El cliente Supabase vive en `lib/supabase/client.ts` usando `@supabase/ssr`.

## DB schema

- Siempre leer `prompt.txt` antes de decisiones arquitectónicas.
- Los nombres de columna en el código deben coincidir exactamente con los de Supabase (definidos en `prompt.txt`).
- RLS y triggers ya existen en el proyecto de Supabase; el código solo consume/inserta.
