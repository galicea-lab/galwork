load_env() {
    local env_file env_dir

    if [ "$#" -gt 1 ]; then
        echo "Błąd: skrypt przyjmuje co najwyżej jeden argument (plik .env)." >&2
        exit 1
    fi

    if [ "$#" -eq 1 ]; then
        env_file="$1"
    else
        env_file="./.env"
        if [ ! -f "$env_file" ]; then
            echo "Błąd: nie podano argumentu, a plik .env nie istnieje w bieżącym katalogu." >&2
            exit 1
        fi
    fi

    if [ ! -f "$env_file" ]; then
        echo "Błąd: plik $env_file nie istnieje." >&2
        exit 1
    fi

    env_dir="$(cd "$(dirname "$env_file")" && pwd)"
    source "$env_dir/$(basename "$env_file")"

    : "${DIR:?Brak zmiennej DIR w pliku $env_file}"

    case "$DIR" in
        /*) ;;
        *) DIR="$env_dir/$DIR" ;;
    esac

    cd "$DIR"
}

current_branch() {
    local branch

    branch="$(git branch --show-current)"
    if [ -z "$branch" ]; then
        echo "Błąd: HEAD jest odłączony. Przełącz się na gałąź." >&2
        exit 1
    fi
    printf '%s\n' "$branch"
}

assert_not_main() {
    local branch="${1:-}"

    if [ -z "$branch" ]; then
        echo "Błąd: brak nazwy gałęzi." >&2
        exit 1
    fi

    case "$branch" in
        main|master)
            echo "Błąd: operacja niedozwolona na gałęzi głównej $branch." >&2
            exit 1
            ;;
    esac
}

assert_not_protected() {
    local branch="${1:-}"

    if [ -z "$branch" ]; then
        echo "Błąd: brak nazwy gałęzi." >&2
        exit 1
    fi

    case "$branch" in
        main|master|release/*)
            echo "Błąd: odmowa operacji na gałęzi chronionej $branch." >&2
            exit 1
            ;;
    esac
}

assert_branch_is_current() {
    local branch="${1:-}" current

    current="$(current_branch)"
    if [ "$branch" != "$current" ]; then
        echo "Błąd: BRANCH=$branch, ale aktywna gałąź to $current." >&2
        exit 1
    fi
}

assert_no_secrets_staged() {
    local bad path

    bad="$(git diff --cached --name-only | grep -E '(^|/)(\.env|TOKENY)$' || true)"
    if [ -n "$bad" ]; then
        echo "Błąd: do commita trafił .env lub plik TOKENY:" >&2
        printf '%s\n' "$bad" >&2
        while IFS= read -r path; do
            if [ -n "$path" ]; then
                git reset -q -- "$path"
            fi
        done <<< "$bad"
        exit 1
    fi
}

assert_clean_tree() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Błąd: katalog roboczy nie jest czysty. Zacommituj lub odłóż zmiany." >&2
        exit 1
    fi
}
