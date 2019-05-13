#!/usr/bin/env bash

# Remove .gitignore files from the libraries folder in order to commit all generated files within the libraries.
# F.x. VueJs excludes dist/*.js files that makes it impossible to use.
FOLDERS=('docroot/libraries')

for folder in $FOLDERS
do
  echo  "Removing .gitignore files from $folder folder to avoid possible git issues."
  find $folder -type f -name '.gitignore'  -exec rm {} + > /dev/null 2>&1
done
