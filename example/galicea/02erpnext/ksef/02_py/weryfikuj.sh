PFX_PASS=$(cat ~/.hasla/.galicea_sign_pfx.txt)
xmlsec1 --verify --pkcs12 galicea_sign.pfx --pwd $PFX_PASS $1