# Copyright (C) 2014-2015 Droonga Project
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
DOWNLOAD_URL_BASE=https://raw.githubusercontent.com/droonga/$NAME
REPOSITORY_URL=https://github.com/droonga/$NAME.git
USER=$NAME
GROUP=droonga
DROONGA_BASE_DIR=/home/$USER/droonga
TEMPDIR=/tmp/install-$NAME

EXPRESS_DROONGA_REPOSITORY_URL=git://github.com/droonga/express-droonga.git#master

: ${VERSION:=release}
: ${HOST:=Auto Detect}
: ${PORT:=10041}
: ${ENGINE_HOST:=Auto Detect}
: ${ENGINE_PORT:=Auto Detect}

NODEJS_BASE_DIR=/home/$USER/node
NODEJS_COMMAND=$NODEJS_BASE_DIR/bin/node
NODEJS_BASE_URL=https://nodejs.org/download/release

: ${NODEJS_VERSION:=v0.12.9}
: ${NODEJS_OS:=linux}
: ${NODEJS_ARCH:=x64}

NODEJS_DOWNLOAD_URL=$NODEJS_BASE_URL/$NODEJS_VERSION/node-$NODEJS_VERSION-$NODEJS_OS-$NODEJS_ARCH.tar.gz

case $(uname) in
  Darwin|*BSD|CYGWIN*) sed="sed -E" ;;
  *)                   sed="sed -r" ;;
esac

ensure_root() {
  if [ "$EUID" != "0" ]; then
    echo "You must run this script as the root."
    exit 1
  fi
}

guess_platform() {
  if [ -e /etc/debian_version ] || [ -e /etc/debian_release ]; then
    echo "debian"
    return 0
  elif [ -e /etc/centos-release ]; then
    echo "centos"
    return 0
  fi
  return 1
}

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
  if ! yum --enablerepo=$1 repolist; then
    return 1
  fi
  yum --enablerepo=$1 repolist | grep --quiet "$1"
}

exist_user() {
  id "$1" > /dev/null 2>&1
}

prepare_user() {
  echo ""
  echo "Preparing the user..."

  groupadd $GROUP

  if ! exist_user $USER; then
    useradd -m $USER
  fi

  usermod -G $GROUP $USER
  return 0
}

install_nodejs() {
  echo "Installing Node.js $NODE_VERSION $NODE_ARCH..."
  mkdir $NODEJS_BASE_DIR
  curl $NODEJS_DOWNLOAD_URL | tar -xz --strip-components 1 -C $NODEJS_BASE_DIR
  chown -R $USER:$GROUP $NODEJS_BASE_DIR
}

detect_engine_config() {
  local config_key=$1
  local config_value=""
  local engine_config="/home/droonga-engine/droonga/droonga-engine.yaml"
  if [ -e $engine_config ]; then
    config_value=$(cat $engine_config | grep -E "^ *$config_key *:" | \
                   cut -d ":" -f 2 | $sed -e "s/^ +| +\$//g")
  fi
  echo $config_value
}

setup_configuration_directory() {
  echo ""
  echo "Setting up the configuration directory..."

  [ ! -e $DROONGA_BASE_DIR ] &&
    mkdir $DROONGA_BASE_DIR

  local config_file="$DROONGA_BASE_DIR/$NAME.yaml"
  if [ ! -e $config_file ]; then
    local should_reconfigure_engine_host="false"
    local should_reconfigure_host="false"

    if [ "$ENGINE_HOST" = "Auto Detect" ]; then
      ENGINE_HOST=$(detect_engine_config host)
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

    if [ "$ENGINE_PORT" = "Auto Detect" ]; then
      ENGINE_PORT=$(detect_engine_config port)
      if [ "$ENGINE_PORT" != "" ]; then
        echo "The droonga-engine service is detected on this node."
        echo "The droonga-http-server is configured to be connected"
        echo "to this node with the port $ENGINE_PORT."
      else
        ENGINE_PORT=10031
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

    # we should use --no-prompt instead of --quiet, for droonga-http-server 1.0.9 and later.
    droonga-http-server-configure --quiet \
                                  --droonga-engine-host-name=$ENGINE_HOST \
                                  --droonga-engine-port=$ENGINE_PORT \
                                  --receive-host-name=$HOST \
                                  --port=$PORT
    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to configure $NAME!"
      exit 1
    fi
  fi

  chown -R $USER:$GROUP $DROONGA_BASE_DIR
}


guess_global_hostname() {
  if hostname -d > /dev/null 2>&1; then
    local domain=$(hostname -d)
    local hostname=$(hostname -s)
    if [ "$domain" != "" ]; then
      echo "$hostname.$domain"
      return 0
    fi
  fi
  echo ""
  return 1
}

determine_hostname() {
  local global_hostname=$(guess_global_hostname)
  if [ "$global_hostname" != "" ]; then
    echo "$global_hostname"
    return 0
  fi

  local address=$(hostname -i | \
                  $sed -e "s/127\.[0-9]+\.[0-9]+\.[0-9]+//g" \
                       -e "s/[0-9a-f:]+%[^ ]+//g" \
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
    $sed -e "s;(express-droonga\"[^:]*:[^\"]*\")[^\"]+;\1$EXPRESS_DROONGA_REPOSITORY_URL;" \
    > package.json
}

install_from_npm() {
  sudo -u $USER /bin/bash -c "
  export PATH=$NODEJS_BASE_DIR/bin:$PATH
  npm install -g droonga-http-server
  "
}

install_from_repository() {
  cd $TEMPDIR

  if [ -d $NAME ]
  then
    cd $NAME
    git reset --hard
    git pull --rebase
    git checkout $VERSION
    use_master_express_droonga
    chown -R $USER .
    sudo -u $USER /bin/bash -c "
    export PATH=$NODEJS_BASE_DIR/bin:$PATH
    npm update
    "
  else
    git clone $REPOSITORY_URL
    cd $NAME
    git checkout $VERSION
    use_master_express_droonga
  fi
  chown -R $USER .
  sudo -u $USER /bin/bash -c "
  export PATH=$NODEJS_BASE_DIR/bin:$PATH
  npm install -g
  "
  rm package.json
  mv package.json.bak package.json
}

download_url() {
  if [ "$VERSION" != "release" ]; then
    echo "$DOWNLOAD_URL_BASE/master/$1"
  else
    echo "$DOWNLOAD_URL_BASE/v$(installed_version)/$1"
  fi
}

installed_version() {
  $NAME --version
}



# ====================== for Debian/Ubuntu ==========================
prepare_environment_in_debian() {
  apt-get update
  apt-get install -y curl sudo

  if [ "$VERSION" != "release" ]; then
    apt-get install -y git
  fi
}
# ====================== /for Debian/Ubuntu =========================



# ========================= for CentOS 7 ============================
prepare_environment_in_centos() {
  yum -y makecache
  yum -y install curl sudo

  if [ "$VERSION" != "release" ]; then
    yum -y install git
  fi
}
# ========================= /for CentOS 7 ===========================



install() {
  mkdir -p $TEMPDIR

  echo "Preparing the environment..."
  prepare_environment_in_$PLATFORM

  prepare_user

  install_nodejs

  echo ""
  if [ "$VERSION" != "release" ]; then
    echo "Installing $NAME from the git repository..."
    install_from_repository
  else
    echo "Installing $NAME from npmjs.org..."
    install_from_npm
  fi

  if ! exist_command $NODEJS_BASE_DIR/bin/droonga-http-server; then
    echo "ERROR: Failed to install $NAME!"
    exit 1
  fi

  curl -s -o $TEMPDIR/functions.sh $(download_url "install/$PLATFORM/functions.sh")
  if ! source $TEMPDIR/functions.sh; then
    echo "ERROR: Failed to download post-installation script!"
    exit 1
  fi
  if ! exist_command register_service; then
    echo "ERROR: Downloaded post-installation script is broken!"
    exit 1
  fi

  setup_configuration_directory

  echo ""
  echo "Registering $NAME as a service..."
  # this function is defined by the downloaded "functions.sh"!
  register_service $NAME $USER $GROUP

  echo ""
  echo "Successfully installed $NAME."
}

ensure_root

PLATFORM=$(guess_platform)
if [ "$PLATFORM" = "" ]; then
  echo "Not supported platform."
  exit 255
fi

install

exit 0
