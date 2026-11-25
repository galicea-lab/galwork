# twó©z klucz prywatny
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out key.pem

# twó©z csr
openssl req -new -key key.pem -out req.csr \
  -config openssl-ksef.cnf \
  -subj "/C=PL/O=Kowalski sp. z o.o/CN=Kowalski sp. z o.o/organizationIdentifier=VATPL-1234567890" \
  -addext "keyUsage=digitalSignature" \
  -addext "extendedKeyUsage=clientAuth"

