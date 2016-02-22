#!/bin/sh

git add *.md *.sh LICENSE
git add SOURCE/*.INC SOURCE/*.BAT SOURCE/*.PAS SOURCE/*.DEF

git commit -m "$*"
git push