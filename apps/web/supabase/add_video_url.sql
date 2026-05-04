-- Migration: video_url Spalte für Produktvideos (YouTube embed URL)
ALTER TABLE products ADD COLUMN IF NOT EXISTS video_url text;
