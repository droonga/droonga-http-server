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
#   Install with specified hostnames (disabling auto-detection):
#     $ curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | sudo HOST=xxx.xxx.xxx.xxx ENGINE_HOST=xxx.xxx.xxx.xxx bash
#
#  CentOS 7:
#
#   Install a release version:
#     # curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | bash
#   Install the latest revision from the repository:
#     # curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | VERSION=master bash
#   Install with specified hostnames (disabling auto-detection):
#     # curl https://raw.githubusercontent.com/droonga/droonga-http-server/master/install.sh | HOST=xxx.xxx.xxx.xxx ENGINE_HOST=xxx.xxx.xxx.xxx bash

NAME=droonga-http-server
SCRIPT_URL=https://raw.githubusercontent.com/droonga/$NAME/master/install
REPOSITORY_URL=https://github.com/droonga/$NAME.git
USER=$NAME
GROUP=$USER
DROONGA_BASE_DIR=/home/$USER/droonga

EXPRESS_DROONGA_REPOSITORY_URL=git://github.com/droonga/express-droonga.git#master

: ${VERSION:=release}
: ${HOST:=Auto Detect}
: ${ENGINE_HOST:=Auto Detect}

REQUIRED_COMMANDS=npm
[ "$VERSION" = "master" ] &&
  REQUIRED_COMMANDS="$REQUIRED_COMMANDS git"

case $(uname) in
  Darwin|*BSD|CYGWIN*) sed="sed -E" ;;
  *)                   sed="sed -r" ;;
esac

exist_command() {
  type "$1" > /dev/null 2>&1
}

exist_all_commands() {
  for command in $@; do
    if ! exist_command $command; then
      return 1
    fi
  done
  return 0
}

exist_yum_repository() {
  yum repolist | grep --quiet "$1"
}

exist_user() {
  id "$1" > /dev/null 2>&1
}

prepare_environment() {
  if exist_all_commands $REQUIRED_COMMANDS; then
    return 0
  fi

  echo "Preparing the environment..."
  prepare_environment_in_$PLATFORM
  return 0
}

prepare_user() {
  if ! exist_user $USER; then
    echo ""
    echo "Preparing the user..."
    useradd -m $USER
  fi
}

setup_configuration_directory() {
  echo ""
  echo "Setting up the configuration directory..."

  [ ! -e $DROONGA_BASE_DIR ] &&
    mkdir $DROONGA_BASE_DIR

  config_file="$DROONGA_BASE_DIR/$NAME.yaml"
  if [ ! -e $config_file ]; then
    should_reconfigure_engine_host="false"
    should_reconfigure_host="false"

    if [ "$ENGINE_HOST" = "Auto Detect" ]; then
      ENGINE_HOST=""
      engine_config="/home/droonga-engine/droonga/droonga-engine.yaml"
      if [ -e $engine_config ]; then
        ENGINE_HOST=$(cat $engine_config | grep -E "^ *host *:" | \
                      cut -d ":" -f 2 | $sed -e "s/^ +| +\$//g")
      fi
      if [ "$ENGINE_HOST" != "" ]; then
        echo "The droonga-engine service is detected on this node."
        echo "The droonga-http-server is configured to be connected"
        echo "to this node ($ENGINE_HOST)."
      else
        if [ "$ENGINE_HOST" = "" ]; then
          ENGINE_HOST=$(hostname)
          should_reconfigure_engine_host="true"
        fi
        echo "This node is configured to connect to the droonga-engine node $ENGINE_HOST."
      fi
    fi

    [ "$HOST" = "Auto Detect" ] &&
      HOST=$(determine_hostname)

    if [ "$HOST" = "" ]; then
      HOST=$(hostname)
      should_reconfigure_host="true"
    fi
    echo "This node is configured with a hostname $HOST."

    if [ "$should_reconfigure_engine_host" = "true" -o \
         "$should_reconfigure_host" = "true" ]; then
      echo "********************** CAUTION!! **********************"
      echo "Installation process coudln't detect following parameters:"
      echo ""
      if [ "$should_reconfigure_engine_host" = "true" ]; then
        echo " * the hostname of the droonga-engine node to be connected"
      fi
      if [ "$should_reconfigure_host" = "true" ]; then
        echo " * the hostname of this node, which is accessible from "
        echo "   other nodes"
      fi
      echo ""
      echo "You may have to configure droonga-http-server manually,"
      echo "by following command line:"
      echo ""
      echo "  droonga-http-server-configure --reset-config"
      echo "*******************************************************"
    fi

    droonga-http-server-configure --quiet \
                                  --droonga-engine-host-name=$ENGINE_HOST \
                                  --receive-host-name=$HOST
  fi

  chown -R $USER:$GROUP $DROONGA_BASE_DIR
}


guess_global_hostname() {
  if hostname -d > /dev/null 2>&1; then
    domain=$(hostname -d)
    hostname=$(hostname -s)
    if [ "$domain" != "" ]; then
      echo "$hostname.$domain"
      return 0
    fi
  fi
  echo ""
  return 1
}

determine_hostname() {
  global_hostname=$(guess_global_hostname)
  if [ "$global_hostname" != "" ]; then
    echo "$global_hostname"
    return 0
  fi

  address=$(hostname -i | \
            $sed -e "s/127\.[0-9]+\.[0-9]+\.[0-9]+//g" \
                 -e "s/  +/ /g" \
                 -e "s/^ +| +\$//g" |\
            cut -d " " -f 1)
  if [ "$address" != "" ]; then
    echo "$address"
    return 0
  fi

  echo ""
  return 1
}


use_master_express_droonga() {
  mv package.json package.json.bak
  cat package.json.bak | \
    $sed -e "s;(express-droonga.+)\*;\1$EXPRESS_DROONGA_REPOSITORY_URL;" \
    > package.json
}

install_master() {
  tempdir=/tmp/install-$NAME
  mkdir $tempdir
  cd $tempdir

  if [ -d $NAME ]
  then
    cd $NAME
    git reset --hard
    git pull --rebase
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
  DOWNLOAD_URL=$SCRIPT_URL/$PLATFORM/$NAME
  curl -o $INSTALL_LOCATION $DOWNLOAD_URL
  chmod +x $INSTALL_LOCATION
}



# ====================== for Debian/Ubuntu ==========================

prepare_environment_in_debian() {
  apt-get update
  apt-get -y upgrade
  apt-get install -y nodejs nodejs-legacy npm

  if [ "$VERSION" = "master" ]; then
    apt-get install -y git
  fi
}

register_service_in_debian() {
  pid_dir=/var/run/$NAME
  mkdir -p $pid_dir
  chown -R $USER:$GROUP $pid_dir

  install_service_script /etc/init.d/$NAME debian
  update-rc.d $NAME defaults
}

# ====================== /for Debian/Ubuntu =========================



# ========================= for CentOS 7 ============================

prepare_environment_in_centos() {
  if ! exist_yum_repository epel; then
    # epel-release is not installed, so install it.
    yum -y install epel-release
    # however, we should disable it by default because
    # the system administrator won't expect to use it
    # in his daily use.
    epel_repo=/etc/yum.repos.d/epel.repo
    backup=/tmp/$(basename $epel_repo).bak
    mv $epel_repo $backup
    cat $backup | $sed -e "s/enabled=1/enabled=0/" \
      > $epel_repo
  fi
  yum -y --enablerepo=epel install npm

  if [ "$VERSION" = "master" ]; then
    yum -y install git
  fi
}

register_service_in_centos() {
  install_service_script /etc/rc.d/init.d/$NAME centos
  /sbin/chkconfig --add $NAME
}

# ========================= /for CentOS 7 ===========================



install() {
  prepare_environment

  echo ""
  if [ "$VERSION" = "master" ]; then
    echo "Installing $NAME from the git repository..."
    install_master
  else
    echo "Installing $NAME from npmjs.org..."
    npm install -g droonga-http-server
  fi

  prepare_user

  setup_configuration_directory

  echo ""
  echo "Registering $NAME as a service..."
  register_service_in_$PLATFORM

  echo ""
  echo "Successfully installed $NAME."
}

if [ "$EUID" != "0" ]; then
  echo "You must run this script as the root."
  exit 1
elif [ -e /etc/debian_version ] || [ -e /etc/debian_release ]; then
  PLATFORM=debian
elif [ -e /etc/centos-release ]; then
  PLATFORM=centos
else
  echo "Not supported platform. This script works only for Debian or CentOS."
  exit 255
fi

install $PLATFORM

exit 0
