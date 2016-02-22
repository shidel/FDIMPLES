#!/bin/sh

git add *.md *.sh LICENSE
git add SOURCE/*.INC *.BAT SOURCE/*.PAS SOURCE/*.DEF SOURCE/*.LSM

git commit -m "$*"
git push