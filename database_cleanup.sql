-- Database Cleanup Script voor Bookshelf App
-- Fix dubbel geproxied cover URLs

-- Stap 1: Bekijk welke boeken dubbel geproxied URLs hebben
SELECT id, title, cover_url 
FROM books 
WHERE cover_url LIKE '%image-proxy?url=http%image-proxy%'
ORDER BY id;

-- Stap 2: Update dubbel geproxied URLs (BACKUP EERST!)
-- Deze query haalt de originele Google Books URL eruit
UPDATE books 
SET cover_url = SUBSTRING_INDEX(
    SUBSTRING_INDEX(cover_url, 'image-proxy?url=', -1),
    '&',
    1
)
WHERE cover_url LIKE '%image-proxy?url=%image-proxy%';

-- Stap 3: Verifieer de fix
SELECT id, title, cover_url 
FROM books 
WHERE cover_url LIKE '%google.com%'
ORDER BY id
LIMIT 10;

-- Stap 4: Check voor nog meer issues
SELECT id, title, cover_url 
FROM books 
WHERE cover_url IS NOT NULL 
  AND cover_url != ''
  AND cover_url NOT LIKE 'http%'
ORDER BY id;

-- Optional: Backup maken voordat je deze queries uitvoert
-- mysqldump -u your_user -p your_database books > books_backup.sql
