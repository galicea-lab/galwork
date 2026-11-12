Zobacz opis w Podręczniku dewelopera - programisty (galwork.net/devbook):
 czesc-2-zasady-wytwarzania/04-wersjonowanie-i-wydania.md


Jeśli Git pyta o login i hasło (albo token), a chcesz tego uniknąć, masz dwa rozwiązania:
- możesz zapamiętać je w Gicie (git config --global credential.helper store albo cache). store zapisuje je jawnym tekstem w ~/.git-credentials.
- możesz też przejść na SSH (git remote set-url origin git@code.galicea.org:labc/galwork-edu.git), o ile serwer ma Twój klucz.

