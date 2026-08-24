import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const PILOT_SUPABASE_URL = 'https://nmzuycveumyfvtxdcnuc.supabase.co'
const mode = process.argv[2]
const extraArgs = process.argv.slice(3)
const configuredUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const configuredKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim()

function isPublishableKey(key) {
  if (key.startsWith('sb_publishable_')) return true
  if (key.startsWith('sb_secret_')) return false

  const segments = key.split('.')
  if (segments.length !== 3) return false

  try {
    const payload = JSON.parse(Buffer.from(segments[1], 'base64url').toString('utf8'))
    return payload.role === 'anon'
  } catch {
    return false
  }
}

if (mode !== 'dev' && mode !== 'build' && mode !== 'start' && mode !== 'check') {
  console.error('Pilot-Start abgebrochen: erlaubt sind nur "check", "dev", "build" und "start".')
  process.exit(1)
}

if (configuredUrl !== PILOT_SUPABASE_URL) {
  console.error('Pilot-Start abgebrochen: NEXT_PUBLIC_SUPABASE_URL zeigt nicht auf das freigegebene Pilot-Projekt.')
  process.exit(1)
}

if (!configuredKey || !isPublishableKey(configuredKey)) {
  console.error('Pilot-Start abgebrochen: In der aktiven Umgebung fehlt ein gültiger Publishable-/Anon-Key. Secret- und Service-Role-Keys sind nicht erlaubt.')
  process.exit(1)
}

if (mode === 'check') {
  console.log('Pilot-Konfiguration gültig: Zielprojekt nmzuycveumyfvtxdcnuc, Publishable-/Anon-Key erkannt.')
  process.exit(0)
}

const nextBin = fileURLToPath(new URL('../node_modules/next/dist/bin/next', import.meta.url))
const result = spawnSync(process.execPath, [nextBin, mode, ...extraArgs], {
  // Geprueft wurde der getrimmte Key — genau der muss auch an Next weitergereicht
  // werden. Sonst validiert der Guard "sb_publishable_x", waehrend Supabase
  // "sb_publishable_x\n" bekommt und jede Anfrage mit 401 scheitert.
  env: { ...process.env, NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: configuredKey, CBB_TARGET_ENV: 'pilot' },
  stdio: 'inherit',
})

if (result.error) {
  console.error(`Pilot-${mode} konnte nicht gestartet werden: ${result.error.message}`)
  process.exit(1)
}

process.exit(result.status ?? 1)
