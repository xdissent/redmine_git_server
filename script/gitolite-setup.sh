#!/bin/bash

echo "Setting up gitolite"

cd
mkdir -p bin
echo 'export PATH="$HOME/bin:$PATH"' > .bashrc
echo 'export PATH="$HOME/bin:$PATH"' > .bash_profile
. .bashrc
git clone "$2" gitolite-source
gitolite-source/install -ln
gitolite setup -pk $1
cd -

# g2
# git clone https://github.com/sitaramc/gitolite.git -b v2.3.1
# gitolite/src/gl-system-install
# gl-setup -q /Users/xdissent/Code/redmine/.ssh/gitolite_admin_id_rsa.pub