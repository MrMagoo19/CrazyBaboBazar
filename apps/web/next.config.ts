import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  // Pilot builds use a separate artifact directory so `npm start` can never
  // accidentally serve a locally built Pilot bundle as the normal app.
  distDir: process.env.CBB_TARGET_ENV === 'pilot' ? '.next-pilot' : '.next',
  images: {
    unoptimized: true,
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
      {
        protocol: 'https',
        hostname: 'm.media-amazon.com',
      },
      {
        protocol: 'https',
        hostname: 'www.40yards.de',
        pathname: '/cdn/shop/**',
      },
    ],
  },
}

export default nextConfig
