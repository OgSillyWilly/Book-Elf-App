#!/bin/bash

API_URL="http://127.0.0.1:8000/api"
GOOGLE_BOOKS_API="https://www.googleapis.com/books/v1/volumes"

echo "🗑️  Stap 1: Duplicaten verwijderen uit kast 10"
echo "=============================================="

# Get all duplicate book IDs from cabinet 10
duplicate_ids=$(curl -s "$API_URL/books" | jq -r '[.[] | select(.cabinet == "9" or .cabinet == "10")] | group_by(.title + "|" + .author) | map(select(length == 2 and ([.[] | .cabinet] | unique | length == 2)) | map(select(.cabinet == "10")) | .[0].id) | .[]')

count=0
total=$(echo "$duplicate_ids" | wc -l | xargs)
echo "Aantal duplicaten te verwijderen: $total"
echo ""

# Delete each duplicate
for id in $duplicate_ids; do
    count=$((count + 1))
    echo "[$count/$total] Verwijderen boek ID: $id"
    curl -s -X DELETE "$API_URL/books/$id" > /dev/null
done

echo ""
echo "✅ Duplicaten verwijderd!"
echo ""
echo "📚 Stap 2: Nieuwe kinderboeken toevoegen aan kast 10"
echo "====================================================="
echo ""

# List of popular Dutch and international children's books
# These are books that are likely NOT in the collection yet
declare -a new_books=(
    "Het Wilde Woud|Colin Meloy"
    "Kruistocht in Spijkerbroek|Thea Beckman"
    "De Tweeling|Lieve Baeten"
    "Waanzinnige Woensdag|Roald Dahl"
    "Het Kannibalen Eiland|Jacques Vriens"
    "Knabbel en Babbel|Paul van Loon"
    "Het Mysterie van de Zwarte Kat|Paul Biegel"
    "De Kameleon-serie|Hotze de Roos"
    "Pluk van de Petteflet|Annie M.G. Schmidt"
    "De Kinderen van Moeder Aarde|Thea Beckman"
    "Floris en het Gezoem in de Motor|Gerrit de Vries"
    "Het Paard en de Jongen|C.S. Lewis"
    "De Laatste Strijd|C.S. Lewis"
    "Het Betoverde Land achter de Kleerkast|C.S. Lewis"
    "Koning Peter en Koning Caspian|C.S. Lewis"
    "De Zilveren Stoel|C.S. Lewis"
    "Het Paard Humpie en de Jongen|C.S. Lewis"
    "De Reis van de Dageraad|C.S. Lewis"
    "Floris V|Thea Beckman"
    "Het Huis van de Dood|Rindert Kromhout"
    "De Zwarte Zwanen|Jackie French Koller"
    "Dansen voor het Geld|Sjoerd Kuyper"
    "De Vloek van de Woestijn|Jan Terlouw"
    "Oorlog van de Knopen|Rindert Kromhout"
    "De Tasjesdief|Henk Hardeman"
    "Vrienden voor het Leven|Henk Hardeman"
    "Spijt|Carry Slee"
    "Kappen!|Carry Slee"
    "Razend|Carry Slee"
    "Pijnstillers|Carry Slee"
    "Afblijven|Carry Slee"
    "Een Doodgewoon Gezin|Carry Slee"
    "Timboektoe|Paul Biegel"
    "Het Sleutelkruid|Tonke Dragt"
    "De Zevensprong|Tonke Dragt"
    "Torenhoog en Mijlen breed|Tonke Dragt"
    "Geheimen van het Wilde Woud|Tonke Dragt"
    "Dido en Pa|Tonke Dragt"
    "Het Goudsmidsmeisje|Lydia Rood"
    "Het Regent Gehaktballen|Judi Barrett"
    "Het Wonderbaarlijke Voorval met de Hond in de Nacht|Mark Haddon"
    "De Stille Kracht|Louis Couperus"
    "Max en de Maximonsters|Maurice Sendak"
    "De Gekke Keet|Annie M.G. Schmidt"
    "Het Schaap Schapenijs|Annie M.G. Schmidt"
    "Tow-Truck Pluck|Annie M.G. Schmidt"
    "Jip en Janneke|Annie M.G. Schmidt"
    "Minoes|Annie M.G. Schmidt"
    "De A van Abeltje|Annie M.G. Schmidt"
    "Madelief|Guus Kuijer"
    "Het Boek van Alle Dingen|Guus Kuijer"
    "Polleke|Guus Kuijer"
    "Voor Altijd Samen, Amen|Guus Kuijer"
    "Krassen in het Tafelblad|Els Pelgrom"
    "De Kinderen van het Achtste Woud|Els Pelgrom"
    "Het Eiland Klaasje|Ted van Lieshout"
    "Weg uit Afrika|Wanda Breuer"
    "Vrek in de Speeltuin|Dirk Weber"
    "De Meester-Spion|Anna Woltz"
    "Zilveren Klaassen|Anna Woltz"
    "Haaientanden|Anna Woltz"
    "Tunnels|Brian Williams"
    "Diepgang|Brian Williams"
    "Gevallen Engel|Roderick Gordon"
    "Het Spion van de Buurkant|Tonke Dragt"
    "Iep!|Paul van Loon"
    "Foeksia de Miniheks|Paul van Loon"
    "De Griezelvakantie|Paul van Loon"
    "De Griezelclub|Paul van Loon"
    "Dolfje Weerwolfje|Paul van Loon"
    "De Volle Maan|Paul van Loon"
    "Waggelmans|Thijs Goverde"
    "Villa Kakelbont|Thijs Goverde"
    "De Rattenvangers|Thijs Goverde"
    "De Vloek van Woestewolf|Thijs Goverde"
    "Het Raadsel Scherpzinnig|Thijs Goverde"
    "De Wet van Verdraaide Werelden|Thijs Goverde"
    "Robin Hood|Michael Morpurgo"
    "Oorlogspaard|Michael Morpurgo"
    "Kleintje Kapitein|Michael Morpurgo"
    "Kaspar|Michael Morpurgo"
    "De Gok|Paul Kustermans"
    "De Verborgen Grot|Dick Laan"
    "De Groene Kei|Dick Laan"
    "Het Gouden Slot|Dick Laan"
    "De Verdwenen Rode Laan|Dick Laan"
    "De Zwarte Rots|Dick Laan"
    "Stop de Trein|Gerrit Jan Zwier"
    "Flauw|Gerrit Jan Zwier"
    "De Marathon|Joke van Leeuwen"
    "Iep, Oep of Moes?|Joke van Leeuwen"
    "De Vliegeraar|Joke van Leeuwen"
    "De Club der Mislukkingen|Els Beerten"
    "De Wraak van Woeste Willem|Els Beerten"
    "Vamp de Misdaad|Els Beerten"
    "Liefdesverdriet met Frambozenmayonaise|Tais Teng"
    "Brandenrijders|Tais Teng"
    "Geheim Agent voor een Dag|Tais Teng"
    "Papieren Paradijs|Tais Teng"
    "Op de Rode Loper|Tais Teng"
    "Schaduwvlinders|Veronica Hazelhoff"
    "Engeleneiland|Veronica Hazelhoff"
    "Oorlogsgeheimen|Jacques Vriens"
    "Ren je Rot|Jacques Vriens"
    "Tommy en de Parelvisser|Jacques Vriens"
    "Het Zoveelste Oor|Jacques Vriens"
    "De Kakkerlak uit Keulen|Henk Hardeman"
    "De Kinderen van het Spook|Henk Hardeman"
    "Het Spookhuis|Henk Hardeman"
    "De Reusachtige Krokodil|Roald Dahl"
    "De Grootste Gemenerik van de Hele Wereld|Roald Dahl"
    "De Wonderlijke Apotheek van Meneer Pingeling|Roald Dahl"
    "De Giraffe de Pelikaan en Ik|Roald Dahl"
    "Sjakie en de Grote Glazen Lift|Roald Dahl"
    "De Fantastische Meneer Vos|Roald Dahl"
    "Klaus|Eoin Colfer"
    "Artemis Fowl|Eoin Colfer"
    "Het Arctisch Incident|Eoin Colfer"
    "Alex Rider Stormbreaker|Anthony Horowitz"
    "Percy Jackson de Bliksemdief|Rick Riordan"
    "Percy Jackson de Zee van Monsters|Rick Riordan"
    "Het Leven van een Loser|Jeff Kinney"
    "Het Leven van een Loser Rodrick is een Eikel|Jeff Kinney"
    "Het Leven van een Loser De Laatste Loodjes|Jeff Kinney"
    "Dik Trom|C.J. Kievit"
    "Dik Trom en Zijn Dorpsgenoten|C.J. Kieviet"
    "De Belevingen van Pietje Bell|Chris van Abkoude"
    "De Tocht naar Grootmoederland|Chris van Abkoude"
    "Alleen voor Jonge Jongens|Guus Kuijer"
    "We slapen nooit meer|Guus Kuijer"
    "Een Schitterend Gebrek|Arthur Japin"
    "De Grote Boze Wolf|Maranke Rinck"
    "De Soldaat en de Heks|Jan Terlouw"
    "De Koning van Katoren|Jan Terlouw"
    "Pjotr|Jan Terlouw"
    "Oorlogswinter|Jan Terlouw"
    "De Brief voor de Koning Vervolg|Tonke Dragt"
    "Het Geheim van de Wilde Woud|Tonke Dragt"
    "Torenhoog en Mijlenwijd|Tonke Dragt"
    "De Rode Ruiter|Tonke Dragt"
    "De Blauwe Maansteen|Tonke Dragt"
    "Het Gouden Sterrenvlies|Tonke Dragt"
    "Zwarte Zwanen Witte Zwanen|Tonke Dragt"
    "Ik Was Zestien in '45|Miep Diekmann"
    "De Kinderen uit het Dennenbos|Nienke van Hichtum"
    "Afke's Tiental|Nienke van Hichtum"
    "Kruimeltje|Chris van Abkoude"
    "Pietje Puk|Willy Schermelier"
    "De Pepernotenboom|Imme Dros"
    "De Kinderen van de Vogelwacht|Johan Brinkhoff"
    "Janneke en Gerton Trekken de Wereld In|N. van Schouwenburg"
    "Mijn Zusje is Een Vampier|Sienna Mercer"
    "De Club van Harde Werkers|Rindert Kromhout"
    "Hazenovermorgen|Rindert Kromhout"
    "Het Mysterie van de Wilde Zwie|Rindert Kromhout"
    "De Flessenduivel|Rindert Kromhout"
    "Kleine Ijsbeer|Hans de Beer"
    "Kleine Potlood|Thé Tjong-Khing"
    "Het Meisje met de Blauwe Trui|Gideon Samson"
    "Rotjoch|Gideon Samson"
    "Niks Voor Jan|Gideon Samson"
    "De Griezelsteen|Selma Noort"
    "De Griezeltrein|Selma Noort"
    "Wonderland|Dick Matena"
    "De Gouden Koets|Joke van Leeuwen"
    "Kaas|Willem Elsschot"
    "De Brief voor de Koning Musical|Tonke Dragt"
    "De Verschrikkelijke Twee|Philip Ardagh"
    "Pietje Pook en de Kat met de Grijns|Philip Ardagh"
    "Geheim Genootschap van Tovenaars|Lene Kaaberbol"
    "Het Boek zonder Nome|Anonymous"
    "Het Gouden Kompas|Philip Pullman"
    "Het Magische Mes|Philip Pullman"
    "Geit met Stip|Thijs Goverde"
    "Gebroken Beek Breuk|Thijs Goverde"
    "Het Sterrenlied|Dolf Verroen"
)

added=0
failed=0
needed=$total

for book_info in "${new_books[@]}"; do
    if [ $added -ge $needed ]; then
        break
    fi
    
    IFS='|' read -r title author <<< "$book_info"
    echo "[$((added + 1))/$needed] Zoeken: $title - $author"
    
    # Check if book already exists in collection
    exists=$(curl -s "$API_URL/books" | jq --arg title "$title" --arg author "$author" '[.[] | select(.title == $title and .author == $author)] | length')
    
    if [ "$exists" -gt 0 ]; then
        echo "  ⚠️  Boek bestaat al in collectie, overslaan"
        continue
    fi
    
    # Search Google Books
    query=$(echo "intitle:$title inauthor:$author" | jq -sRr @uri)
    response=$(curl -s "$GOOGLE_BOOKS_API?q=$query&maxResults=1")
    
    # Extract book info
    has_items=$(echo "$response" | jq '.totalItems // 0')
    
    if [ "$has_items" -gt 0 ]; then
        volume_info=$(echo "$response" | jq '.items[0].volumeInfo')
        
        isbn=$(echo "$volume_info" | jq -r '.industryIdentifiers[]? | select(.type == "ISBN_13" or .type == "ISBN_10") | .identifier' | head -1)
        cover_url=$(echo "$volume_info" | jq -r '.imageLinks.thumbnail // .imageLinks.smallThumbnail // ""')
        publisher=$(echo "$volume_info" | jq -r '.publisher // ""')
        pub_date=$(echo "$volume_info" | jq -r '.publishedDate // ""')
        retrieved_title=$(echo "$volume_info" | jq -r '.title // ""')
        retrieved_author=$(echo "$volume_info" | jq -r '.authors[0] // ""')
        
        # Use retrieved info if available, otherwise use search terms
        final_title="${retrieved_title:-$title}"
        final_author="${retrieved_author:-$author}"
        
        # Create book JSON
        book_json=$(jq -n \
            --arg title "$final_title" \
            --arg author "$final_author" \
            --arg isbn "$isbn" \
            --arg type "kinderboek" \
            --arg format "Hardcover" \
            --arg publisher "$publisher" \
            --arg pub_date "$pub_date" \
            --arg cover "$cover_url" \
            --arg cabinet "10" \
            '{
                title: $title,
                author: $author,
                isbn: $isbn,
                type: $type,
                format: $format,
                publisher: $publisher,
                publication_date: $pub_date,
                cover_url: $cover,
                has_slipcase: false,
                has_dustjacket: true,
                cabinet: $cabinet,
                shelf: "",
                position: null,
                is_read: false,
                start_date: null,
                end_date: null,
                year_read: null,
                rating: null
            }')
        
        # Add book to collection
        result=$(curl -s -X POST "$API_URL/books" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$book_json")
        
        if echo "$result" | jq -e '.id' > /dev/null 2>&1; then
            echo "  ✅ Toegevoegd: $final_title"
            echo "     ISBN: ${isbn:-geen}"
            echo "     Cover: ${cover_url:+ja}"
            added=$((added + 1))
        else
            echo "  ❌ Fout bij toevoegen"
            failed=$((failed + 1))
        fi
    else
        echo "  ⚠️  Niet gevonden in Google Books"
        failed=$((failed + 1))
    fi
    
    # Small delay to avoid rate limiting
    sleep 0.4
    echo ""
done

echo "============================================="
echo "🎉 Klaar!"
echo ""
echo "Verwijderd: $total duplicaten uit kast 10"
echo "Toegevoegd: $added nieuwe boeken"
echo "Niet gevonden: $failed boeken"
echo ""
echo "Kast 10 bevat nu unieke boeken met covers en ISBN!"
