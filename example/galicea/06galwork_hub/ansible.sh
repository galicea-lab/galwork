# klucz galwork_deploy ma hasło, ładuję go przez ssh-add
ssh-add  ~/.ssh/galwork_deploy
# użytkownik deploy nie ma passwordless sudo - parametr -K
cd ansible

#  --check --diff w razie potrzeby:
# ansible-playbook deploy.yml --check --diff -K

# inicjowanie słowników
#ansible-playbook deploy.yml -K --tags seed

ansible-playbook deploy.yml -K
