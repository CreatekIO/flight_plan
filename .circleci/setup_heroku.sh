#!/bin/bash
set -ex

apk --update add openssl # required for wget
apk --update add openssh # required for ssh-keyscan

ssh-keyscan -H heroku.com >> ~/.ssh/known_hosts

wget https://cli-assets.heroku.com/branches/stable/heroku-linux-amd64.tar.gz

mkdir -p /usr/local/lib /usr/local/bin
tar -xzf heroku-linux-amd64.tar.gz -C /usr/local/lib
ln -s /usr/local/lib/heroku/bin/heroku /usr/local/bin/heroku

cat > ~/.netrc << EOF
machine api.heroku.com
  login $HEROKU_LOGIN
  password $HEROKU_API_KEY
EOF

cat >> ~/.ssh/config << EOF
VerifyHostKeyDNS yes
StrictHostKeyChecking no
EOF
