1. Zrób clone biblioteki do testów:
git_clone.sh

2. Skopiuj certyfikat i klucz do secret/edr
Czyli powineneś mieć pliki:
secret/edr/edr_key.pem
secret/edr/edr_cert.pem

3. Ustaw parametry w config.ini
poza ścieżkami do powyższych plików - adres e-doręczeń

4. Zrób test:
test_inbox.sh

powinen wyświetlić zawartość skrzynki


Token można uzyskać pod adresem *https://ow.edoreczenia.gov.pl/auth/realms/EDOR/protocol/openid-connect/token*. 

Wyszukiwanie adresów doręczeń elektronicznych (ADE) zaimplementowano, używając adresu
(endpoint) *https://ow.edoreczenia.gov.pl/api/se/v3* (v3 oznacza wersję 3). 

Natomiast skrzynki wiadomości są obsługiwane na serwerze operatora - obecnie  Poczty Polskiej: 
https://uaapi-ow.poczta-polska.pl/api/v1. 

Do celów testowych udostępnione zostały odpowiednio adresy: 
-  *https://int-ow.edoreczenia.gov.pl/auth/realms/EDOR/protocol/openid-connect*, 
-  *https://int-ow.edoreczenia.gov.pl/api/se/v1*, 
-  *https://uaapi-int-ow.poczta-polska.pl/api/v1*. 
Wszystkie endpointy służące do obsługi wiadomości zaczynają się od adresu obsługiwanej skrzynki: 

`https://{hostname}/{eDeliveryAddress}/{definicja1} `

Gdzie: 
-  {*hostname*} to powyższy adres podany przez operatora, 
-  {*eDeliveryAddress*} to unikalny adres skrzynki odbiorcy, uzyskany podczas rejestracji w systemie (np. PL-99999-99999-STVJH-99), 
-  {*definicja*} - definicja wywoływanej funkcji (endpoint). 


Po zarejestrowaniu skrzynki możemy w jej ustawieniach zarejestrować swoją aplikację. Potrzebny do tego jest kwalifikowany certyfikat.
Podmioty publiczne uzyskują go za darmo ze strony e-Doręczen. Natomiast podmioty prywatne muszą dostarczyć
certyfikat zakupiony u kwalifikowanego dostawcy. Może to być na przykład certyfikat uzyskany do szyfrowania komunikacji z Węzłem Krajowym.
Aplikację wraz z certyfikatem ustawiamy w opcji *Uprawnienia/System skrzynki e-Doręczeń*. 



Proces uwierzytelniania systemu klienckiego w usłudze e-Doręczenia jest oparty na  standardzie OAuth 2.0 z wykorzystaniem JWT Bearer Token. 
Oznacza to, że aplikacja kliencka musi najpierw udowodnić swoją tożsamość, tworząc i podpisując cyfrowo specjalny „bilet" (JWT), a następnie wymienic
go na właściwy token dostępowy u dostawcy  tożsamości. 


Dokumentacja dodatkowa 

* Strona e-Doręczeń, https://www.gov.pl/web/e-doreczenia
* Interfejsy API, https://www.gov.pl/web/e-doreczenia/interfejsy-api



