# Copyright (C) 2014 Droonga Project
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

# Usage:
#   Install a release version:
#     curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | sudo bash
#   Install the latest revision from the repository:
#     curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | sudo INSTALL_VERSION=master bash

NAME=droonga-http-server
SCRIPT_URL=https://raw.githubusercontent.com/droonga/$NAME/master/install
REPOSITORY_URL=https://github.com/droonga/$NAME.git
USER=$NAME
DROONGA_BASE_DIR=/home/$USER/droonga

EXPRESS_DROONGA_REPOSITORY_URL=git://github.com/droonga/express-droonga.git#master

if [ "$INSTALL_VERSION" = "" ]; then
  export INSTALL_VERSION=release
fi

case $(uname) in
  Darwin|*BSD|CYGWIN*) sed="sed -E" ;;
  *)                   sed="sed -r" ;;
esac

exist_user() {
  id "$1" > /dev/null 2>&1
}

prepare_user() {
  if ! exist_user $USER; then
    useradd -m $USER
  fi
}

setup_configuration_directory() {
  PLATFORM=$1

  [ ! -e $DROONGA_BASE_DIR ] &&
    mkdir $DROONGA_BASE_DIR
  [ ! -e $DROONGA_BASE_DIR/$NAME.yaml ] &&
    curl -o $DROONGA_BASE_DIR/$NAME.yaml $SCRIPT_URL/$PLATFORM/$NAME.yaml
  chown -R $USER.$USER $DROONGA_BASE_DIR
}

use_master_express_droonga() {
  mv package.json package.json.bak
  cat package.json.bak | $sed -e "s;(express-droonga.+)\*;\1$EXPRESS_DROONGA_REPOSITORY_URL;" > package.json
}

install_master() {
  if [ -d $NAME ]
  then
    cd $NAME
    git stash save
    git pull --rebase
    git stash pop
    use_master_express_droonga
    npm update
  else
    git clone $REPOSITORY_URL
    cd $NAME
    use_master_express_droonga
  fi
  npm install -g
  rm package.json
  mv package.json.bak package.json
}

install_service_script() {
  INSTALL_LOCATION=$1
  PLATFORM=$2
  DOWNLOAD_URL=$SCRIPT_URL/$PLATFORM/$NAME
  if [ ! -e $INSTALL_LOCATION ]
  then
    curl -o $INSTALL_LOCATION $DOWNLOAD_URL
    chmod +x $INSTALL_LOCATION
  fi
}

install_in_debian() {
  # install droonga
  apt-get update
  apt-get -y upgrade
  apt-get install -y nodejs nodejs-legacy npm
  if [ "$INSTALL_VERSION" = "master" ]; then
    echo "Installing $NAME from the git repository..."
    apt-get install -y git
    install_master
  else
    echo "Installing $NAME from npmjs.org..."
    npm install -g droonga-http-server
  fi

  prepare_user
  
  setup_configuration_directory debian

  # set up service
  install_service_script /etc/rc.d/init.d/$NAME debian
  update-rc.d $NAME defaults
}

install_in_centos() {
  #TODO: We have to take care of a case when EPEL is already activated.
  #      If EPEL is not activated, we have to activate it temporally
  #      and disable it after installation.
  #      Otherwise we should not do anything around EPEL.
  yum -y update
  yum -y install epel-release
  yum -y install npm
  if [ "$INSTALL_VERSION" = "master" ]; then
    echo "Installing $NAME from the git repository..."
    yum -y install git
    install_master
  else
    echo "Installing $NAME from npmjs.org..."
    npm install -g droonga-http-server
  fi

  prepare_user

  setup_configuration_directory centos

  install_service_script /etc/rc.d/init.d/$NAME centos
  /sbin/chkconfig --add $NAME
}

if [ -e /etc/debian_version ] || [ -e /etc/debian_release ]; then
  install_in_debian
elif [ -e /etc/centos-release ]; then
  install_in_centos
else
  echo "Not supported platform. This script works only for Debian or CentOS."
  return 255
fi
