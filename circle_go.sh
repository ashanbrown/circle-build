#!/usr/bin/env bash
set -uex

# This script exists because CircleCI doesn't allow us to set any kind of global environment shared across
# projects.

GOVERSION=1.8.3
GODIST="go${GOVERSION}.linux-amd64.tar.gz"
REPO_NAME=${1:-CIRCLE_PROJECT_REPONAME}
REPO_LOCAL=${2:-CIRCLE_PROJECT_REPONAME}

#This directory is cached by CircleCI:
LOCAL_GOPATH=~/.go_workspace

get_go() {
    mkdir -p download
    test -e download/${GODIST} || curl -o download/${GODIST} https://storage.googleapis.com/golang/${GODIST}
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf download/${GODIST}
}

install_go() {
    rm -rf ${LOCAL_GOPATH}/github.com/launchdarkly/${REPO_NAME}
    mkdir -p ${LOCAL_GOPATH}/src/github.com/launchdarkly/
    rm -rf ${LOCAL_GOPATH}/.cache/govendor
    ln -s ~/${REPO_LOCAL} ${LOCAL_GOPATH}/src/github.com/launchdarkly/${REPO_NAME}
    GOPATH=${LOCAL_GOPATH}
    go get github.com/GoASTScanner/gas # get the Go AST scanner
    go get github.com/GeertJohan/fgt
    go get github.com/kardianos/govendor
    go env
}

# For formatting, linting, and other analysis
go_enforce() {
    cd_to_proper_go_dir
    set -uxe
#    fgt govendor status
    GO_ENFORCE_CMD="gas -skip=**vendor/** -exclude=G101,G104 -out=${CIRCLE_ARTIFACTS}/gas-results.txt ./..."
    echo ${GO_ENFORCE_CMD}
    ${GO_ENFORCE_CMD}
}

go_test() {
    cd_to_proper_go_dir
    GO_TEST_CMD="govendor test -v +local"
    echo ${GO_TEST_CMD}
    ${GO_TEST_CMD}
}

go_build() {
    cd_to_proper_go_dir
    GO_BUILD_CMD="govendor build +local"
    echo ${GO_BUILD_CMD}
    ${GO_BUILD_CMD}
}

#changes the working dir to the go tool-friendly symlink in our local gopath.
cd_to_proper_go_dir() {
    GOPATH=${LOCAL_GOPATH}
    cd ${LOCAL_GOPATH}/src/github.com/launchdarkly/${REPO_NAME}
}
