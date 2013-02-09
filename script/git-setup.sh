#!/bin/bash

# Any argument means we kill everything off first.
if [ -z "$1" ]; then clean=false; else clean=true; fi

if [ ! -d `pwd`/plugins/redmine_git_server ]
then
  echo "Run from Rails.root!"
  exit 1
fi

mkdir -p tmp/redmine_git_server
cd tmp/redmine_git_server

web_user=`whoami`
git_user="git"
git_home="/var/git"
key_path=`pwd`/.ssh/gitolite_admin_id_rsa
gitolite_repo="https://github.com/sitaramc/gitolite.git"

$clean && echo "Cleaning .ssh" && rm -rf .ssh

echo "Creating SSH keys"
mkdir -p .ssh
chmod 700 .ssh
[ ! -f "$key_path" ] && ssh-keygen -N "" -f "$key_path"

echo "Creating $git_user user"
sudo dscl . -create /Groups/$git_user
sudo dscl . -create /Groups/$git_user PrimaryGroupID 333
sudo dscl . -create /Groups/$git_user RealName "Git Server"
sudo dscl . -create /Users/$git_user UniqueID 333
sudo dscl . -create /Users/$git_user PrimaryGroupID 333
sudo dscl . -create /Users/$git_user NFSHomeDirectory "$git_home"
sudo dscl . -create /Users/$git_user UserShell /bin/bash
sudo dscl . -create /Users/$git_user RealName "Git Server"

sudo dseditgroup -o edit -a "$web_user" -t user _git

$clean && echo "Cleaning $git_user home" && sudo rm -rf "$git_home"

echo "Creating $git_user home"
sudo mkdir -p "$git_home"
sudo chown -R $git_user:$git_user "$git_home"

echo "Copying gitolite_admin pubkey"
sudo cp "$key_path.pub" "$git_home/gitolite_admin.pub"
sudo chown $git_user:$git_user "$git_home/gitolite_admin.pub"

web2git="$web_user ALL=($git_user) NOPASSWD:ALL"
git2web="$git_user ALL=($web_user) NOPASSWD:ALL"

if ! sudo grep "$web2git" /etc/sudoers > /dev/null && ! sudo grep "$web2git" /etc/sudoers > /dev/null
then
  echo "Updating sudoers"
  sudo cp -p /etc/sudoers /etc/sudoers.tmp
  echo -e "$web2git\n$git2web" | sudo tee -a /etc/sudoers.tmp > /dev/null
  if sudo visudo -cqf /etc/sudoers.tmp
  then
      echo "Updating sudoers succeeded"
      sudo mv /etc/sudoers.tmp /etc/sudoers
  else
      sudo rm /etc/sudoers.tmp
      echo "Updating sudoers failed"
  fi
else
  echo "Sudoers already updated"
fi

sudo -u $git_user -H bash -c "./gitolite-setup.sh \"$key_path.pub\" \"$gitolite_repo\""

$clean && echo "Cleaning gitolite-admin" && rm -rf gitolite-admin
echo "Cloning gitolite-admin"
# git clone "$git_user@git.redmine.dev:gitolite-admin.git"

# $clean && rm db/development.db
# rake db:migrate
# REDMINE_LANG=en rake redmine:load_default_data
# rake redmine:plugins:migrate
touch tmp/restart.txt