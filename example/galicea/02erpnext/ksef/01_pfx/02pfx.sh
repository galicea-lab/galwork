PFX_PASS=$(cat ~/.hasla/.galicea_sign_pfx.txt)
# eksport do pfx
openssl pkcs12 -export -inkey sign.key.pem -in sign.crt.pem -out galicea_sign.pfx -passout pass:$PFX_PASS
