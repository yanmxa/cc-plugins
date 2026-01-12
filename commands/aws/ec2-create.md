---
argument-hint: "[ami-name] [instance-type] [disk-size-gb] [key-name] (optional arguments)"
description: Create an AWS EC2 instance with customizable AMI, instance type, disk size, and key pair
allowed-tools: [Bash, TodoWrite]
---

Create an AWS EC2 instance with specified AMI name, instance type, disk size, and SSH key pair. All parameters are customizable with sensible defaults.

## Default Configuration
- **AMI Name**: myan-dev-centos10
- **Instance Type**: t3.xlarge
- **Disk Size**: 120GB (gp3)
- **Key Pair**: myan
- **Network**: Public subnet with auto-assigned public IP
- **Security Group**: Auto-created with SSH (port 22) access from 0.0.0.0/0

## Implementation Steps

1. **Parse Arguments**: Extract AMI name (default: `$1` or "myan-dev-centos10"), instance type (default: `$2` or "t3.xlarge"), disk size (default: `$3` or "120"), and key name (default: `$4` or "myan")

2. **Lookup AMI ID**: Use `aws ec2 describe-images` to find the AMI ID based on the provided AMI name

3. **Get Network Configuration**: Query default VPC and available subnets with public IP auto-assignment enabled

4. **Create or Get Security Group**:
   - Check if security group "ssh-access" exists in the VPC
   - If not exists, create new security group with description "Allow SSH access"
   - Ensure ingress rule allows TCP port 22 from 0.0.0.0/0
   - Store security group ID for instance creation

5. **Create EC2 Instance**: Execute `aws ec2 run-instances` with:
   - Specified AMI ID
   - Configured instance type
   - Block device mapping with specified disk size (gp3 volume type)
   - SSH key pair for access
   - Selected subnet (preferably one with MapPublicIpOnLaunch=true)
   - Security group ID created/retrieved in previous step
   - Instance name tag for easy identification

6. **Display Instance Details**: Show instance ID, state, private IP, public DNS hostname (once assigned), and SSH connection command using the DNS hostname format (e.g., `ssh -i "myan.pem" ec2-user@ec2-54-219-67-11.us-west-1.compute.amazonaws.com`)

## Usage Examples

```bash
# Use all defaults (myan-dev-centos10, t3.xlarge, 120GB, myan key)
/aws:create-ec2

# Custom AMI name only
/aws:create-ec2 my-custom-ami

# Custom AMI and instance type
/aws:create-ec2 my-custom-ami t3.2xlarge

# Full customization
/aws:create-ec2 my-custom-ami t3.2xlarge 200 my-key-pair
```

## Notes
- Requires AWS CLI configured with appropriate credentials and default region
- The instance will be created in a public subnet with automatic public IP assignment
- Automatically creates/reuses a security group with SSH access enabled
- Uses gp3 volume type for better performance and cost efficiency
- Instance will be tagged with a descriptive name for easy identification
- Public IP and DNS hostname are assigned after the instance enters "running" state
- SSH connection command will be displayed using the public DNS hostname format after instance creation
- Security group allows SSH from anywhere (0.0.0.0/0) - consider restricting to specific IPs for production use
- To check instance status and public IP after creation:
  ```bash
  aws ec2 describe-instances --instance-ids <instance-id> --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress]' --output table
  ```
