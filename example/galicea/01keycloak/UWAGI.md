<!-- 2026-11-25: uwagi z wdrożenia Keycloak (uwaga.txt, users.txt) -->
# Keycloak – uwagi z wdrożenia (realm `galicea`)

## Klient `galwork` (fronty Next.js)

    dla galwork: Client authentication -> OFF (klient publiczny, logowanie z przeglądarki z PKCE).
    Advanced -> Proof Key for Code Exchange Code Challenge Method = S256.
    Nie włączać Client authentication - front nie wysyła sekretu, token endpoint zwraca wtedy 401 (unauthorized_client).
    
    Hub weryfikuje tokeny frontu: KEYCLOAK_CLIENT_ID w .env huba musi być = galwork
    (hub porównuje claim azp z client_id - inaczej "Invalid token client (azp)").
    Hub nie używa sekretu klienta galwork (weryfikacja przez certs_url).
    Jeśli potrzebny klient z sekretem (serwer-serwer, np. hub-konto z client_credentials),
    założyć go jako osobnego klienta.

## Użytkownicy

    user musi mieć role: read-token, view-consent

## Do zaostrzenia przed produkcją

Eksport `client-import-galwork.json` ma `redirectUris`, `webOrigins` i `post.logout.redirect.uris` = `*`.
Na produkcji wpisz jawnie adresy frontów (centrum, akademia, pm, arena), np. `https://pm.galicea.org/*`.

## Ochrona przed zgadywaniem haseł

<!-- 2026-11-25: włączenie brute force detection (TODO_bezpieczenstwo 2.2) -->
Eksport realmu ma `bruteForceProtected: true`, blokadę **tymczasową** (`permanentLockout: false`)
po 10 nieudanych próbach (`failureFactor`), czas blokady rosnący o 60 s, maksymalnie 15 min.
Blokada trwała pozwoliłaby każdemu celowo zablokować cudze konto.

Na działającym serwerze (eksport nie zmienia istniejącego realmu):

    kcadm.sh config credentials --server https://login.galicea.org --realm master --user <admin>
    kcadm.sh update realms/galicea -s bruteForceProtected=true -s permanentLockout=false \
        -s failureFactor=10 -s waitIncrementSeconds=60 -s maxFailureWaitSeconds=900

albo w konsoli: *Realm settings → Security defenses → Brute force detection* (tryb *Lockout temporarily*).
