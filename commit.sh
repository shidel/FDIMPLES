#!/bin/sh

git add *.md *.sh LICENSE
git add *.INC *.BAT *.PAS *.DEF

git commit -m "$*"
git push