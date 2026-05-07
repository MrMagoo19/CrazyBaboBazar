import { createClient } from '@supabase/supabase-js'
const sb = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!)
async function main() {
  const { data } = await sb.from('products').select('slug, name, description, tagline').eq('is_published', true)
  const short = (data ?? []).filter(p => (p.description ?? '').length < 150)
  console.log('Total:', data?.length, '| Short (<150 chars):', short.length)
  short.forEach(p => console.log(` ${(p.description??'').length}c | ${p.name}`))
}
main()
