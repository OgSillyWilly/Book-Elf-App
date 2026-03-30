#!/bin/bash

# Batch fetch covers for books in cabinets 9 and 10
echo "🎨 Batch Cover Fetcher voor Kast 9 & 10"
echo "========================================"
echo ""

API_URL="http://127.0.0.1:8000/api"
GOOGLE_BOOKS_API="https://www.googleapis.com/books/v1/volumes"

# Get all books from cabinets 9 and 10 without covers
echo "📚 Boeken ophalen uit kasten 9 en 10..."
books=$(curl -s "$API_URL/books" | jq -c '[.[] | select((.cabinet == "9" or .cabinet == "10") and (.cover_url == null or .cover_url == ""))] | .[]')

total=$(echo "$books" | wc -l | xargs)
echo "Gevonden: $total boeken zonder cover"
echo ""

count=0
success=0
failed=0

# Process each book
echo "$books" | while IFS= read -r book; do
    count=$((count + 1))
    
    id=$(echo "$book" | jq -r '.id')
    title=$(echo "$book" | jq -r '.title')
    author=$(echo "$book" | jq -r '.author')
    cabinet=$(echo "$book" | jq -r '.cabinet')
    
    echo "[$count/$total] Verwerken: $title - $author (Kast $cabinet)"
    
    # URL encode the query
    query=$(echo "intitle:$title inauthor:$author" | jq -sRr @uri)
    
    # Search Google Books
    response=$(curl -s "$GOOGLE_BOOKS_API?q=$query&maxResults=1")
    
    # Extract cover URL
    cover_url=$(echo "$response" | jq -r '.items[0].volumeInfo.imageLinks.thumbnail // .items[0].volumeInfo.imageLinks.smallThumbnail // empty' 2>/dev/null)
    
    if [ ! -z "$cover_url" ] && [ "$cover_url" != "null" ]; then
        # Update book with cover URL
        update_data=$(echo "$book" | jq --arg cover "$cover_url" '. + {cover_url: $cover}')
        
        update_response=$(curl -s -X PUT "$API_URL/books/$id" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$update_data")
        
        if [ $? -eq 0 ]; then
            echo "  ✅ Cover gevonden en opgeslagen"
            success=$((success + 1))
        else
            echo "  ❌ Fout bij opslaan"
            failed=$((failed + 1))
        fi
    else
        echo "  ⚠️  Geen cover gevonden in Google Books"
        failed=$((failed + 1))
    fi
    
    # Small delay to avoid rate limiting
    sleep 0.3
    echo ""
done

echo "========================================"
echo "✨ Klaar!"
echo "Succesvol: $success"
echo "Niet gevonden: $failed"
echo "Totaal: $total"
