---
argument-hint: [KUBECONFIG] [SPOKE_KUBECONFIG] [test-case-focus] [--monitor-logs] (optional focus e.g., RHACM4K-51185, optional monitoring flag default=false)
description: Run Global Hub QE E2E tests with optional real-time log monitoring for troubleshooting
allowed-tools: [Bash, Read, Write, TodoWrite, Grep]
---

Run Global Hub QE E2E test cases with optional real-time log monitoring from operator, manager, and agent components for troubleshooting purposes.

## Prerequisites

- KUBECONFIG path to global-hub cluster config
- SPOKE_KUBECONFIG path to hub1 (spoke) cluster config
- Kind cluster configured with NodePort service type
- Global Hub operator, manager, and agent deployed

## Implementation Steps

1. **Parse arguments and create task tracking list**
   - Check if 4th argument contains `--monitor-logs` flag
   - Default to `false` if not specified
   - Track progress of log collection and test execution

2. **Collect initial component logs (if monitoring enabled)**
   - Skip this step if `--monitor-logs` not specified
   - Capture operator logs: `kubectl logs -n multicluster-global-hub deploy/multicluster-global-hub-operator --tail=500`
   - Capture manager logs: `kubectl logs -n multicluster-global-hub deploy/multicluster-global-hub-manager --tail=500`
   - Capture agent logs from spoke: `kubectl logs -n multicluster-global-hub-agent deploy/multicluster-global-hub-agent --tail=500`
   - Save all logs with timestamps for correlation

3. **Start real-time log monitoring (if monitoring enabled)**
   - Skip this step if `--monitor-logs` not specified
   - Launch background log collection for operator: `kubectl logs -f -n multicluster-global-hub deploy/multicluster-global-hub-operator`
   - Launch background log collection for manager: `kubectl logs -f -n multicluster-global-hub deploy/multicluster-global-hub-manager`
   - Launch background log collection for agent on spoke cluster
   - Direct output to timestamped log files in `/tmp/`

4. **Execute E2E test case**
   - Set required environment variables:
     - `export KUBECONFIG=$1`: path to global-hub cluster config
     - `export SPOKE_KUBECONFIG=$2`: path to spoke cluster config
     - `export SERVICE_TYPE=NODE_PORT` (only for Kind clusters; skip for environments with LoadBalancer support)
     - `export GOPRIVATE=github.com/stolostron` (if needed for private repos)
   - Run ginkgo test with focus: `ginkgo -v -timeout=30m -focus="$3" pkg/test/e2e` (if test case specified)
   - Run full e2e suite if no focus provided: `ginkgo -v -timeout=30m -label-filter='e2e' pkg/test/e2e`
   - Capture test output to timestamped log file

5. **Monitor test execution**
   - Wait for test to complete or detect failures
   - Track test progress from output logs
   - Update task status as tests complete

6. **Analyze results and troubleshoot**
   - Check test outcome (PASSED/FAILED)
   - If failed, extract error messages from test logs
   - If monitoring was enabled:
     - Search operator logs for ERROR patterns and resource conflicts
     - Look for "Operation cannot be fulfilled" errors indicating concurrency issues
     - Check manager logs for leader election issues or reconciliation errors
     - Review agent logs for connectivity or sync problems
     - Correlate timestamps between component logs and test failures
   - If monitoring was disabled, only analyze test output

7. **Generate troubleshooting report**
   - Summarize test results with execution time
   - If monitoring was enabled:
     - List all collected log file locations
     - Extract key errors from each component
     - Identify root cause based on error patterns:
       - Resource conflict errors → Operator concurrency issues
       - Leader election lost → Manager instability
       - Connection refused → Component communication issues
       - Timeout errors → Sync or propagation delays
     - Provide recommendations based on findings
   - If monitoring was disabled, provide basic test result summary

8. **Clean up and save artifacts**
   - If monitoring was enabled, stop background log collection processes
   - List all generated log files with sizes (if any)
   - Provide summary of findings and next steps

## Error Pattern Analysis

The workflow analyzes common issues:

- **Operator Conflicts**: Multiple `"Operation cannot be fulfilled on kafkausers"` errors indicate retry mechanism issues
- **Manager Issues**: `"leader election lost"` suggests pod restarts or instability
- **Agent Problems**: Connection errors or heartbeat failures indicate spoke cluster issues
- **Test Timeouts**: Long execution times (>600s) suggest configuration sync delays

## Log File Naming Convention

All logs use timestamp format: `YYYYMMDD-HHMMSS`
- Operator: `/tmp/operator-[test|realtime]-TIMESTAMP.log`
- Manager: `/tmp/manager-[logs|realtime]-TIMESTAMP.log`
- Agent: `/tmp/agent-[logs|realtime]-TIMESTAMP.log`
- E2E Test: `/tmp/e2e-[testname]-TIMESTAMP.log`

## Example Usage

Run specific test case without log monitoring:
```
/globalhub:qe-e2e-debug /path/to/global-hub/config /path/to/hub1/config RHACM4K-51185
```

Run specific test case with log monitoring:
```
/globalhub:qe-e2e-debug /path/to/global-hub/config /path/to/hub1/config RHACM4K-51185 --monitor-logs
```

Run full e2e suite without log monitoring:
```
/globalhub:qe-e2e-debug /path/to/global-hub/config /path/to/hub1/config
```

Run full e2e suite with log monitoring:
```
/globalhub:qe-e2e-debug /path/to/global-hub/config /path/to/hub1/config "" --monitor-logs
```

## Notes

- `SERVICE_TYPE=NODE_PORT` is only required for Kind clusters; environments with LoadBalancer support don't need this variable
- Log monitoring (`--monitor-logs`) is optional and disabled by default to improve test execution speed
- Correlates logs across multiple components for root cause analysis when monitoring is enabled
- Provides actionable troubleshooting recommendations
- All logs preserved for post-mortem analysis
