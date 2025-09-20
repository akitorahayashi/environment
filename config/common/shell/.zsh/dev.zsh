# Define development aliases for commands
# Usage: dev_alias_as <base_command> <prefix> [run_prefix]
dev_alias_as() {
    local base_command="$1"
    local prefix="$2"
    local run_prefix="$3"

    # Basic command alias
    alias "${prefix}=${base_command}"

    # Common development commands
    alias "${prefix}-h=${base_command} ${run_prefix} help"
    alias "${prefix}-s=${base_command} ${run_prefix} setup"
    alias "${prefix}-f=${base_command} ${run_prefix} format"
    alias "${prefix}-l=${base_command} ${run_prefix} lint"
    alias "${prefix}-r=${base_command} ${run_prefix} run"
    alias "${prefix}-t=${base_command} ${run_prefix} test"
    alias "${prefix}-cln=${base_command} ${run_prefix} clean"

    # Combined format and lint
    alias "${prefix}-fl=${base_command} ${run_prefix} format && ${base_command} ${run_prefix} lint"

    # Test variations
    alias "${prefix}-ut=${base_command} ${run_prefix} unit-test"
    alias "${prefix}-uit=${base_command} ${run_prefix} ui-test"
    alias "${prefix}-et=${base_command} ${run_prefix} e2e-test"
    alias "${prefix}-lt=${base_command} ${run_prefix} local-test"
    alias "${prefix}-dt=${base_command} ${run_prefix} docker-test"
    alias "${prefix}-sqt=${base_command} ${run_prefix} sqlt-test"
    alias "${prefix}-pst=${base_command} ${run_prefix} pstg-test"
    alias "${prefix}-sdt=${base_command} ${run_prefix} sdk-test"
    alias "${prefix}-pet=${base_command} ${run_prefix} perf-test"
    alias "${prefix}-it=${base_command} ${run_prefix} intg-test"
    alias "${prefix}-bt=${base_command} ${run_prefix} build-test"
}