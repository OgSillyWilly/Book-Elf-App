#!/bin/bash

echo "🌟 Random ratings toevoegen aan gelezen boeken zonder beoordeling..."
echo "================================================================"
echo ""

API_URL="http://192.168.0.179:8000/api"

# Haal ALLE boeken op (alle pagina's)
echo "📚 Alle boeken ophalen..."
all_books_json="[]"
page=1
total_pages=0

while true; do
    echo -n "  Pagina $page laden... "
    response=$(curl -s "${API_URL}/books?page=$page&per_page=50")
    
    # Check if response is valid JSON
    if ! echo "$response" | jq empty 2>/dev/null; then
        echo "❌ Fout bij ophalen"
        break
    fi
    
    # Get pagination info
    current_page=$(echo "$response" | jq -r '.current_page')
    last_page=$(echo "$response" | jq -r '.last_page')
    
    if [ "$total_pages" -eq 0 ]; then
        total_pages=$last_page
        echo "($total_pages pagina's totaal)"
    else
        echo "✅"
    fi
    
    # Append this page's data
    page_data=$(echo "$response" | jq -c '.data[]')
    if [ ! -z "$page_data" ]; then
        all_books_json=$(echo "$all_books_json" | jq ". + [$(echo "$response" | jq -c '.data[]' | tr '\n' ',' | sed 's/,$//')]")
    fi
    
    # Check if we've reached the last page
    if [ "$current_page" -ge "$last_page" ]; then
        break
    fi
    
    page=$((page + 1))
done

echo ""
echo "📊 Filteren op gelezen boeken zonder rating..."

# Filter: is_read moet true zijn EN rating null of 0
books_to_update=$(echo "$all_books_json" | jq -r '.[] | select(.is_read == true or .is_read == 1 or .is_read == "1") | select(.rating == null or .rating == "null" or .rating == 0 or .rating == "0") | "\(.id)|\(.title)|\(.author)"')

if [ -z "$books_to_update" ]; then
    echo "✅ Alle gelezen boeken hebben al een beoordeling!"
    exit 0
fi

count=$(echo "$books_to_update" | wc -l | tr -d ' ')
echo "📊 Gevonden: $count gelezen boeken zonder beoordeling"
echo ""
echo "🎲 Willekeurige ratings (1-5 sterren) toewijzen..."
echo ""

updated=0
failed=0

while IFS='|' read -r book_id title author; do
    # Genereer random rating tussen 1 en 5
    rating=$((RANDOM % 5 + 1))
    
    # Truncate title voor display
    short_title=$(echo "$title" | cut -c1-40)
    if [ ${#title} -gt 40 ]; then
        short_title="${short_title}..."
    fi
    
    echo -n "ID $book_id: \"$short_title\" - $rating⭐ ... "
    
    # Haal eerst het volledige boek op
    book_json=$(curl -s "${API_URL}/books/${book_id}")
    
    if ! echo "$book_json" | jq empty 2>/dev/null; then
        echo "❌ (kan boek niet ophalen)"
        ((failed++))
        continue
    fi
    
    # Update alleen de rating in de bestaande data
    updated_book=$(echo "$book_json" | jq ".rating = $rating")
    
    # PUT de volledige update
    result=$(curl -s -X PUT "${API_URL}/books/${book_id}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$updated_book")
    
    if echo "$result" | jq -e '.id' >/dev/null 2>&1; then
        echo "✅"
        ((updated++))
    else
        echo "❌ $(echo "$result" | jq -r '.message // .error // "unknown error"' 2>/dev/null || echo "unknown error")"
        ((failed++))
    fi
    
    # Kleine pauze om server niet te overbelasten
    sleep 0.05
done <<< "$books_to_update"

echo ""
echo "================================================================"
echo "✅ Voltooid!"
echo "   - Bijgewerkt: $updated boeken"
if [ $failed -gt 0 ]; then
    echo "   - Mislukt: $failed boeken"
fi
echo ""
