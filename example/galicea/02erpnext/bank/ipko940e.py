#!/usr/bin/env python

# source /python/venv/bin/activate
# pip install mt-940

import csv
import io
import re
import sys
from datetime import datetime
from decimal import Decimal

import mt940
from mt940.tags import Statement, Tag


class StatementWithTime(Statement):

    pattern = r'''^
    (?P<year>\d{2})
    (?P<month>\d{2})
    (?P<day>\d{2})
    (?P<entry_month>\d{2})?
    (?P<entry_day>\d{2})?
    (?P<entry_time>\d{6})?
    (?P<status>R?[DC])
    (?P<funds_code>[A-Z])?
    [\n ]?
    (?P<amount>[\d,]{1,15})
    (?P<id>[A-Z][A-Z0-9 ]{3})?
    (?P<customer_reference>((?!//)[^\n]){0,16})
    (//(?P<bank_reference>.{0,23}))?
    (\n?(?P<extra_details>.{0,34}))?
    $'''


POLISH_LETTERS = set('ąćęłńóśźżĄĆĘŁŃÓŚŹŻ')
ENCODINGS = ('utf-8-sig', 'utf-8', 'iso-8859-2', 'cp852', 'cp1250', 'latin1')
DETAILS_MARKER = re.compile(r'[\^~](\d{2})')
CHUNK_WIDTH = 27
IGNORED_TAG_IDS = (26,)
REFERENCE_PREFIX = 'PKOB1'
HEADERS = ['Data', 'Wpłata', 'Wypłata', 'Opis', 'Numer referencyjny',
           'Rachunek bankowy', 'Waluta']
DATE_FORMATS = ('%d.%m.%Y', '%Y-%m-%d', '%d-%m-%Y')


class IgnoredTag(Tag):

    pattern = r'(?P<value>[\s\S]*)$'

    def __call__(self, transactions, value):
        return {}


def build_custom_tags():
    tags = {61: StatementWithTime()}
    for tag_id in IGNORED_TAG_IDS:
        tag = IgnoredTag()
        tag.id = tag_id
        tags[tag_id] = tag
    return tags


def decode_file(filename):
    with open(filename, 'rb') as fh:
        raw = fh.read()

    best = None
    for encoding in ENCODINGS:
        try:
            text = raw.decode(encoding)
        except UnicodeDecodeError:
            continue

        score = sum(3 for ch in text if ch in POLISH_LETTERS)
        score -= 5 * sum(
            1 for ch in text
            if (ord(ch) < 32 and ch not in '\n\r\t') or 0x7F <= ord(ch) <= 0x9F
        )
        if encoding.startswith('utf-8'):
            score += 10

        if best is None or score > best[0]:
            best = (score, text)

    if best is None:
        return raw.decode('iso-8859-2', errors='replace')
    return best[1]


def clean_chunk(value):
    value = value.replace('\r', '').replace('\n', '')
    value = value.replace('\u02d9', '').replace('\u00a0', ' ')
    return ''.join(ch if ch.isprintable() else ' ' for ch in value)


def detail_chunks(memo):
    memo = (memo or '').replace('\r', '')
    matches = list(DETAILS_MARKER.finditer(memo))
    chunks = {}
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(memo)
        value = clean_chunk(memo[match.end():end])
        chunks.setdefault(match.group(1), []).append(value)
    return chunks


def join_chunks(chunks, codes):
    parts = []
    for code in codes:
        parts.extend(chunks.get(code, []))

    text = ''.join(part.ljust(CHUNK_WIDTH) for part in parts)
    return re.sub(r'\s+', ' ', text).strip()


def extract_description(memo):
    chunks = detail_chunks(memo)
    if not chunks:
        return re.sub(r'\s+', ' ', clean_chunk(memo)).strip() or 'UNKNOWN'

    text = join_chunks(chunks, ('20', '21', '22', '23', '24', '25'))
    if not text:
        text = join_chunks(chunks, ('00',))
    return text or 'UNKNOWN'


def split_amount(amount):
    if amount > 0:
        return amount, Decimal(0)
    return Decimal(0), -amount


def write_statement(month_year, operations):
    csv_filename = f'zestawienie_{month_year.replace("/", "_")}.csv'
    fnumer = f'{REFERENCE_PREFIX}/{month_year}/'

    with open(csv_filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile, delimiter=',', quotechar='"',
                            quoting=csv.QUOTE_ALL)
        writer.writerow(HEADERS)

        for n, operation in enumerate(operations, 1):
            writer.writerow([
                operation['date'],
                operation['deposit'],
                operation['withdrawal'],
                operation['description'],
                f'{fnumer}{n:02}',
                '',
                operation['currency'],
            ])

    print(f'Zapisano plik: {csv_filename}')


def parse_mt940_file(filename):
    text = decode_file(filename)
    transactions = mt940.parse(io.StringIO(text), tags=build_custom_tags())
    lista = transactions.transactions

    if not lista:
        print('Brak transakcji w pliku.')
        return

    first_date = lista[0].data.get('entry_date') or lista[0].data['date']
    month_year = first_date.strftime('%Y/%m')
    operations = []

    for tr in lista:
        amount = tr.data['amount']
        deposit, withdrawal = split_amount(amount.amount)
        operations.append({
            'date': tr.data.get('entry_date') or tr.data['date'],
            'deposit': deposit,
            'withdrawal': withdrawal,
            'description': extract_description(
                tr.data.get('transaction_details', '')),
            'currency': amount.currency,
        })

    write_statement(month_year, operations)


def clean_field(value):
    if value is None:
        return ''
    value = value.strip()
    if value.startswith("'"):
        value = value[1:].strip()
    return value


def get_field(row, *names):
    for name in names:
        value = clean_field(row.get(name))
        if value:
            return value
    return ''


def parse_amount(value):
    value = clean_field(value).replace('\u00a0', '').replace(' ', '')
    if ',' in value:
        value = value.replace('.', '').replace(',', '.')
    return Decimal(value)


def parse_date(value):
    value = clean_field(value)
    for date_format in DATE_FORMATS:
        try:
            return datetime.strptime(value, date_format).date()
        except ValueError:
            continue
    raise ValueError(f'Nieprawidłowa data: {value!r}')


def parse_operations_csv(filename):
    text = decode_file(filename)
    lines = text.splitlines()
    if not lines:
        print('Plik jest pusty.')
        return

    delimiter = ';' if lines[0].count(';') >= lines[0].count(',') else ','
    reader = csv.DictReader(io.StringIO(text), delimiter=delimiter)

    operations_by_month = {}
    for raw_row in reader:
        row = {(key or '').strip().lstrip('\ufeff'): value
               for key, value in raw_row.items()}
        if not any(clean_field(value) for value in row.values()):
            continue

        try:
            date = parse_date(get_field(
                row, 'Data księgowania', 'Data ksiegowania'))
            amount = parse_amount(get_field(row, 'Kwota operacji', 'Kwota'))
        except (ValueError, ArithmeticError) as exc:
            print(f'Pominięto wiersz: {exc}')
            continue

        description = get_field(row, 'Tytułem', 'Tytulem')
        if not description:
            description = get_field(
                row, 'Typ operacji', 'Nadawca / Odbiorca')
        description = re.sub(r'\s+', ' ', description).strip() or 'UNKNOWN'

        deposit, withdrawal = split_amount(amount)
        month_year = date.strftime('%Y/%m')
        operations_by_month.setdefault(month_year, []).append({
            'date': date,
            'deposit': deposit,
            'withdrawal': withdrawal,
            'description': description,
            'currency': get_field(row, 'Waluta') or 'PLN',
        })

    if not operations_by_month:
        print('Brak operacji w pliku.')
        return

    for month_year in sorted(operations_by_month):
        operations = operations_by_month[month_year]
        operations.sort(key=lambda operation: operation['date'])
        write_statement(month_year, operations)


def main():
    args = sys.argv[1:]

    if len(args) == 1 and not args[0].startswith('-'):
        parse_mt940_file(args[0])
    elif len(args) == 2 and args[0] in ('--csv', '-c'):
        parse_operations_csv(args[1])
    else:
        print('Użycie:')
        print('  python3 ipko940e.py <plik_MT940>')
        print('  python3 ipko940e.py --csv <plik_CSV>')
        sys.exit(1)


if __name__ == '__main__':
    main()
