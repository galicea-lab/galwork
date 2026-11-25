-- Dane startowe słowników płaskich (tabela dictionary_entry) dla instancji galicea.
-- Klucze = TABLE_DICTIONARIES w galwork-hub/wf/services/dictionary_service.py.
-- Idempotentny: istniejąca para (dictionary_key, code) jest pomijana,
-- więc wartości poprawione ręcznie w arenie nie są nadpisywane.
-- Słowniki z scripts/seed_flat_dictionaries.py (rodzaj-pisma-studenta,
-- dzien-tygodnia, powod-skreslenia, kategoria-archiwizacji, rodzaje-urlopow)
-- i scripts/seed_zakupy.py (rodzaj-wydatku) celowo pominięte.
--
-- Uruchomienie: psql "$URL" -v ON_ERROR_STOP=1 -f slowniki_startowe.sql

BEGIN;

INSERT INTO dictionary_entry (id, dictionary_key, code, label, sort_order, is_active, extra)
SELECT gen_random_uuid(), v.dictionary_key, v.code, v.label, v.sort_order, true, '{}'::jsonb
FROM (VALUES
  -- ------------------------------------------------- struktura organizacji
  ('dzialy', 'fundacja', 'Fundacja', 10),

  -- ---------------------------------------------------------------- ogólne
  ('kategoria-pilnosci', 'niska',     'Niska',     10),
  ('kategoria-pilnosci', 'normalna',  'Normalna',  20),
  ('kategoria-pilnosci', 'wysoka',    'Wysoka',    30),
  ('kategoria-pilnosci', 'pilna',     'Pilna (natychmiast)', 40),

  ('typ-dokumentu', 'pismo',          'Pismo',            10),
  ('typ-dokumentu', 'wniosek',        'Wniosek',          20),
  ('typ-dokumentu', 'umowa',          'Umowa',            30),
  ('typ-dokumentu', 'aneks',          'Aneks do umowy',   40),
  ('typ-dokumentu', 'faktura',        'Faktura',          50),
  ('typ-dokumentu', 'protokol',       'Protokół',         60),
  ('typ-dokumentu', 'notatka',        'Notatka służbowa', 70),
  ('typ-dokumentu', 'zarzadzenie',    'Zarządzenie',      80),
  ('typ-dokumentu', 'decyzja',        'Decyzja',          90),
  ('typ-dokumentu', 'zaswiadczenie',  'Zaświadczenie',   100),
  ('typ-dokumentu', 'pelnomocnictwo', 'Pełnomocnictwo',  110),
  ('typ-dokumentu', 'oferta',         'Oferta',          120),
  ('typ-dokumentu', 'inny',           'Inny',            999),

  ('statusy-dokumentow', 'projekt',       'Projekt',          10),
  ('statusy-dokumentow', 'w-akceptacji',  'W akceptacji',     20),
  ('statusy-dokumentow', 'zatwierdzony',  'Zatwierdzony',     30),
  ('statusy-dokumentow', 'podpisany',     'Podpisany',        40),
  ('statusy-dokumentow', 'wyslany',       'Wysłany',          50),
  ('statusy-dokumentow', 'zarchiwizowany','Zarchiwizowany',   60),
  ('statusy-dokumentow', 'anulowany',     'Anulowany',        70),

  ('kraj', 'PL', 'Polska',          10),
  ('kraj', 'DE', 'Niemcy',          20),
  ('kraj', 'CZ', 'Czechy',          30),
  ('kraj', 'SK', 'Słowacja',        40),
  ('kraj', 'UA', 'Ukraina',         50),
  ('kraj', 'LT', 'Litwa',           60),
  ('kraj', 'BY', 'Białoruś',        70),
  ('kraj', 'GB', 'Wielka Brytania', 80),
  ('kraj', 'FR', 'Francja',         90),
  ('kraj', 'IT', 'Włochy',         100),
  ('kraj', 'ES', 'Hiszpania',      110),
  ('kraj', 'NL', 'Holandia',       120),
  ('kraj', 'US', 'Stany Zjednoczone', 130),

  -- ------------------------------------------------- finanse / zakupy / umowy
  ('jednostki-miary', 'szt',  'sztuka',            10),
  ('jednostki-miary', 'kpl',  'komplet',           20),
  ('jednostki-miary', 'opak', 'opakowanie',        30),
  ('jednostki-miary', 'usl',  'usługa',            40),
  ('jednostki-miary', 'h',    'godzina',           50),
  ('jednostki-miary', 'rbh',  'roboczogodzina',    60),
  ('jednostki-miary', 'dzien','dzień',             70),
  ('jednostki-miary', 'mies', 'miesiąc',           80),
  ('jednostki-miary', 'kg',   'kilogram',          90),
  ('jednostki-miary', 't',    'tona',             100),
  ('jednostki-miary', 'l',    'litr',             110),
  ('jednostki-miary', 'm',    'metr',             120),
  ('jednostki-miary', 'm2',   'metr kwadratowy',  130),
  ('jednostki-miary', 'm3',   'metr sześcienny',  140),
  ('jednostki-miary', 'km',   'kilometr',         150),

  ('forma-platnosci', 'przelew',    'Przelew',            10),
  ('forma-platnosci', 'karta',      'Karta płatnicza',    20),
  ('forma-platnosci', 'gotowka',    'Gotówka',            30),
  ('forma-platnosci', 'blik',       'BLIK',               40),
  ('forma-platnosci', 'przedplata', 'Przedpłata',         50),
  ('forma-platnosci', 'kompensata', 'Kompensata',         60),

  ('rodzaj-umowy', 'o-prace',      'Umowa o pracę',                         10),
  ('rodzaj-umowy', 'zlecenie',     'Umowa zlecenia',                        20),
  ('rodzaj-umowy', 'o-dzielo',     'Umowa o dzieło',                        30),
  ('rodzaj-umowy', 'wspolpraca',   'Umowa o współpracy (B2B)',              40),
  ('rodzaj-umowy', 'uslugi',       'Umowa o świadczenie usług',             50),
  ('rodzaj-umowy', 'dostawa',      'Umowa dostawy / sprzedaży',             60),
  ('rodzaj-umowy', 'najem',        'Umowa najmu / dzierżawy',               70),
  ('rodzaj-umowy', 'licencja',     'Umowa licencyjna',                      80),
  ('rodzaj-umowy', 'powierzenie',  'Umowa powierzenia przetwarzania danych',90),
  ('rodzaj-umowy', 'nda',          'Umowa o zachowaniu poufności (NDA)',   100),
  ('rodzaj-umowy', 'porozumienie', 'Porozumienie / list intencyjny',       110),

  -- ------------------------------------------------------------- kadry
  ('wyksztalcenie', 'podstawowe',   'Podstawowe',                       10),
  ('wyksztalcenie', 'zawodowe',     'Zasadnicze zawodowe / branżowe',   20),
  ('wyksztalcenie', 'srednie',      'Średnie ogólnokształcące',         30),
  ('wyksztalcenie', 'srednie-zaw',  'Średnie zawodowe',                 40),
  ('wyksztalcenie', 'policealne',   'Policealne',                       50),
  ('wyksztalcenie', 'wyzsze-1',     'Wyższe I stopnia (licencjat/inżynier)', 60),
  ('wyksztalcenie', 'wyzsze-2',     'Wyższe II stopnia (magister)',     70),
  ('wyksztalcenie', 'doktor',       'Stopień doktora',                  80),
  ('wyksztalcenie', 'dr-hab',       'Stopień doktora habilitowanego',   90),

  ('stopien-niepelnosprawnosci', 'brak',        'Brak',        10),
  ('stopien-niepelnosprawnosci', 'lekki',       'Lekki',       20),
  ('stopien-niepelnosprawnosci', 'umiarkowany', 'Umiarkowany', 30),
  ('stopien-niepelnosprawnosci', 'znaczny',     'Znaczny',     40),

  ('stopien-pokrewienstwa', 'malzonek',    'Małżonek',            10),
  ('stopien-pokrewienstwa', 'dziecko',     'Dziecko',             20),
  ('stopien-pokrewienstwa', 'rodzic',      'Rodzic',              30),
  ('stopien-pokrewienstwa', 'rodzenstwo',  'Rodzeństwo',          40),
  ('stopien-pokrewienstwa', 'dziadek',     'Dziadek / babcia',    50),
  ('stopien-pokrewienstwa', 'wnuk',        'Wnuk / wnuczka',      60),
  ('stopien-pokrewienstwa', 'tesc',        'Teść / teściowa',     70),
  ('stopien-pokrewienstwa', 'inny',        'Inny',               999),

  -- ------------------------------------------------------ kształcenie (edu)
  ('poziom-studiow', 'I',   'Studia I stopnia',                10),
  ('poziom-studiow', 'II',  'Studia II stopnia',               20),
  ('poziom-studiow', 'JM',  'Jednolite studia magisterskie',   30),
  ('poziom-studiow', 'POD', 'Studia podyplomowe',              40),
  ('poziom-studiow', 'SD',  'Szkoła doktorska',                50),
  ('poziom-studiow', 'KUR', 'Kurs / szkolenie',                60),

  ('typ-studiow', 'stacjonarne',   'Stacjonarne',      10),
  ('typ-studiow', 'niestacjonarne','Niestacjonarne',   20),
  ('typ-studiow', 'online',        'Zdalne (online)',  30),

  ('semestry', 'zimowy', 'Semestr zimowy', 10),
  ('semestry', 'letni',  'Semestr letni',  20),

  ('forma-zajec', 'W',   'Wykład',        10),
  ('forma-zajec', 'C',   'Ćwiczenia',     20),
  ('forma-zajec', 'L',   'Laboratorium',  30),
  ('forma-zajec', 'P',   'Projekt',       40),
  ('forma-zajec', 'S',   'Seminarium',    50),
  ('forma-zajec', 'K',   'Konwersatorium',60),
  ('forma-zajec', 'WAR', 'Warsztaty',     70),
  ('forma-zajec', 'PZ',  'Praktyka zawodowa', 80),
  ('forma-zajec', 'E',   'E-learning',    90),

  ('forma-zaliczenia', 'E',   'Egzamin',                  10),
  ('forma-zaliczenia', 'ZO',  'Zaliczenie na ocenę',      20),
  ('forma-zaliczenia', 'Z',   'Zaliczenie (bez oceny)',   30),
  ('forma-zaliczenia', 'PR',  'Projekt / praca zaliczeniowa', 40),

  ('kategoria-efektow-uczenia-sie', 'W', 'Wiedza',               10),
  ('kategoria-efektow-uczenia-sie', 'U', 'Umiejętności',         20),
  ('kategoria-efektow-uczenia-sie', 'K', 'Kompetencje społeczne',30)
) AS v(dictionary_key, code, label, sort_order)
ON CONFLICT (dictionary_key, code) DO NOTHING;

COMMIT;

SELECT dictionary_key, count(*) AS wierszy
FROM dictionary_entry GROUP BY 1 ORDER BY 1;
