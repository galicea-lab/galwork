# klucz galwork_deploy ma hasło, ładuję go przez ssh-add
ssh-add  ~/.ssh/galwork_deploy 
# użytkownik deploy nie ma passwordless sudo - parametr -K
cd ansible

#  --check w razie potrzeby (zob. WDROZENIE.md):
# ansible-playbook deploy.yml --check -K

ansible-playbook deploy.yml -K


