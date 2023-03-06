# Update the apt package index and install packages

sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release openssh-server perl tzdata

# Add the Gitlab package repository and install the package
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash

sudo EXTERNAL_URL="http://gitlab.test-i-need-my-belt.com" apt-get install gitlab-ee