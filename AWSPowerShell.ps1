Install-Module AWSPowerShell
import-Module AWSPowershell 

$UserSecretKey  = ""
$UserAccessKey = ""
$ProfileName  = "Amr_Tarek"
$region = "us-west-2"

# Create AWS session with credentials
$SetCredentials = Set-AWSCredential -AccessKey $UserAccessKey -SecretKey $UserSecretKey -StoreAs $ProfileName
$session = Initialize-AWSDefaults -Region $region -ProfileName $ProfileName


# Define VPC and Subnet details (Modify as needed)
$vpcName = "My-VPC"
$cidrBlock = "10.0.0.0/16"
$subnetName = "PublicSubnet"
$subnetCidrBlock = "10.0.1.0/24"

# Create the VPC
$vpcTag = @{ Key="Name"; Value=$vpcName }
$vpcTagSpec = New-Object Amazon.EC2.Model.TagSpecification
$vpcTagSpec.ResourceType = "vpc"
$vpcTagSpec.Tags.Add($vpcTag)
$vpc = New-EC2Vpc -CidrBlock $cidrBlock -TagSpecification $vpcTagSpec


Write-Host "VPC created successfully: $vpc.VpcId"


# Create the subnet within the VPC
$subnetTag = @{ Key="Name"; Value=$subnetName }
$subnetTagSpec = New-Object Amazon.EC2.Model.TagSpecification
$subnetTagSpec.ResourceType = "subnet"
$subnetTagSpec.Tags.Add($subnetTag)
$subnet = New-EC2Subnet -VpcId $vpc.VpcId -CidrBlock $subnetCidrBlock -TagSpecification $subnetTagSpec

Write-Host "Subnet created successfully: $subnet.SubnetId"
