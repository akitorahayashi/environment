#!/usr/bin/env bash
# Go development aliases and functions

# Quick commands
alias gob='go build'
alias gor='go run'
alias got='go test'
alias gotv='go test -v'
alias gof='go fmt ./...'
alias gol='golangci-lint run'
alias gom='go mod'
alias gomt='go mod tidy'
alias gomi='go mod init'

# Go get with update
alias gogu='go get -u'

# Run tests with coverage
alias gotc='go test -cover ./...'
alias gotcv='go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out'

# Air live reload (if installed)
alias goair='air'

# Go version management
alias gov='go version'
alias goev='goenv version'
alias goel='goenv versions'
