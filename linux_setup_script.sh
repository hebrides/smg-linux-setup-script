########################################
#                                      #
#        SMG Mobile Linux Server       #
#                                      #
#             Basic Set Up             #
#                                      #
#            Ubuntu Version            #
#                                      #
########################################

## update packages
apt update
apt upgrade -y

## create a new admin user

echo "Please enter a user name for the new admin user (defaults to 'admin'): "
read ADMIN
adduser $ADMIN
# asks for password
usermod -aG sudo $ADMIN

## setup ssh
# turn root login off
sed --in-place=_bak 's/PermitRootLogin\ yes/PermitRootLogin\ no/g' /etc/ssh/sshd_config
# turn off password auth
sed --in-place=_bak 's/PasswordAuthentication\ yes/PasswordAuthentication\ no/g' /etc/ssh/sshd_config
# default SSH port to 22 if not set
 if [ -z "$SSH_PORT" ]; then SSH_PORT=22 ; else echo "SSH_PORT=$SSH_PORT"; fi
# change port
echo "Port $SSH_PORT" >> /etc/ssh/sshd_config
# add $HOME/.ssh/authorized_keys as the authorized keys file
echo "AuthorizedKeysFile     .ssh/authorized_keys" >> /etc/ssh/sshd_config
# add ssh banner
echo "
███████╗███╗   ███╗ ██████╗ ███╗   ███╗ ██████╗ ██████╗ ██╗██╗     ███████╗
██╔════╝████╗ ████║██╔════╝ ████╗ ████║██╔═══██╗██╔══██╗██║██║     ██╔════╝
███████╗██╔████╔██║██║  ███╗██╔████╔██║██║   ██║██████╔╝██║██║     █████╗
╚════██║██║╚██╔╝██║██║   ██║██║╚██╔╝██║██║   ██║██╔══██╗██║██║     ██╔══╝
███████║██║ ╚═╝ ██║╚██████╔╝██║ ╚═╝ ██║╚██████╔╝██████╔╝██║███████╗███████╗
╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝╚══════╝╚══════╝
" > /etc/ssh/banner
echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config
# add ssh key data to the admin user
mkdir /home/$ADMIN/.ssh
chown $ADMIN:$ADMIN /home/$ADMIN/.ssh
echo "# add your public ssh key(s) here for the admin user" > /home/$ADMIN/.ssh/authorized_keys
nano /home/$ADMIN/.ssh/authorized_keys
chown $ADMIN:$ADMIN /home/$ADMIN/.ssh/authorized_keys

## swap file
free -h
echo "
Enter a swap file value in GB (Recommend 2-8 GB) based on your free MEM shown above. 
(Refer to https://bitlaunch.io/blog/how-to-create-and-adjust-swap-space-in-ubuntu-20-04/) "
read SWAP
sudo fallocate -l ${SWAP}G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

## fire wall set up
# add uncomplicated fire wall package
apt install ufw -y
# ssh
ufw deny in 22
ufw allow out 22
# special ssh port
ufw allow in $SSH_PORT
ufw allow out $SSH_PORT
# http
ufw allow in http
ufw allow out http
ufw allow in https
ufw allow out https
# limits
# ufw limit 80/tcp
# ufw limit 443/tcp
ufw enable

## install fail2ban
# https://linuxhandbook.com/fail2ban-basic/
apt install fail2ban -y
systemctl start fail2ban
systemctl enable fail2ban

## useful cron jobs
# min/hr/day/mth/wkd:
# 15 9 17 3 1 = Sunday, March 17th 0915 hrs
# https://cron.help/ or https://crontab.guru
# update weekly at 3 AM Sunday
echo "0 3 * * 0 root bash (apt update && apt -y upgrade) > /dev/null" >> /etc/cron.d/updates
# restart server every 3 months at 3AM on the 1st
echo "0 3 1 1-12/3 * (/sbin/shutdown -r now) > /dev/null" >> /etc/cron.d/updates

## install other favorite server apps
echo "Installing useful server apps"
apt install ripgrep -y
apt install fd-find -y
apt install jq -y

## set time zone
timedatectl set-timezone America/Los_Angeles

## add useful bash scripts
echo "
# Dir & Nav Shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias up1='cd ..'
alias up2='cd ../..'
alias up3='cd ../../..'
alias up4='cd ../../../..'
alias up5='cd ../../../../..'
alias up6='cd ../../../../../..'
alias home='cd ~'
alias r='cd /'
alias root='cd /'
# Misc
alias cls='clear'
alias dir='ls'
alias h='history'
alias path='echo -e \${PATH//:/\\\n}'
alias now='date +%T'
alias fd='fdfind'
" >> ~/.bash_aliases

cp ~/.bash_aliases /home/$ADMIN

## Prepare for SSL
cd /home/$ADMIN
curl https://get.acme.sh | sh -s email=admin@smgmobile.com

## reboot
reboot
