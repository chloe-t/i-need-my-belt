# Docker Installation Scripts for Ubuntu
# From Docker website:
# https://docs.docker.com/engine/install/ubuntu/

# Update the apt package index and install packages to allow apt to use a repository over HTTPS:

sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release openssh-server perl

# Add the Gitlab package repository and install the package
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash

sudo EXTERNAL_URL="http://gitlab.i-need-my-belt.com" apt-get install gitlab-ee