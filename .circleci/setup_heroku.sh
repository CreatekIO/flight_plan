#!/bin/bash
set -ex

apk --update add openssh # required for ssh-keyscan

ssh-keyscan -H heroku.com >> ~/.ssh/known_hosts

cat >> ~/.ssh/config << EOF
VerifyHostKeyDNS yes
StrictHostKeyChecking no
EOF
