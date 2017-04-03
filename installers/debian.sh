#!/bin/bash

# Debian Jessie Install Script

# paste default ssh key here
default_ssh_key=""


install_stuff(){
sudo apt -y update ;\
sudo apt -y upgrade;\
sudo apt -y install irssi znc secure-delete openvpn tor tor-arm python-pip git ufw
if [[ ! -d /var/lib/dnscrypt ]] ; then
  sleep 1;\
  echo 'I will now install dnscrypt-proxy. Please follow the prompts.';\
  sleep 1;\
  cd /usr/local/src;\
  sudo git clone https://github.com/simonclausen/dnscrypt-autoinstall &&\
  cd dnscrypt-autoinstall &&\
  sudo ./dnscrypt-autoinstall || echo 'Error installing dnscrypt!'
else
  echo 'Already got dnscrypt...'
fi

sudo cp /etc/tor/torrc /etc/tor/torrc.orig
sudo cp /etc/tor/torrc /tmp/torrc && \
sudo bash -c " echo 'HiddenServiceDir /var/lib/tor/ssh_service' >>/tmp/torrc" &&\
sudo bash -c " echo 'HiddenServicePort 22 127.0.0.1:22' >>/tmp/torrc " &&\
sudo cp /tmp/torrc /etc/tor/torrc || exit 1

(sudo service tor restart >/dev/null 2>&1 || sudo service tor start) || (echo "Failed to start tor! Wtf?";exit 1) &&\
echo 'Your SSH .onion url:'
sleep 1;echo '..';sleep 1;echo '...';sleep 1
sudo cat '/var/lib/tor/ssh_service/hostname' 2>/dev/null;echo
}

firewall_up(){
echo 'Hardening ssh...'
wget -O /tmp/sshd_config https://raw.githubusercontent.com/anonshells/config/master/sshd_config &&\
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
sudo cp /tmp/sshd_config /etc/ssh/sshd_config
sudo ufw allow ssh
sudo ufw enable
read -p "Have you confirmed that you can log in with your public key? (yes/no)" I_am_not_an_idiot
if ([[ $I_am_not_an_idiot == "yes" ]]||[[ $I_am_not_an_idiot == "y" ]]||[[ $I_am_not_an_idiot == "Y" ]]) ; then
  sudo service ssh restart
else
  echo 'Remember to restart ssh after you have confirmed you can log in with your key!'
fi
}

conf_ssh(){
echo 'Configuring ssh'
mkdir ~/.ssh
chmod 700 ~/.ssh
read -p "Please paste your ssh key or press enter to use default" ssh_key
if [[ -s "$ssh_key" ]] ; then
  echo "$ssh_key" >~/.ssh/authorized_keys
else
  echo "$default_ssh_key" >~/.ssh/authorized_keys
fi
echo 'Contents of authorized_keys:'
cat ~/.ssh/authorized_keys

chmod 600 ~/.ssh/authorized_keys
ip=$(curl ipecho.net/plain)>/dev/null &&\
echo "Success. You can now test logging in with ssh:";\
echo "       $ ssh -i ~/.ssh/<key file> -v $USER@$ip"||\
echo 'Temporary error. Try logging in with ssh key'

}

if [[ ! -f ~/.ssh/authorized_keys ]] ; then
conf_ssh
fi

echo 'Done, updating system and installing software'

which sudo >/dev/null 2>&1 &&\
if groups $USER|grep sudo >/dev/null 2>&1 ; then gotSudo='True' ;fi


if [[ "$gotSudo" != "True" ]]; then
  (export user=$USER
  su -c "apt -y update ;apt -y install sudo;usermod -a -G sudo $user"
  echo 'Please log out of ssh and in again, and rerun this script to finish.')
fi



install_stuff
firewall_up

exit
