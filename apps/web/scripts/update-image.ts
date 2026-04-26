import { createClient } from '@supabase/supabase-js'

const sb = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

async function main() {
  const { error } = await sb
    .from('products')
    .update({ is_published: true })
    .eq('slug', 'tradercat-i-teach-muggles-jutebeutel-lehrer')
  console.log(error ?? '✅ Produkt ist jetzt live')
}

main()
