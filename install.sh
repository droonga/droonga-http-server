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
#
#  Ubuntu:
#
#   Install a release version:
#     $ curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | sudo bash
#   Install the latest revision from the repository:
#     $ curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | sudo VERSION=master bash
#   Install without prompt for the hostname:
#     $ curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | sudo HOST=xxx.xxx.xxx.xxx ENGINE_HOST=xxx.xxx.xxx.xxx bash
#
#  CentOS 7:
#
#   Install a release version:
#     # curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | bash
#   Install the latest revision from the repository:
#     # curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | VERSION=master bash
#   Install without prompt for the hostname:
#      #curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | HOST=xxx.xxx.xxx.xxx ENGINE_HOST=xxx.xxx.xxx.xxx bash

NAME=droonga-http-server
SCRIPT_URL=https://raw.githubusercontent.com/droonga/$NAME/master/install
REPOSITORY_URL=https://github.com/droonga/$NAME.git
USER=$NAME
DROONGA_BASE_DIR=/home/$USER/droonga

EXPRESS_DROONGA_REPOSITORY_URL=git://github.com/droonga/express-droonga.git#master

: ${VERSION:=release}
: ${HOST:=Auto Detect}
: ${ENGINE_HOST:=Auto Detect}

case $(uname) in
  Darwin|*BSD|CYGWIN*) sed="sed -E" ;;
  *)                   sed="sed -r" ;;
esac

exist_command() {
  type "$1" > /dev/null 2>&1
}

exist_user() {
  id "$1" > /dev/null 2>&1
}

prepare_user() {
  if ! exist_user $USER; then
    echo ""
    echo "Preparing the user..."
    useradd -m $USER
  fi
}

setup_configuration_directory() {
  PLATFORM=$1

  echo ""
  echo "Setting up the configuration directory..."

  [ ! -e $DROONGA_BASE_DIR ] &&
    mkdir $DROONGA_BASE_DIR

  config_file="$DROONGA_BASE_DIR/$NAME.yaml"
  if [ ! -e $config_file ]; then
    if [ "$ENGINE_HOST" = "Auto Detect" ]; then
      ENGINE_HOST=""
      engine_config="/home/droonga-engine/droonga/droonga-engine.yaml"
      if [ -e $engine_config ]; then
        ENGINE_HOST=$(cat $engine_config | grep -E "^ *host *:" | \
                      cut -d ":" -f 2 | $sed -e "s/^ +| +\$//g")
      fi
      if [ "$ENGINE_HOST" != "" ]; then
        echo "The droonga-engine service is detected on this node. The droonga-http-server is configured to be connected to this node ($ENGINE_HOST)."
      else
        input_hostname \
          "Enter a host name or an IP address of the droonga-engine to be connected" &&
        HOST=$TYPED_HOSTNAME
      fi
    fi

    [ "$HOST" = "Auto Detect" ] &&
      determine_hostname \
        "If this node has a global host name or a global IP address, then choose \"Manual Input\" and type it. Otherwise, choose a preferred IP address which can be accessed from the droonga-engine node." \
        "Enter a global host name or a global IP address for this node" &&
      HOST=$DETERMINED_HOSTNAME

    curl -o $config_file.template $SCRIPT_URL/$PLATFORM/$NAME.yaml
    cat $config_file.template | \
      $sed -e "s/\\\$engine_hostname/$ENGINE_HOST/" \
           -e "s/\\\$receiver_hostname/$HOST/" \
      > $config_file
    rm $config_file.template
  fi

  chown -R $USER.$USER $DROONGA_BASE_DIR
}


get_addresses_with_interface() {
  if exist_command ip; then
    ip addr | grep "inet " | \
      $sed -e "s/^ *inet ([0-9\.]+).+ ([^ ]+)\$/\1 \2/"
    return 0
  fi

  if exist_command ifconfig; then
    interfaces=$(ifconfig -s | cut -d " " -f 1 | tail -n +2)
    for interface in $interfaces; do
      address=$(LANG=C ifconfig $interface | grep "inet addr" | \
                $sed -e "s/^ *inet addr:([0-9\.]+).+\$/\1/")
      if [ "$address" != "" ]; then
        echo $address $interface
      fi
    done
    return 0
  fi

  echo "127.0.0.1 lo"
  return 0
}

determine_hostname() {
  prompt_for_suggestions="$1"
  prompt_for_manual_input="$2"

  if [ $(get_addresses_with_interface | wc -l) -eq 1 ]; then
    DETERMINED_HOSTNAME=$(get_addresses_with_interface | cut -d " " -f 1)
    return 0
  fi

  PS3="$prompt_for_suggestions: "
  select chosen in $(get_addresses_with_interface | \
                     $sed -e "s/ (.+)\$/(\1)/") "Manual Input"
  do
    if [ -z "$chosen" ]; then
      continue
    else
      DETERMINED_HOSTNAME=$(echo $chosen | cut -d "(" -f 1)
      break
    fi
  done

  if [ "$DETERMINED_HOSTNAME" = "Manual Input" ]; then
    input_hostname "$prompt_for_manual_input" &&
      DETERMINED_HOSTNAME="$TYPED_HOSTNAME"
  fi

  return 0
}

input_hostname() {
  prompt="$1: "
  while read -p "$prompt" TYPED_HOSTNAME; do
    if [ "$TYPED_HOSTNAME" != "" ]; then break; fi
  done
  return 0
}


use_master_express_droonga() {
  mv package.json package.json.bak
  cat package.json.bak | \
    $sed -e "s;(express-droonga.+)\*;\1$EXPRESS_DROONGA_REPOSITORY_URL;" \
    > package.json
}

install_master() {
  [ ! -e $DROONGA_BASE_DIR ] &&
    mkdir $DROONGA_BASE_DIR

  cd $DROONGA_BASE_DIR

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

  echo ""

  if [ "$VERSION" = "master" ]; then
    echo "Installing $NAME from the git repository..."
    apt-get install -y git
    install_master
  else
    echo "Installing $NAME from npmjs.org..."
    npm install -g droonga-http-server
  fi

  prepare_user
  
  setup_configuration_directory debian

  echo ""
  echo "Registering $NAME as a service..."
  install_service_script /etc/init.d/$NAME debian
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

  echo ""

  if [ "$VERSION" = "master" ]; then
    echo "Installing $NAME from the git repository..."
    yum -y install git
    install_master
  else
    echo "Installing $NAME from npmjs.org..."
    npm install -g droonga-http-server
  fi

  prepare_user

  setup_configuration_directory centos

  echo ""
  echo "Registering $NAME as a service..."
  install_service_script /etc/rc.d/init.d/$NAME centos
  /sbin/chkconfig --add $NAME
}

if [ -e /etc/debian_version ] || [ -e /etc/debian_release ]; then
  install_in_debian
elif [ -e /etc/centos-release ]; then
  install_in_centos
else
  echo "Not supported platform. This script works only for Debian or CentOS."
  exit 255
fi

echo ""
echo "Successfully installed $NAME."
exit 0
