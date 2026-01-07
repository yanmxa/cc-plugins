---
argument-hint: "[profile] (defaults to 'stark')"
description: List running EC2 instances and interactively select one to stop
allowed-tools: [Bash, AskUserQuestion]
---

Display all running EC2 instances and allow interactive selection to stop a specific instance. Preserves all configurations and data for future restart.

## Implementation Steps

1. **Determine AWS Profile**: Use provided `profile` argument or default to 'stark' profile

2. **Query Running Instances**: Execute AWS CLI to list all running EC2 instances with detailed information:
   - Use `aws ec2 describe-instances --profile <profile> --filters "Name=instance-state-name,Values=running"`
   - Display formatted table showing: InstanceId, InstanceType, Name tag, PrivateIpAddress, PublicIpAddress, LaunchTime

3. **Present Instance Selection**: Use AskUserQuestion to display available running instances with descriptive labels in format: `{Name} ({InstanceType}) - {PublicIpAddress}`, allowing user to select which instance to stop

4. **Stop Selected Instance**: Execute `aws ec2 stop-instances --profile <profile> --instance-ids <selected-instance-id>`

5. **Confirm Results**: Display success message showing:
   - Instance name and ID being stopped
   - Previous state and current state (stopping)
   - Reminder that all data and configurations are preserved
   - Note about cost savings (no instance runtime charges while stopped)

## Usage Examples

- `/aws:ec2-stop` - Stop an EC2 instance using default 'stark' profile
- `/aws:ec2-stop production` - Stop an EC2 instance in production profile
- `/aws:ec2-stop dev` - Stop an EC2 instance in dev profile

## Notes

- Stopping preserves all EBS volumes, configurations, and installed software
- Stopped instances only incur EBS storage costs, not instance runtime costs
- Instance can be restarted anytime with `/aws/ec2-start` command
- Private IP address will remain the same after restart
- Public IP address may change after restart (unless using Elastic IP)
- Requires AWS CLI configured with appropriate credentials and EC2 stop permissions
