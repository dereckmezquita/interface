#!/usr/bin/env bash

# if $1 does not match either check or install
if [[ $1 != "check" ]] && [[ $1 != "install" ]] && [[ $1 != "check-install" ]]; then
    echo "Usage: package-management.sh [check|install|check-install]"
fi

if [[ $1 == "check" ]]; then
    Rscript -e "devtools::check()"
fi

if [[ $1 == "install" ]]; then
    # get name of current directory
    PROJECT_DIR=$(pwd)
    PKGNAME=$(basename $(pwd))
    cd ..
    R CMD build $PKGNAME
    R CMD INSTALL --no-multiarch --with-keep.source $PKGNAME
    cd $PROJECT_DIR
fi

if [[ $1 == "check-install" ]]; then
    Rscript -e "devtools::check()"
    # get name of current directory
    PROJECT_DIR=$(pwd)
    PKGNAME=$(basename $(pwd))
    cd ..
    R CMD build $PKGNAME
    R CMD INSTALL --no-multiarch --with-keep.source $PKGNAME
    cd $PROJECT_DIR
fi
