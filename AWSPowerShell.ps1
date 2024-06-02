Install-Module AWSPowerShell
import-Module AWSPowershell 
Install-Module -Name AWS.Tools.Installer
Import-Module AWS.Tools.Installer

. .\credentials.ps1

# Remove-Module -Name Functions
$ProfileName  = "Amr_Tarek"
$region = "us-west-2"

# Create AWS session with credentials
$SetCredentials = Set-AWSCredential -AccessKey $UserAccessKey -SecretKey $UserSecretKey -StoreAs $ProfileName
$session = Initialize-AWSDefaults -Region $region -ProfileName $ProfileName

# Configure AWS client with credentials and region
$awsClientConfig = New-Object Amazon.WebServices.ClientConfig -DefaultRequestTimeout 300
$awsClientConfig.Credentials = $SetCredentials
$awsClientConfig.RegionEndpoint = $region

###### Functions ######
function Greeting {
  Clear-Host
  Write-Host "   +------------------------------------------------+"
  Write-Host "   |                                                |"
  Write-Host "   |      Wellcome to my AWSPowerShell project      |"
  Write-Host "   |              Made by 💗 Amr Tarek              |"
  Write-Host "   |                                                |"
  Write-Host "   +------------------------------------------------+"
}

function close {
  Clear-Host
  Write-Host "+----------------------------------------+"
  Write-Host "|                                        |"
  Write-Host "|                 Bye 👋                 |"
  Write-Host "|       We hope to see you again 😇      |"
  Write-Host "|                                        |"
  Write-Host "+----------------------------------------+"
  break
  
}

function Show-Menu() {
  Write-Host "Please select an option:"
  Write-Host "  (1) Create VPC"
  Write-Host "  (2) List VPC"
  Write-Host "  (3) Create VPC Peering"
  Write-Host "  (4) Destroy VPC"
  Write-Host "  (Q) Quit"
}

function MainMenue{
  # $choice = ""
  Greeting
  do {
    Show-Menu
    $choice = Read-Host "Chose"
    switch ($choice) {
      "1" { CreateVPC }
      "2" { ListVpc }
      "3" { CreateVpcPeering }
      "4" { DestroyVPC }
      "Q" { close }
      default { Write-Host "Invalid choice. Please try again." }
    }
  } while ($choice -ne "Q")

  Write-Host "Exiting the menu..."
}

function CreateVPC {
  Write-Host "You selected CreateVPC."
  $continue= Read-Host "Do you want to continue(Y/N): "
  if ( $continue -in "Y","y","YES","yes"){
    # Define VPC and Subnet details
    $vpcName = Read-Host "Please enter new VPC Name " #"My-VPC"
    $cidrBlock = Read-Host "Please enter VPC Cider Block " #"10.0.0.0/16"
    $subnetName1 = Read-Host "Please enter PublicSubnet Name " #"PublicSubnet"
    $subnetName2 = Read-Host "Please enter PrivatSubnet Name " #"PrivatSubnet"
    $subnetCidrBlock1 = Read-Host "Please enter PublicSubnet Cider Block " #"10.0.1.0/24"
    $subnetCidrBlock2 = Read-Host "Please enter PrivatSubnet Cider Block " #"10.0.2.0/24"

    # Create the VPC

    $vpc = New-EC2Vpc -CidrBlock $cidrBlock -TagSpecification @{ResourceType="vpc";Tags=[Amazon.EC2.Model.Tag]@{Key="Name";Value=$vpcName}}


    Write-Host "VPC created successfully: $($vpc.VpcId)" -ForegroundColor Green


    # Create the subnets

    $subnet1 = New-EC2Subnet -VpcId $vpc.VpcId -CidrBlock $subnetCidrBlock1 -TagSpecification @{ResourceType="subnet";Tags=[Amazon.EC2.Model.Tag]@{Key="Name";Value=$subnetName1}}

    Write-Host "Subnet created successfully: $($subnet1.SubnetId)" -ForegroundColor Green



    $subnet2 = New-EC2Subnet -VpcId $vpc.VpcId -CidrBlock $subnetCidrBlock2 -TagSpecification @{ResourceType="subnet";Tags=[Amazon.EC2.Model.Tag]@{Key="Name";Value=$subnetName2}}

    Write-Host "Subnet created successfully: $($subnet2.SubnetId)" -ForegroundColor Green

    # Create internet gateway

    $igw = New-EC2InternetGateway -TagSpecification @{ResourceType="internet-gateway";Tags=[Amazon.EC2.Model.Tag]@{Key="Name";Value="my-IGW"}}

    # Attach internet gateway
    Add-EC2InternetGateway -VpcId $vpc.VpcId -InternetGatewayId $igw.InternetGatewayId

    Write-Host "igw created and attached successfully: $($igw.InternetGatewayId)" -ForegroundColor Green



    ## Create EC2 client object with configured credentials
    # $ec2Client = New-Object Amazon.EC2.AmazonEC2Client($awsClientConfig)
    ## Allocate Elastic IP using EC2 client
    # $allocateIpResult = $ec2Client.AllocateAddress()
    # $eipAllocationId = $allocateIpResult.AllocationId

    # Create an elastic IP :

    $MyElasticIP = New-EC2Address -Domain Vpc -TagSpecification @{ResourceType="elastic-ip";Tags=[Amazon.EC2.Model.Tag]@{Key="Name";Value="MyElasticIP"}}


    Write-Host "Created elastic IP : $($MyElasticIP.AllocationId)" -ForegroundColor Green

    # Create natgateway

    $ngw = New-EC2NatGateway -SubnetId $subnet1.SubnetId -AllocationId $MyElasticIP.AllocationId -TagSpecification @{ResourceType="natgateway";Tags=[Amazon.EC2.Model.Tag]@{Key="Name";Value="my-NGW"}}

    Write-Host "NatGatway created : $($ngw.NatGateway.NatGatewayId)" -ForegroundColor Green
    # Create Route Tables

    $publicRouteTable = New-EC2RouteTable -VpcId $vpc.VpcId -TagSpecification @{ResourceType="route-table";Tags=[Amazon.EC2.Model.Tag]@{Key="Name";Value="public-rt"}}


    $privateRouteTable = New-EC2RouteTable -VpcId $vpc.VpcId -TagSpecification @{ResourceType="route-table";Tags=[Amazon.EC2.Model.Tag]@{Key="Name";Value="private-rt"}}

    # Associate Public Subnet with Public Route Table
    $rtbassoc1= Register-EC2RouteTable -RouteTableId $publicRouteTable.RouteTableId -SubnetId $subnet1.SubnetId

    # Associate Private Subnet with Private Route Table
    $rtbassoc2= Register-EC2RouteTable -RouteTableId $privateRouteTable.RouteTableId -SubnetId $subnet2.SubnetId

    # Create Route for Public Route Table (Internet access)
    $route1= New-EC2Route -RouteTableId $publicRouteTable.RouteTableId -DestinationCidrBlock "0.0.0.0/0" -GatewayId $igw.InternetGatewayId

    # Create Route for Private Route Table (NAT Gateway access)
    Start-Sleep -Seconds 60
    $route2= New-EC2Route -RouteTableId $privateRouteTable.RouteTableId -DestinationCidrBlock "0.0.0.0/0" -NatGatewayId  $ngw.NatGateway.NatGatewayId
    # $maxRetries = 5
    # $sleepInterval = 60
    # $retryCount = 0
    # $privateRouteTable.RouteTableId  $ngw.NatGateway.NatGatewayId
    # $ngwInfo= Get-EC2NatGateway -Filter @{ Name='vpc-id'; Values=$vpc.VpcId }
    # do{
    #   if ($ngwInfo.State -eq "available") {
    #     $route2= New-EC2Route -RouteTableId   "rtb-0330d195e47084545" -DestinationCidrBlock "0.0.0.0/0" -NatGatewayId  "nat-01cf8c3f4cb1d2c96"
    #   }else {
    #     $retryCount++
    #     Start-Sleep -Seconds $sleepInterval
    #   }
    # }while ($retryCount -lt $maxRetries)
    Write-Host "VPC Created: $($vpc.VpcId)" -ForegroundColor Green
  
  }else {
    Write-Host "Send you back to Main."
    MainMenue
  }
}

function ListVpc {
  # Get all VPCs
  $vpcs = Get-EC2Vpc

  # Display VPC information 
  $vpcs | ForEach-Object {
    Write-Host "VPC ID: $($_.VpcId)"
    Write-Host "CIDR Block: $($_.CidrBlock)"
    Write-Host "State: $($_.State)"
    Write-Host "is Default: $($_.IsDefault)"  
    Write-Host "----"
  }
 
}

function CreateVpcPeering {
  $RequisterVpcId= Read-Host "Enter VPC ID (Requester) "
  $AccepterVpcId= Read-Host "Enter VPC ID (Accepter) "
  $peeringName= Read-Host "Enter Peering Name "
  $peering= New-EC2VpcPeeringConnection -VpcId $RequisterVpcId -PeerVpcId $AccepterVpcId -TagSpecification @{ResourceType="vpc-peering-connection";Tags=[Amazon.EC2.Model.Tag]@{Key="Name";Value=$peeringName}}
  Approve-EC2VpcPeeringConnection  -VpcPeeringConnectionId $peering.VpcPeeringConnectionId
  $RequisterCider= Get-EC2Vpc -Filter @{Name="vpc-id"; Values=$RequisterVpcId} | %{$_.CidrBlock}
  $AccepterCider= Get-EC2Vpc -Filter @{Name="vpc-id"; Values=$AccepterVpcId} | %{$_.CidrBlock}
  $route1= Get-EC2RouteTable -Filter @{Name="vpc-id"; Values=$RequisterVpcId} |%{New-EC2Route -RouteTableId $_.RouteTableId -DestinationCidrBlock $AccepterCider -VpcPeeringConnectionId $peering.VpcPeeringConnectionId}#$peering.VpcPeeringConnectionId
  $route2= Get-EC2RouteTable -Filter @{Name="vpc-id"; Values=$AccepterVpcId} |%{New-EC2Route -RouteTableId $_.RouteTableId -DestinationCidrBlock $RequisterCider -VpcPeeringConnectionId $peering.VpcPeeringConnectionId}
}

function DestroyVPC {
  $vpcDesID= Read-Host "Enter VPC ID to destroy "
  #$vpcDesID="vpc-075e5cf4ce8ed1faf"
  # Get-EC2RouteTable -Filter @{Name="vpc-id"; Values=$vpcDesID} | %{ try{Remove-EC2Route -RouteTableId $_.RouteTableId -DestinationCidrBlock 0.0.0.0/0 -Force}catch{Write-Host " ERROR REMOVING Route from RouteTableId $($_.RouteTableId) ❌" -ForegroundColor Red}}
  Get-EC2RouteTable -Filter @{Name="vpc-id"; Values=$vpcDesID} | %{try {Unregister-EC2RouteTable -AssociationId $_.RouteTableAssociationId}catch {Write-Host " ERROR REMOVING RouteTableAssociation $($_.RouteTableAssociationId)" -ForegroundColor Red}}
  $rts= Get-EC2RouteTable -Filter @{Name="vpc-id"; Values=$vpcDesID}
  foreach ($RouteTableAssociation in $rts.Associations) {
    try {
      Unregister-EC2RouteTable -AssociationId $RouteTableAssociation.RouteTableAssociationId
    }
    catch {
      Write-Host " ERROR REMOVING RouteTableAssociation $($RouteTableAssociation.RouteTableAssociationId)" -ForegroundColor Red
    }
  }
  Get-EC2RouteTable -Filter @{Name="vpc-id"; Values=$vpcDesID} | %{ try{Remove-EC2RouteTable -RouteTableId $_.RouteTableId -Force}catch{Write-Host " ERROR REMOVING RouteTable $($_.RouteTableId) ❌" -ForegroundColor Red}}
  
  Get-EC2Address -Filter @{Name="tag:Name";Value="MyElasticIP"} | % { try{Remove-EC2Address -Force -AllocationId $_.AllocationId}catch{Write-Host " ERROR Releasing Elastic IP $($_.AllocationId) ❌" -ForegroundColor Red} }
  Get-EC2NatGateway -Filter @{Name="vpc-id"; Values=$vpcDesID} | %{ try{Remove-EC2NatGateway -NatGatewayId $_.NatGateway.NatGatewayId -Force}catch{Write-Host " ERROR REMOVING NatGateway $($_.NatGateway.NatGatewayId) ❌" -ForegroundColor Red}}
  Get-EC2InternetGateway -Filter @{Name="attachment.vpc-id"; Values=$vpcDesID} | % { Dismount-EC2InternetGateway -Force -InternetGatewayId $_.InternetGatewayId -VpcId $vpcDesID }
  Get-EC2InternetGateway -Filter @{Name="attachment.vpc-id"; Values=$vpcDesID} | Remove-EC2InternetGateway -Force
  Get-EC2Subnet -Filter @{Name="vpc-id"; Values=$vpcDesID} | % { try{Remove-EC2Subnet -SubnetId $_.SubnetId -Force }catch{Write-Host " ERROR Removing subnet $($_.SubnetId) ❌" -ForegroundColor Red} }
  try {
    Remove-EC2Vpc -VpcId $vpcDesID -Force -ClientConfig $awsClientConfig
    Write-Host " finished REMOVING vpc $($vpcDesID) " -ForegroundColor Green
  }
  catch {
    Write-Host " ERROR REMOVING vpc $($vpcDesID) ❌" -ForegroundColor Red
  }
}

MainMenue

# destroy
# Try
#     {
#   Remove-EC2Route -RouteTableId $publicRouteTable.RouteTableId -DestinationCidrBlock 0.0.0.0/0 -Force -ClientConfig $awsClientConfig
#     }
# catch {
#   Write-Host " ERROR REMOVING Route from RouteTableId $($publicRouteTable.RouteTableId)" -ForegroundColor Red
# }
# Try
#     {
#   Remove-EC2Route -RouteTableId $privateRouteTable.RouteTableId -DestinationCidrBlock 0.0.0.0/0 -Force -ClientConfig $awsClientConfig
#     }
# catch {
#   Write-Host " ERROR REMOVING Route from RouteTableId $($privateRouteTable.RouteTableId)" -ForegroundColor Red
# }


# foreach ($RouteTableAssociation in $publicRouteTable.Associations) {
#   try {
#     Unregister-EC2RouteTable -AssociationId $RouteTableAssociation.RouteTableAssociationId
#   }
#   catch {
#     Write-Host " ERROR REMOVING publicRouteTableAssociation $($RouteTableAssociation.RouteTableAssociationId)" -ForegroundColor Red
#   }
# }

# foreach ($RouteTableAssociation in $privateRouteTable.Associations) {
#   try {
#     Unregister-EC2RouteTable -AssociationId $RouteTableAssociation.RouteTableAssociationId
#   }
#   catch {
#     Write-Host " ERROR REMOVING privateRouteTableAssociation $($RouteTableAssociation.RouteTableAssociationId)" -ForegroundColor Red
#   }
  
  
# }
  
# Get-EC2RouteTable -Filter @{Name="vpc-id"; Values=$vpc.VpcId} | %{ try{Remove-EC2RouteTable -RouteTableId $_.RouteTableId -Force}catch{Write-Host " ERROR REMOVING RouteTable $($_.RouteTableId) ❌" -ForegroundColor Red}}

# Get-EC2Address | % { try{Remove-EC2Address -Force -AllocationId $_.AllocationId}catch{Write-Host " ERROR Releasing Elastic IP $($_.AllocationId) ❌" -ForegroundColor Red} }

# try{Remove-EC2NatGateway -NatGatewayId $ngw.NatGateway.NatGatewayId -Force -ClientConfig $awsClientConfig}catch{Write-Host " ERROR REMOVING NatGateway $($ngw.NatGateway.NatGatewayId) ❌" -ForegroundColor Red}

# Get-EC2InternetGateway -Filter @{Name="attachment.vpc-id"; Values=$vpc.VpcId} | % { Dismount-EC2InternetGateway -Force -InternetGatewayId $_.InternetGatewayId -VpcId $vpc.VpcId } | Remove-EC2InternetGateway -Force

# try {
#   Remove-EC2Subnet -SubnetId $subnet1.SubnetId -Force -ClientConfig $awsClientConfig
# }
# catch {
#   Write-Host " ERROR REMOVING Subnet $($subnet1.SubnetId) ❌" -ForegroundColor Red
# }

# try {
#   Remove-EC2Subnet -SubnetId $subnet2.SubnetId -Force -ClientConfig $awsClientConfig
# }
# catch {
#   Write-Host " ERROR REMOVING Subnet $($subnet2.SubnetId) ❌" -ForegroundColor Red
# }

# $publicRouteTableDestroy = Remove-EC2RouteTable -RouteTableId $publicRouteTable.RouteTableId -Region $region -Force -ClientConfig $awsClientConfig
# try {
#   Remove-EC2Vpc -VpcId $vpc.VpcId -Force -ClientConfig $awsClientConfig
# }
# catch {
#   Write-Host " ERROR REMOVING vpc $($vpc.VpcId) ❌" -ForegroundColor Red
# }




# $privateRouteTableDestroy = Remove-EC2RouteTable -RouteTableId $privateRouteTable.RouteTableId -Force -ClientConfig $awsClientConfig

#Get-EC2RouteTable -Region $region

# $RouteTableList = Get-EC2RouteTable

# foreach ($RouteTable in $RouteTableList) {
#   foreach ($RouteTableAssociation in $RouteTable.Associations) {
#     Unregister-EC2RouteTable -AssociationId $RouteTableAssociation.RouteTableAssociationId
#   }
#   foreach ($Route in $RouteTable.Routes) {
#     Remove-EC2Route -DestinationCidrBlock $Route.DestinationCidrBlock -RouteTableId $RouteTable.RouteTableId -Force
#   }
#   Remove-EC2RouteTable -RouteTableId $RouteTable.RouteTableId -Force
# }

# $SubnetList = Get-EC2Subnet

# foreach ($Subnet in $SubnetList) {
#   Remove-EC2Subnet -SubnetId $Subnet.SubnetId -Force
# }
