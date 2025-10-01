#!/bin/bash
# shellcheck disable=SC2139
# Define development aliases for commands
# Usage: dev_alias_as <base_command> <prefix> [run_prefix]
dev_alias_as() {
	local base_command="$1"
	local prefix="$2"
	local run_prefix="${3:-}" # Make run_prefix optional, default to empty

	# Basic command alias
	alias "${prefix}=${base_command}"

	# Helper function to build command with optional run_prefix
	local cmd_prefix="${base_command}"
	if [ -n "$run_prefix" ]; then
		cmd_prefix="${base_command} ${run_prefix}"
	fi

	# Common development commands
	alias "${prefix}-h=\${cmd_prefix} help"
	alias "${prefix}-s=\${cmd_prefix} setup"
	alias "${prefix}-f=\${cmd_prefix} format"
	alias "${prefix}-l=\${cmd_prefix} lint"
	alias "${prefix}-r=\${cmd_prefix} run"
	alias "${prefix}-t=\${cmd_prefix} test"
	alias "${prefix}-cln=\${cmd_prefix} clean"

	# Combined format and lint
	alias "${prefix}-fl=\${cmd_prefix} format && \${cmd_prefix} lint"

	# Test variations
	alias "${prefix}-ut=\${cmd_prefix} unit-test"
	alias "${prefix}-uit=\${cmd_prefix} ui-test"
	alias "${prefix}-et=\${cmd_prefix} e2e-test"
	alias "${prefix}-lt=\${cmd_prefix} local-test"
	alias "${prefix}-dt=\${cmd_prefix} docker-test"
	alias "${prefix}-sqt=\${cmd_prefix} sqlt-test"
	alias "${prefix}-pst=\${cmd_prefix} pstg-test"
	alias "${prefix}-sdt=\${cmd_prefix} sdk-test"
	alias "${prefix}-pet=\${cmd_prefix} perf-test"
	alias "${prefix}-it=\${cmd_prefix} intg-test"
	alias "${prefix}-bt=\${cmd_prefix} build-test"
}
