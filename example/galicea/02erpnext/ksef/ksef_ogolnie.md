## KSeF - Krajowy System e-Faktur

Do komunikacji z KSeF wymagany jest certyfikat wystawiony prze kwalifikowanego dostawcy z EUTL (EU Trusted List) (https://esignature.ec.europa.eu/efda/tl-browser/).
Do testów możemy użyć certyfikatu `self-signed`, ale **uwaga** - nie możemy w ten sposób testować transmisji, gdyż KSeF taki certyfikat odrzuci.
Możemy natomiast użyć na przykład pieczęci firmowej.

Kwalifikowana pieczęć powinna mieć w polu **Subject** wartości OID:

- 2.5.4.10: organizationName
- 2.5.4.97: organizationIdentifier
- 2.5.4.3:  commonName
- 2.5.4.6:  countryName

Kluczowym jest `organizationIdentifier`, który musi zawierać numer VAT w formacie: VATPL-1234567890.
Odpowiedni certyfikat testowy (self-signed) możemy wygenerować na podstawie pliku cnf o strukturze:
```
[ req ]
default_bits = 3072
distinguished_name = req_distinguished_name
string_mask = utf8only
req_extensions = v3_req
oid_section = new_oids

[ req_distinguished_name ]
C = PL
O = Kowalski sp. z o.o
CN = Kowalski sp. z o.o

[new_oids]
organizationIdentifier = 2.5.4.97

[v3_req]
```
Przykładowe polecenia generowania certyfikatu:
```bash
# twórz klucz prywatny
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out key.pem
# twórz csr
openssl req -new -key key.pem -out req.csr \
  -config openssl-ksef.cnf \
  -subj "/C=PL/O=Kowalski/CN=Kowalski/organizationIdentifier=VATPL-1234567890" \
  -addext "keyUsage=digitalSignature" \
  -addext "extendedKeyUsage=clientAuth"
# cert. samopodpisany
openssl x509 -req -in req.csr -signkey key.pem -days 365 \
  -out cert.pem -extensions v3_req -extfile openssl-ksef.cnf
# eksport do pfx
openssl pkcs12 -export -inkey key.pem -in cert.pem \
  -out cert.pfx -passout pass:pass123
```
Ten certyfikat (i każdy inny) możemy przetestować poleceniem:
```bash
openssl pkcs12 -in $(pwd)/cert.pfx -nodes -passin pass:"pass123"\
 | openssl x509 -noout -subject

```

### Algorytm uwierzytelniania certyfikatem w KSeF 2.0.

**1. Pobieranie challenge**
Funkcja API `POST: /api/v2/auth/challenge` zwraca:
```
challenge_response = {
    challenge:   Unikalny challenge. 
    timestamp: Czas wygenerowania challenge-a.
}
 
```

**2. Przygotowanie zapytania autoryzacyjnego w postaci XML**

```xml
<?xml version="1.0" encoding="utf-8"?>
<AuthTokenRequest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
   xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
   xmlns="http://ksef.mf.gov.pl/auth/token/2.0">
    <Challenge>{challenge}</Challenge>
    <ContextIdentifier>
        <Nip>{identifier_value}</Nip>
    </ContextIdentifier>
    <SubjectIdentifierType>certificateSubject</SubjectIdentifierType>
</AuthTokenRequest>"""
```
Gdzie:
```
  challenge=challenge_response.challenge,
  identifier_type="Nip",
  identifier_value=<nip>
```

**3. Podpisanie XML podpisem XAdES**

```xml
<ds:Signature Id="Signature" xmlns:ds="{DS_NS}">
  <ds:SignedInfo>
    <ds:CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
    <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
    <ds:Reference URI="">
      <ds:Transforms>
        <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
        <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
      </ds:Transforms>
      <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
      <ds:DigestValue></ds:DigestValue>
    </ds:Reference>
    <ds:Reference Type="{SIGNED_PROPERTIES_TYPE}" URI="#SignedProperties">
      <ds:Transforms>
        <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
      </ds:Transforms>
      <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
      <ds:DigestValue></ds:DigestValue>
    </ds:Reference>
  </ds:SignedInfo>
  <ds:SignatureValue></ds:SignatureValue>
  <ds:KeyInfo>
    <ds:X509Data>
      <ds:X509Certificate></ds:X509Certificate>
    </ds:X509Data>
  </ds:KeyInfo>
</ds:Signature>
```

Gdzie:
```
DS_NS = "http://www.w3.org/2000/09/xmldsig#"
XADES_NS = "http://uri.etsi.org/01903/v1.3.2#"
SIGNED_PROPERTIES_TYPE = "http://uri.etsi.org/01903#SignedProperties"
```

Do węzła `ds:Signature` dodajemy  XAdES QualifyingProperties

```xml
<xades:QualifyingProperties Target="#{signature_id}" xmlns:xades="{XADES_NS}" xmlns:ds="{DS_NS}">
  <xades:SignedProperties Id="{signed_props_id}">
    <xades:SignedSignatureProperties>
      <xades:SigningTime>{signing_time}</xades:SigningTime>
      <xades:SigningCertificate>
        <xades:Cert>
          <xades:CertDigest>
            <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
            <ds:DigestValue>{digest_b64}</ds:DigestValue>
          </xades:CertDigest>
          <xades:IssuerSerial>
            <ds:X509IssuerName>{issuer_name}</ds:X509IssuerName>
            <ds:X509SerialNumber>{serial_number}</ds:X509SerialNumber>
          </xades:IssuerSerial>
        </xades:Cert>
      </xades:SigningCertificate>
    </xades:SignedSignatureProperties>
  </xades:SignedProperties>
</xades:QualifyingProperties>
```
Wartości pól w powyższym szablonie ustawiamy na podstawie certyfikatu:

```py
  cert_der = cert.public_bytes(serialization.Encoding.DER)
  cert_digest = hashes.Hash(hashes.SHA256())
  cert_digest.update(cert_der)
  digest_b64 = base64.b64encode(cert_digest.finalize()).decode("ascii")

  issuer_name = cert.issuer.rfc4514_string()
  serial_number = str(cert.serial_number)
  signing_time = datetime.now(timezone.utc).isoformat()
```
Tak przygotowany plik możemy podpisać programem xmlsec1:

```
xmlsec1 --sign --output signed.xml --pkcs12 cert.pfx --pwd pass123 input.xml 
```

**4. Wysyłamy podpisany XML do KSeF**

Polceniem POST na adres `/api/v2/auth/xades-signature` wysyłamy podpisany XML. W odpowiedzi uzyskujemy numer referencyjny oraz token autentykacji:
```
referenceNumber=response.referenceNumber
auth_token = response.authenticationToken.token
```
Sprawdzamy w pętli status operacji, aż do uzyskania statusu 200:
```py
while True:
  status_response = ksef_client.auth_status(referenceNumber, auth_token)
  if status_response.status.code == 200:
    break
  elif status_response.status.code >= 400:
    print(f"Uwierzytelnienie nie powiodło się. Powód: {status_response.status.description}")
    return None    
  time.sleep(2)
```
Funkcja `ksef_client.auth_status` wykonuje zapytanie get na adres `/api/v2/auth/{reference_number}`, przekazując token w nagłówku, jako `Authorization: Bearer {auth_token}`.

**5. Zamieniamy token autoryzacji na tokeny dostępowe**
Funkcja `redeem_token` wymaga tylko `auth_token`, numer referencyjny jest w tokenie:
```
tokens = ksef_client.redeem_token(auth_token)
```
Token autoryzacji jest jak poprzednio umieszczany w nagłówku. Tym razem wykonywane jest zapytanie POST na adres `/api/v2/auth/token/redeem`. W odpowiedzi uzyskujemy JSON z dwoma polami:
```
  accessToken:  Token dostępu
  refreshToken: Token odświeżenia
```
Każdy z nich ma strukturę:
```
  token: str # Token w formacie JWT.
  validUntil: datetime # termin ważności
```

### Aplikacja testowa w C#

Bardzo cennym źródłem informacji jest oficjalny projekt na portalu github: [https://github.com/CIRFMF/ksef-client-csharp.git](https://github.com/CIRFMF/ksef-client-csharp.git).
Wymaga on instalacji biblioteki .NET Microsoftu w wersji 9.
Jeśli testujesz program w systemie Linux, może zachodzić potrzeba pobrania jej z portalu Microsoft (jeśli dystrybucja Linux jej nie zawiera):
```bash
wget https://dotnetcli.azureedge.net/dotnet/Sdk/9.0.100/dotnet-sdk-9.0.100-linux-x64.tar.gz
sudo mkdir -p /usr/share/dotnet
sudo tar zxf dotnet-sdk-9.0.100-linux-x64.tar.gz -C /usr/share/dotnet
echo 'export PATH=$PATH:/usr/share/dotnet' | sudo tee -a /etc/profile
source /etc/profile
dotnet --version
```
Uruchomienie testu autoryzacji:

```bash
cd $(pwd)/ksef-client-csharp/KSeF.Client.Tests.CertTestApp
source /etc/profile
dotnet run --framework net9.0
```

### Wysyłanie faktur

Faktury są szyfrowane przy pomocy szyfrowania symetrycznego. Do tego celu musimy pobrać klucz publiczny KSeF oznaczony jako `SymmetricKeyEncryption`. Klucze publiczne są dostępne pod adresem `/api/v2/security/public-key-certificates` (nie jest wymagane uwierzytelnienie). 
Wysyłanie faktur odbywa się w obrębie sesji interaktywnej, albo w sposób wsadowy.
Jeśli chcemy zainicjować sesję, musimy przygotować klucz szyfrowania symstrycznego (losowe 32 bajty) oraz wektor IV (losowe 16 bajtów), na podstawie których tworzymy formularz zapytania:

```python
# symmetric_key - nasz losowy klucz
# iv - losowy wektor iv
public_key = RSA.import_key(public_key_pem) # public_key_pem - klucz KSeF
cipher_rsa = PKCS1_OAEP.new(public_key, hashAlgo=SHA256) 
encrypted_key = cipher_rsa.encrypt(symmetric_key) 
encryption_info = EncryptionInfo(
    encryptedSymmetricKey=base64.b64encode(encrypted_key).decode('ascii'),
    initializationVector=base64.b64encode(iv).decode('ascii')
  )
# Dla KSeF 2.0 wymagane jest: systemCode="FA (2)"
session_request = OpenOnlineSessionRequest(
    formCode=FormCode(systemCode="FA (2)", schemaVersion="1-0E", value="FA"),
    encryption=encryption_info
)
```
Gdzie `OpenOnlineSessionRequest` oraz `EncryptionInfo` to struktury pochodzące z modelu (OpenAPI) udostępnianego przez KSeF.

**Otwarcie sesji** następuje poprzez zapytanie POST z danymi z powyżej przygotowanej struktury (`session_request`) na adres `/api/v2/sessions/online`.
W odpowiedzi dostajemy numer referencyjny sesji:
```python
session_ref = response.referenceNumber
```

**Wysyłanie faktury** wykonujemy poleceniem POST na adres `/api/v2/sessions/online/{session_ref}/invoices`.
Dane zapytania zawierają strukturę, której przygotowanie opisują poniższe funkcje:
```python
def calculate_invoice_hash(xml_content: bytes) -> str:
  # Oblicza hash SHA256 faktury w formacie Base64
  hash_obj = hashlib.sha256(xml_content)
  return base64.b64encode(hash_obj.digest()).decode('ascii')

def prepare_invoice_for_sending(
    xml_content: bytes,
    symmetric_key: bytes,
    initialization_vector: bytes
) -> tuple[bytes, str, str]:
  # Przygotowuje fakturę do wysłania - szyfrowanie AES-256-CBC 
  original_hash = calculate_invoice_hash(xml_content)
  cipher = AES.new(symmetric_key, AES.MODE_CBC, initialization_vector)
  padded_data = pad(xml_content, AES.block_size)
  encrypted_content = cipher.encrypt(padded_data)
  encrypted_hash = calculate_invoice_hash(encrypted_content)
  return encrypted_content, original_hash, encrypted_hash

def create_send_invoice_request(
    xml_content: bytes,
    encrypted_xml_content: bytes,
    encryption_info: EncryptionInfo,
    offline_mode: bool = False,
    hash_of_corrected_invoice: Optional[str] = None
) -> SendInvoiceRequest:
  # Tworzy obiekt SendInvoiceRequest z XML faktury zgodnie z KSeF 2.0

  original_hash = hashlib.sha256(xml_content)
  original_hash_value = base64.b64encode(original_hash.digest()).decode('ascii')

  encrypted_hash = hashlib.sha256(encrypted_xml_content)
  encrypted_hash_value = base64.b64encode(encrypted_hash.digest()).decode('ascii')

  return SendInvoiceRequest(
    invoiceHash=original_hash_value,
    invoiceSize=len(xml_content),
    encryptedInvoiceHash=encrypted_hash_value,
    encryptedInvoiceSize=len(encrypted_xml_content),
    encryptedInvoiceContent=base64.b64encode(encrypted_xml_content).decode('ascii'),
    offlineMode=offline_mode,
    hashOfCorrectedInvoice=hash_of_corrected_invoice
  )

encrypted_content = prepare_invoice_for_sending(invoice_data, symmetric_key, iv)
send_request = create_send_invoice_request(
    xml_content=invoice_data,
    encrypted_xml_content=encrypted_content,
    encryption_info=None,
    offline_mode=False
)
```
Struktura `SendInvoiceRequest` pochodzi z modelu OpenAPI udostępnionego przez KSef [https://ksef-test.mf.gov.pl/docs/v2/openapi.json](https://ksef-test.mf.gov.pl/docs/v2/openapi.json).
Struktura faktury w postaci XML jest opisana na stronie: [https://crd.gov.pl/wzor/2025/06/25/13775/](https://crd.gov.pl/wzor/2025/06/25/13775/).


### Dodatkowe informacje

* Dokumentacja API / środowisko testowe KSeF: [https://ksef-test.mf.gov.pl/docs/v2](https://ksef-test.mf.gov.pl/docs/v2). ([Krajowy System e-Faktur][1])
* Oficjalny portal KSeF: [https://ksef.podatki.gov.pl/](https://ksef.podatki.gov.pl/). ([Krajowy System e-Faktur][2])
* Dokumentacja KSeF: [https://github.com/CIRFMF/ksef-docs/tree/main](https://github.com/CIRFMF/ksef-docs/tree/main)