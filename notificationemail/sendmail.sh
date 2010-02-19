#!/bin/bash -eu
# Given a recipients/ directory created by createmails.rb, fires off an email for each.

export REPLYTO=jefft@apache.org
for recip in recipients/*; do
(
cd "$recip"
echo mail -s "$(cat subject)" "$(cat to)"
cat body | mail -s "$(cat subject)" "$(cat to)"
# Avoid flooding things.
sleep 1
)
done
