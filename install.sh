#!/usr/bin/env bash

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do
  case $1 in
  --dev)
    APP_ENV="development"
    shift
    ;;
  esac
  shift
done
if [[ "$1" == '--' ]]; then shift; fi

. /etc/os-release

distros="$ID $ID_LIKE"
isRhelBased=false

for word in $distros
do
    if [[ $word == "rhel" ]]; then
      isRhelBased=true
    fi
done


if [[ $isRhelBased != true ]]; then
  echo "Ansible installation is only supported on RHEL based distributions."
  exit 0
fi

majorVersion=$(rpm -q --queryformat '%{RELEASE}' rpm | grep -o [[:digit:]]*\$)
if [[ $majorVersion -lt 8 ]]; then
  echo "RHEL 8+ is required"
  exit 0
fi

sudo dnf update
sudo dnf install -y ansible python3-pip python3-mysqlclient

APP_ENV="${APP_ENV:-production}"

if ! command -v opam &> /dev/null
then
    echo "Installing OPAM"
    bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"
fi


echo "Installing AzuraCast (Environment: $APP_ENV)"
ansible-galaxy collection install community.general
ansible-playbook ansible/deploy.yml --inventory=ansible/hosts --extra-vars "app_env=$APP_ENV"
