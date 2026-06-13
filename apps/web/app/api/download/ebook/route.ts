export const runtime = 'edge'

export async function GET() {
  const res = await fetch(
    process.env.EBOOK_URL!,
    { next: { revalidate: 0 } }
  )

  if (!res.ok) {
    return new Response('Not found', { status: 404 })
  }

  return new Response(res.body, {
    headers: {
      'Content-Type': 'application/pdf',
      'Content-Disposition': 'attachment; filename="Jarvis-mit-Claude-Ebook.pdf"',
      'Cache-Control': 'no-store',
    },
  })
}
