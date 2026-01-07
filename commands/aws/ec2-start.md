---
argument-hint: "[profile] (defaults to 'stark')"
description: List stopped EC2 instances and interactively select one to start
allowed-tools: [Bash, AskUserQuestion]
---

Display all stopped EC2 instances and allow interactive selection to start a specific instance. All previous configurations and data are preserved.

## Implementation Steps

1. **Determine AWS Profile**: Use provided `profile` argument or default to 'stark' profile

2. **Query Stopped Instances**: Execute AWS CLI to list all stopped EC2 instances with detailed information:
   - Use `aws ec2 describe-instances --profile <profile> --filters "Name=instance-state-name,Values=stopped"`
   - Display formatted table showing: InstanceId, InstanceType, Name tag, PrivateIpAddress, previous PublicIpAddress (if any)

3. **Present Instance Selection**: Use AskUserQuestion to display available stopped instances with descriptive labels in format: `{Name} ({InstanceType}) - {PrivateIpAddress}`, allowing user to select which instance to start

4. **Start Selected Instance**: Execute `aws ec2 start-instances --profile <profile> --instance-ids <selected-instance-id>`

5. **Wait for Instance to Start**: Execute `aws ec2 wait instance-running --profile <profile> --instance-ids <selected-instance-id>` to wait until instance is fully running

6. **Display New Instance Information**: Query and show the updated instance details:
   - Instance name and ID
   - Current state (running)
   - Private IP address (unchanged)
   - **New Public IP address** (highlighted as this likely changed)
   - Reminder to update SSH/connection configurations with new IP

## Usage Examples

- `/aws:ec2-start` - Start a stopped EC2 instance using default 'stark' profile
- `/aws:ec2-start production` - Start a stopped EC2 instance in production profile
- `/aws:ec2-start dev` - Start a stopped EC2 instance in dev profile

## Usage Examples

```bash
# After starting, connect via SSH with new IP:
ssh -i your-key.pem ec2-user@<NEW_PUBLIC_IP>
```

## Notes

- All configurations, files, and installed software are preserved from before stopping
- Private IP address remains unchanged (important for VPC-internal services)
- Public IP address **will change** unless instance has an Elastic IP attached
- Instance resumes billing for runtime costs once started
- Starting typically takes 30-60 seconds to fully boot
- Requires AWS CLI configured with appropriate credentials and EC2 start permissions
- Use `/aws/ec2-stop` command when done to save costs
