#!/usr/bin/env bash
# Go development aliases and functions

# Quick commands
alias go-b='go build'
alias go-r='go run'
alias go-t='go test'
alias go-tv='go test -v'
alias go-f='go fmt ./...'
alias go-l='golangci-lint run'
alias go-m='go mod'
alias go-mt='go mod tidy'
alias go-mi='go mod init'
alias go-v='go version'

# Go get with update
alias go-gu='go get -u'

# Run tests with coverage
alias go-tc='go test -cover ./...'
alias go-tcv='go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out'

alias gv-v='goenv version'
alias gv-ls='goenv versions'
