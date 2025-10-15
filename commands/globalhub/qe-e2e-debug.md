---
argument-hint: [KUBECONFIG] [SPOKE_KUBECONFIG] [test-case-focus] (optional focus, e.g., RHACM4K-51185)
description: Run Global Hub QE E2E tests with comprehensive logging for troubleshooting
allowed-tools: [Bash, Read, Write, TodoWrite, Grep]
---

Run Global Hub QE E2E test cases with comprehensive logging collection from operator, manager, and agent components for troubleshooting purposes.

## Prerequisites

- KUBECONFIG path to global-hub cluster config
- SPOKE_KUBECONFIG path to hub1 (spoke) cluster config
- Kind cluster configured with NodePort service type
- Global Hub operator, manager, and agent deployed

## Implementation Steps

1. **Create task tracking list**
   - Track progress of log collection and test execution
   - Monitor each component's status

2. **Collect initial component logs**
   - Capture operator logs: `kubectl logs -n multicluster-global-hub deploy/multicluster-global-hub-operator --tail=500`
   - Capture manager logs: `kubectl logs -n multicluster-global-hub deploy/multicluster-global-hub-manager --tail=500`
   - Capture agent logs from spoke: `kubectl logs -n multicluster-global-hub-agent deploy/multicluster-global-hub-agent --tail=500`
   - Save all logs with timestamps for correlation

3. **Start real-time log monitoring**
   - Launch background log collection for operator: `kubectl logs -f deploy/multicluster-global-hub-operator`
   - Launch background log collection for manager: `kubectl logs -f deploy/multicluster-global-hub-manager`
   - Launch background log collection for agent on spoke cluster
   - Direct output to timestamped log files in `/tmp/`

4. **Execute E2E test case**
   - Set required environment variables:
     - `KUBECONFIG=$1`: path to global-hub cluster config
     - `SPOKE_KUBECONFIG=$2`: path to spoke cluster config
     - `GOPRIVATE=github.com/stolostron`
     - `SERVICE_TYPE=NODE_PORT`
   - Run ginkgo test with focus: `ginkgo -v --focus="$3" pkg/test/e2e` (if test case specified)
   - Run full e2e suite if no focus provided: `ginkgo -v -label-filter='e2e' pkg/test/e2e`
   - Capture test output to timestamped log file

5. **Monitor test execution**
   - Wait for test to complete or detect failures
   - Track test progress from output logs
   - Update task status as tests complete

6. **Analyze results and troubleshoot**
   - Check test outcome (PASSED/FAILED)
   - If failed, extract error messages from test logs
   - Search operator logs for ERROR patterns and resource conflicts
   - Look for "Operation cannot be fulfilled" errors indicating concurrency issues
   - Check manager logs for leader election issues or reconciliation errors
   - Review agent logs for connectivity or sync problems
   - Correlate timestamps between component logs and test failures

7. **Generate troubleshooting report**
   - Summarize test results with execution time
   - List all collected log file locations
   - Extract key errors from each component
   - Identify root cause based on error patterns:
     - Resource conflict errors → Operator concurrency issues
     - Leader election lost → Manager instability
     - Connection refused → Component communication issues
     - Timeout errors → Sync or propagation delays
   - Provide recommendations based on findings

8. **Clean up and save artifacts**
   - Stop background log collection processes
   - List all generated log files with sizes
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

Run specific test case:
```
/globalhub:qe-e2e-debug /path/to/global-hub/config /path/to/hub1/config RHACM4K-51185
```

Run full e2e suite:
```
/globalhub:qe-e2e-debug /path/to/global-hub/config /path/to/hub1/config
```

## Notes

- Works with Kind clusters using NodePort service type (set `SERVICE_TYPE=NODE_PORT`)
- Correlates logs across multiple components for root cause analysis
- Provides actionable troubleshooting recommendations
- All logs preserved for post-mortem analysis
