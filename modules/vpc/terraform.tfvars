vpc_cidr_block              = "192.168.0.0/16"
vpc_name                    = "main"
public_subnets_cidr_blocks  = ["192.168.0.0/20", "192.168.16.0/20"]
private_subnets_cidr_blocks = ["192.168.32.0/20", "192.168.48.0/20"]
azs                         = ["us-east-1a", "us-east-1b"]