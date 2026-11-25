<!-- AI 2026-11-25: lista sekretów wdrożenia huba i pieczęci - same nazwy, bez wartości -->
# Sekrety wdrożenia (`secrets/`, poza repozytorium)

| plik | zawartość | właściciel / prawa |
|---|---|---|
| `secrets/hub/edr/edr_key.pem`, `edr_cert.pem` | klucz i certyfikat systemu e-Doręczeń | uid 1000, `0400` |
| `secrets/seal/valkey_seal_password` | hasło użytkownika `seal` w Valkey pieczęci | uid 10001, `0600` |
| `secrets/seal/valkey_hub_password` | hasło użytkownika `hub` w Valkey pieczęci | hub (uid 1000), `0600` |
| `secrets/seal/seal_pkcs11_pin`, `seal_pkcs11_so_pin` | PIN-y tokenu SoftHSM2 | uid 10001, `0600` |
| `secrets/seal/users.acl` | wynik `galwork-seal/scripts/make-acl.sh` (skróty SHA-256) | `0644` |
| `secrets/seal/chain.pem` | certyfikat pieczęci, potem certyfikaty pośrednie | `0644` |
| `secrets/npmrc` | token rejestru npm `code.galicea.org` (budowa obrazów) | `0600` |

Generowanie haseł i ACL: rozdział „Wdrożenie z SoftHSM2” w `galwork-seal/README.md`.
Uwaga: każdy plik montowany przez compose musi istnieć **przed** `docker compose up`.
Inaczej Docker utworzy w jego miejscu pusty katalog.
