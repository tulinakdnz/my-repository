# Project-503 : Blog Page Application (Django) deployed on AWS Application Load Balancer with Auto Scaling, S3, Relational Database Service(RDS), VPC's Components, DynamoDB and Cloudfront with Route 53 (STUDENT_SOLUTION)

## Description

The Clarusway Blog Page Application aims to deploy blog application as a web application written Django Framework on AWS Cloud Infrastructure. This infrastructure has Application Load Balancer with Auto Scaling Group of Elastic Compute Cloud (EC2) Instances and Relational Database Service (RDS) on defined VPC. Also, The Cloudfront and Route 53 services are located in front of the architecture and manage the traffic in secure. User is able to upload pictures and videos on own blog page and these are kept on S3 Bucket. This architecture will be created by Firms DevOps Guy.

## Steps to Solution
  
### Step 1: Create dedicated VPC and whole components
        
    ### VPC
    - Create VPC. 
        create a vpc named `aws-capstone-vpc` CIDR blok is `10.90.0.0/16` 
        no ipv6 CIDR block
        tenancy: default
    - select `aws-capstone-vpc` VPC, click `Actions` and `enable DNS hostnames` for the `aws-capstone-vpc`. 

    ## Subnets
    - Create Subnets
        - Create a public subnet named `aws-capstone-public-subnet-1A` under the vpc aws-capstone-vpc in AZ us-east-1a with 10.90.10.0/24
        - Create a private subnet named `aws-capstone-private-subnet-1a` under the vpc aws-capstone-vpc in AZ us-east-1a with 10.90.11.0/24
        - Create a public subnet named `aws-capstone-public-subnet-1b` under the vpc aws-capstone-vpc in AZ us-east-1b with 10.90.20.0/24
        - Create a private subnet named `aws-capstone-private-subnet-1b` under the vpc aws-capstone-vpc in AZ us-east-1b with 10.90.21.0/24

    - Set `auto-assign IP` up for public subnets. Select each public subnets and click Modify "auto-assign IP settings" and select "Enable auto-assign public IPv4 address" 

    ## Internet Gateway

    - Click Internet gateway section on left hand side. Create an internet gateway named `aws-capstone-igw` and create.

    - ATTACH the internet gateway `aws-capstone-igw` to the newly created VPC `aws-capstone-vpc`. Go to VPC and select newly created VPC and click action ---> Attach to VPC ---> Select `aws-capstone-vpc` VPC 

    ## Route Table
    - Go to route tables on left hand side. We have already one route table as main route table. Change it's name as `aws-capstone-public-rt` 
    - Create a route table and give a name as `aws-capstone-private-rt`.
    - Add a rule to `aws-capstone-public-rt` in which destination 0.0.0.0/0 (any network, any host) to target the internet gateway `aws-capstone-igw` in order to allow access to the internet.
    - Select the private route table, come to the subnet association subsection and add private subnets to this route table. Similarly, we will do it for public route table and public subnets. 
        
    ## Endpoint
    - Go to the endpoint section on the left hand menu
    - select endpoint
    - click create endpoint
    - Name tag      : aws-capstone-s3-gw-endpoint
    - service name  : `com.amazonaws.us-east-1.s3`
    - type          : Gateway
    - VPC           : `aws-capstone-vpc`
    - Route Table   : private route table
    - Policy        : `Full Access`
    - Create

### Step 2: Create Security Groups (ALB ---> EC2 ---> RDS)

1. ALB Security Group
Name            : aws-capstone-alb-sg
Description     : ALB Security Group allows traffic HTTP and HTTPS ports from anywhere 
Inbound Rules
VPC             : aws-capstone-vpc
HTTP(80)    ----> anywhere
HTTPS (443) ----> anywhere

2. EC2 Security Groups
Name            : aws-capstone-ec2-sg
Description     : EC2 Security Groups only allows traffic coming from aws-capstone-alb-sg Security Groups for HTTP and HTTPS ports. In addition, ssh port is allowed from anywhere
VPC             : aws-capstone_VPC
Inbound Rules
HTTP(80)    ----> aws-capstone-alb-sg
HTTPS (443) ----> aws-capstone-alb-sg
ssh         ----> anywhere

3. RDS Security Groups
Name            : aws-capstone-rds-sg
Description     : EC2 Security Groups only allows traffic coming from aws-capstone-ec2-sg Security Groups for MYSQL/Aurora port. 

VPC             : aws-capstone-vpc
Inbound Rules
MYSQL/Aurora(3306)  ----> aws-capstone-ec2-sg

4. NAT Instance Security Group
Name            : aws-capstone-nat-sg
Description     : NAT instance Security Group allows traffic HTTP and HTTPS and SSH ports from anywhere 
Inbound Rules
VPC             : aws-capstone-vpc
HTTP(80)    ----> anywhere
HTTPS (443) ----> anywhere
SSH (22)    ----> anywhere

### Step 3: Create RDS
First we create a subnet group for our custom VPC. Click `subnet Groups` on the left hand menu and click `create DB Subnet Group` 
```text
Name               : aws-capstone-rds-subnet-group
Description        : aws-capstone-rds-subnet-group
VPC                : aws-capstone-vpc
Add Subnets
Availability Zones : Select 2 AZ in aws-capstone-vpc
Subnets            : Select 2 Private Subnets in these subnets (x.x.11.0, x.x.21.0)

```
- Go to the RDS console and click `create database` button
```text
Choose a database creation method : Standart Create
Engine Type     : MySQL
Edition         : MySQL Community
Version         : 8.0.33 (or latest)
Templates       : Free Tier
Settings        : 
    - DB instance identifier : aws-capstone-rds
    - Master username        : admin
    - Password               : Clarusway1234 
DB Instance Class            : Burstable classes (includes t classes) ---> db.t2.micro
Storage                      : 20 GB and enable autoscaling(up to 40GB)
Connectivity:
    Compute                  : Don't connect to EC2
    VPC                      : aws-capstone-vpc
    Subnet Group             : aws-capstone-rds-subnet-group
    Public Access            : No 
    VPC Security Groups      : Choose existing ---> aws-capstone-rds-sg
    Availability Zone        : No preference
    Additional Configuration : Database port ---> 3306
Database authentication ---> Password authentication
Additional Configuration:
    - Initial Database Name  : database1
    - Backup ---> Enable automatic backups
    - Backup retention period ---> 7 days
    - Select Backup Window ---> Select 03:00 (am) Duration 1 hour
    - Maintance window : Select window    ---> 04:00(am) Duration:1 hour
create instance
```

### Step 4: Create two S3 Buckets and set one of these as static website.
Go to the S3 Console and lets create two buckets. 

1. Blog Website's S3 Bucket

- Click Create Bucket
```text
Bucket Name : awscapstones<name>blog
Region      : N.Virginia
Object Ownership
    - ACLs enabled
        - Bucket owner preferred
Block Public Access settings for this bucket
Block all public access : Unchecked
Other Settings are keep them as are
create bucket
```

2. S3 Bucket for failover scenario

- Click Create Bucket
```text
Bucket Name : www.clarusway.us
Region      : N.Virginia
Object Ownership
    - ACLs enabled
        - Bucket owner preferred
Block Public Access settings for this bucket
Block all public access : Unchecked
Please keep other settings as are
```
- create bucket

- Selects created `www.<YOUR DNS NAME>` bucket ---> Properties ---> Static website hosting
```text
Static website hosting : Enable
Hosting Type : Host a static website
Index document : index.html
save changes
```
- Select `www.<YOUR DNS NAME>` bucket ---> select Upload and upload `index.html` and `sorry.jpg` files from given folder---> Permissions ---> Grant public-read access ---> Checked warning massage

## Step 5: Create NAT Instance in Public Subnet
To launch NAT instance, go to the EC2 console and click the `Launch Instance` button

```text
- Name: AWS Capstone NAT Instance
- AMI: write "amzn-ami-vpc-nat-hvm" into the filter box
select NAT Instance `amzn-ami-vpc-nat-hvm-2018.03.0.20210915.x86_64-ebs` 
    - Instance Type: t2.micro
    - Key Pair - choose your key pair
    - Network : aws-capstone-vpc
    - Subnet  : aws-capstone-public-subnet-1a
    - Security Group: aws-capstone-nat-sg
    - Termination protection        : Enable
    - Other features keep them as are
```
- Click on `Launch Instance`

!!!IMPORTANT!!!
- select newly created NAT instance and enable stop source/destination check from Networking properties
- go to private route table and write a rule
```
Destination : 0.0.0.0/0
Target      : instance ---> Select NAT Instance
Save
```

Test your NAT instance:
- Launch a new Linux instance in the aws-capstone-private-1a subnet
- Connect to your NAT instance:
    - In a new GitBash or MacOS Terminal:
        - change to the directory where your pem key file is
        - type: `eval $(ssh-agent)`
        - type: `ssh-add <your pem file name>`
        - type: `ssh -A ec2-user@<IP of NAT Instance>`
    - When connected to the NAT instance:
        - type `ssh <private IP of test instance>`
    - When connected to the private instance:
        - type `curl www.google.com`
- Terminate your test instance (NOT your NAT instance!!)        

## Step 6: Prepare your Github repository
- Create private project repository on your Github and clone it on your local. Copy all files and folders which are downloaded from clarusway repo under this folder. Commit and push them on your private Git hup Repo.

- Go to `github.com`
- First create a user access token
- Select your profile picture on the to right side
- Choose `settings`
- On the left side choose `developer settings`
- Select `Personal Access Tokens` --> `Tokens (classic)`
- Click on `Generate new token`
- Click on `Generate new token (classic)`
- Enter `capstone project access` under `Note`
- Enter `7 Days` for expiration
- Select the check box `repo`
- Click `Generate token`
- Save your token somewhere safe

- Go to github.com
- Create a new repository
- Repository name: capstone
- Description: Repo for AWS Dev Ops C14 Capstone Project
- Choose 'Private'

- In your local machine go to Desktop
- Copy the git clone URL from github.com
- At a terminal type `git clone <Clone URL>`
- If you have authentication issues, you can enter your user name and use the token created above for your password

- Copy the files from the clarusway repo (`src` folder) to the capstone folder on your desktop
- Copy the file `requirements.txt` to the capstone folder

- Go back to the terminal
- Make sure you are in the `capstone` folder
- Type the following commands
-   `git add .`
-   `git commit -m "initial commit"`
-   `git push`
- Verify that your new repo has your new files


## Step 7: Write RDS database endpoint and S3 Bucket name in settings file given by Clarusway Fullstack Developer team and push your application into your own public repo on Github
Please follow and apply the instructions in the developer_notes.txt.
```text
- Movie and picture files are kept on S3 bucket named awscapstones<name>blog as object. You should create an S3 bucket and write name of it on "/src/cblog/settings.py" file as AWS_STORAGE_BUCKET_NAME variable. In addition, you must assign region of S3 as AWS_S3_REGION_NAME variable

- Users credentials and blog contents are going to be kept on RDS database. To connect EC2 to RDS, following variables must be assigned on "/src/cblog/settings.py" file after you create RDS;
    a. Database name - "NAME" variable (database1)
    b. Database endpoint - "HOST" variables
    c. Port - "PORT"
    d. User - "USER" (Admin)
    e. PASSWORD variable must be written on "/src/.env" file not to be exposed with settings file

===> PUSH YOUR CHANGES to github:
- git add .
- git commit -m "configuration changes"
- git push
```

## Step 8: Create certification for secure connection
We will use this later, but it may take a while to activate so we will create it now.

Go to the certification manager console and click `request a certificate` button. Select `Request a public certificate`, then `request a certificate` ---> `*.<YOUR DNS NAME>` ---> DNS validation ---> No tag ---> Review ---> click confirm and request button. Then it takes a while to be activated. 

===> Make sure you click `Create DNS Records`


## Step 9: Prepare a userdata to be utilized in Launch Template
userdata has already given by developer to us. In production environment. you should write it based on application and developer instructions. Lets go over it again.

First we will need a role for our ec2 instance:
- Go to IAM
- Click `Roles`
- Click `Create Role`
- Trusted Entity type: `AWS Service`
- Use case: `EC2`
- Add permission `AmazonS3FullAccess`
- Role name: aws-capstone-ec2-s3-full-access
- Click `Create role`

- Please check if this userdata is working or not. to do this create new instance in public subnet

Run one command at a time and look for any errors

Instance properties:
- Ubuntu 22.04
- Key Pair: your key
- VPC: aws-capstone-public-1a
- Security Group
    - aws-capstone-ec2-sg
    - aws-capstone-alb-sg
    - aws-capstone-nat-sg
- Advanced details:
    - IAM Instance Profile: 
        - aws-capstone-ec2-s3-full-access
```bash
sudo su
apt-get update -y
apt-get install git -y
apt-get install python3 -y
cd /home/ubuntu/
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
git clone https://$TOKEN@<YOUR PRIVATE REPO URL>
cd /home/ubuntu/<YOUR PRIVATE REPO NAME>
apt install python3-pip -y
apt-get install python3.10-dev default-libmysqlclient-dev -y
pip3 install -r requirements.txt
cd /home/ubuntu/<YOUR PRIVATE REPO NAME>/src
python3 manage.py collectstatic --noinput
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:80
```


## Step 10: Create Launch Template
To create Launch Template, go to the EC2 console and select `Launch Template` on the left hand menu. Tab the Create Launch Template button.
```bash
Launch template name                : aws-capstone-launch-template
Template version description        : Blog Web Page version 1
Amazon machine image (AMI)          : Ubuntu 22.04
Instance Type                       : t2.micro
Key Pair                            : your key pair
Subnet                              : Don't include
Security Groups                     : aws-capstone-ec2-sg
Storage (Volumes)                   : keep it as is
Resource tags                       : Key: Name   Value: aws-capstone-web-server
Advance Details:
    - IAM instance profile          : aws-capstone-ec2-s3-full-access
    - Termination protection        : Enable
    - User Data
#!/bin/bash
apt-get update -y
apt-get install git -y
apt-get install python3 -y
cd /home/ubuntu/
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
git clone https://$TOKEN@<YOUR PRIVATE REPO URL>
cd /home/ubuntu/<YOUR PRIVATE REPO NAME>
apt install python3-pip -y
apt-get install python3.10-dev default-libmysqlclient-dev -y
pip3 install -r requirements.txt
cd /home/ubuntu/<YOUR PRIVATE REPO NAME>/src
python3 manage.py collectstatic --noinput
#python3 manage.py makemigrations
#python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:80
```
NOTE: You don't have to run the migrations statements more than once since it re-configures the database
- create launch template
## Step 11: Create ALB and Target Group
Go to the Load Balancer section on the left hand side menu of EC2 console. Click `create Load Balancer` button and select Application Load Balancer
```text
Application Load Balancer ---> Create
Basic Configuration:
Name                    : aws-capstone-alb
Schema                  : internet-facing
IP Address Type         : IPv4

Network mapping:
VPC                     : aws-capstone-vpc
Mappings                :
    - Availability zones:
        1. aws-capstone-public-subnet-1a
        2. aws-capstone-public-subnet-1b
Security Groups         :
Security Groups         : aws-capstone-alb-sg

Listeners and Routing   :
Listener HTTPS:443
Protocol HTTP ---> Port 443 ---> Default Action Create Target Group (New Window pops up)
    - Target Type         : Instance
    - Name                : aws-capstone-tg
    - Protocol            : HTTP
    - Port                : 80
    - Protocol version    : HTTP1
    - Health Check        :
      - Protocol          : HTTP
      - Path              : /
      - Port              : traffic port
      - Healthy threshold : 5
      - Unhealthy threshold : 2
      - Timeout           : 5
      - Interval          : 30
      - Success Code      : 200
click Next

Register Targets -->""We're not gonna add any EC2 here. While we create autoscaling group, it will ask us to show target group and ELB, then we'll indicate this target group there, so whenever autoscaling group launches new machine, it will registered this target group automatically.""
without register any target click Next: Review 

then create "Target Group"

switch back to the ALB listener page and select newly created Target Group on the list

Click Add listener ---> Protocol HTTP ---> Port 80 ---> Default Action ---> Select newly created target group

Secure Listener Settings        :
    Security policy: ELBSecurityPolicy-2016-08
    Default ACM    : *.clarusway.us

```
- click create

After creation of ALB, our ALB have to redirect http traffic to https port. Because our requirement wants to secure traffic. Thats why we should change listener rules. Go to the ALB console and select Listeners sub-section

```text
select HTTP: 80 rule ---> click Rule Name
- Check Default under "Listener Rules"
- Click `Actions | Edit rule`
- Choose Redirect to URL
- Enter 443 for Port number
- Status code is "301 - permanently moved"
```
Lets go ahead and look at our ALB DNS --> it going to say "it is not safe", however, it will be fixed after connect ALB to our DNS with Route 53

## Step 12: Create Autoscaling Group with Launch Template 

Go to the Autoscaling Group on the left hand side menu. Click create Autoscaling group. 

- Choose launch template or configuration
```text 
Auto Scaling group name         : aws-capstone-asg
Launch Template                 : aws-capstone-launch-template
```

- Configure settings

```text
Network                         :
    - VPC                       : aws-capstone-vpc
    - Subnets                   : Private 1a and Private 1b
```

Configure advanced options
```text
- Load balancing                                : Attach to an existing load balancer
- Choose from your load balancer target groups  : awscapstoneTargetGroup
- Health Checks
    - Health Check Type             : ELB
    - Health check grace period     : 300
```

- Configure group size and scaling policies

```text
Group size
    - Desired capacity  : 2
    - Minimum capacity  : 2
    - Maximum capacity  : 4
Scaling policies
    - Target tracking scaling policy
        - Scaling policy name       : Target Tracking Policy
        - Metric Type               : Average CPU utilization
        - Target value              : 70
```

- Add notifications
```text
Create new Notification
    - Notification1
        - Send a notification to    : aws-capstone-sns
        - with these recipients     : <your email>
        - event type                : select all 
```

<!-- WARNING!!! Sometimes your EC2 has a problem after you create autoscaling group, If you need to look inside one of your instance to make sure where the problem is, please follow these steps...

```bash
eval $(ssh-agent) (your local)
ssh-add xxxxxxxxxx.pem   (your local )
ssh -A ec2-user@<Public IP or DNS name of NAT instance> (your local)
ssh ubuntu@<Private IP of web server>  (in NAT instance)
You are in the private EC2 instance
``` -->

## Step 13: Create Cloudfront in front of ALB
Go to the cloudfront menu and click start
- Origin Settings
```text
Origin Domain Name          : aws-capstone-ALB-1947210493.us-east-2.elb.amazonaws.com
Origin Path                 : Leave empty (this means, define for root '/')
Protocol                    : Match Viewer
HTTP Port                   : 80
HTTPS                       : 443
Minimum Origin SSL Protocol : Keep it as is
Name                        : Keep it as is
Add custom header           : No header
Enable Origin Shield        : No
Additional settings         : Keep it as is
```
Default Cache Behavior Settings
```text
Path pattern                                : Default (*)
Compress objects automatically              : Yes
Viewer Protocol Policy                      : Redirect HTTP to HTTPS
Allowed HTTP Methods                        : GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
Cached HTTP Methods                         : Select OPTIONS
Cache key and origin requests
- Use legacy cache settings
  Headers     : Include the following headers
    Add Header
    - Accept
    - Accept-Charset
    - Accept-Datetime
    - Accept-Encoding
    - Accept-Language
    - Authorization
    - Cloudfront-Forwarded-Proto
    - Host
    - Origin
    - Referrer
Forward Cookies                         : All
Query String Forwarding and Caching     : All
Other stuff                             : Keep them as are 
```
- Distribution Settings
```text
Price Class                             : Use all edge locations (best performance)
Alternate Domain Names                  : www.clarusway.us
SSL Certificate                         : Custom SSL Certificate (example.com) ---> Select your certificate creared before
Other stuff                             : Keep them as are                  
```

## Step 14: Create Route 53 with Failover settings
Come to the Route53 console and select Health checks on the left hand menu. Click create health check
Configure health check

```text
Name                : aws capstone health check
What to monitor     : Endpoint
Specify endpoint by : Domain Name
Protocol            : HTTP
Domain Name         : Write cloudfront domain name
Port                : 80
Path                : leave it blank
Other stuff         : Keep them as are
```
- Click Hosted zones on the left hand menu

- click your Hosted zone        : <YOUR DNS NAME>

- Create Failover scenario

- Click Create Record

- Select Failover ---> Click Next
```text
Configure records
Record name             : www.<YOUR DNS NAME>
Record Type             : A - Routes traffic to an IPv4 address and some AWS resources
TTL                     : 300

---> First we'll create a primary record for cloudfront

Failover record to add to your DNS ---> Define failover record

Value/Route traffic to  : Alias to cloudfront distribution
                          - Select created cloudfront DNS
Failover record type    : Primary
Health check            : aws capstone health check
Record ID               : Cloudfront as Primary Record
----------------------------------------------------------------

---> Second we'll create secondary record for S3

Failover another record to add to your DNS ---> Define failover record

Value/Route traffic to  : Alias to S3 website endpoint
                          - Select Region
                          - Your created bucket name emerges ---> Select it
Failover record type    : Secondary
Health check            : No health check
Record ID               : S3 Bucket for Secondary record type
```

- click create records

## Step 15: Create DynamoDB Table
Go to the Dynamo Db table and click create table button

- Create DynamoDB table
```text
Name            : awscapstoneDynamo
Primary key     : id
Other Stuff     : Keep them as are
click create
```

## Step 16-17: Create Lambda function

Before we create our Lambda function, we should create IAM role that we'll use for Lambda function. Go to the IAM console and select role on the left hand menu, then create role button
```text
Select Lambda as trusted entity ---> click Next:Permission
Choose: - LambdaS3fullaccess, 
        - Network Administrator
        - DynamoDBFullAccess
No tags
Role Name           : aws-capstone_lambda_Role
Role description    : This role give a permission to lambda to reach S3 and DynamoDB on custom VPC
```

then, go to the Lambda Console and click create function

- Basic Information
```text

Function Name           : awscapstonelambdafunction
Runtime                 : Python 3.8
Create IAM role         : S3 full access policy

Advance Setting:
Network                 : 
    - VPC               : aws-capstone-VPC
    - Subnets           : Select all subnets
    - Security Group    : Select default security Group
```

- Now we'll go to the S3 bucket belongs our website and create an event to trigger our Lambda function. 

## Step 18-19: Create trigger for Lambda Function

- Go to the `awscapstonelambdafunction` lambda Function and click add trigger on the top left hand side.

- For defining trigger for creating objects
```text
Trigger configuration   : S3
Bucket                  : awscapstonec3<name>blog
Event type              : All object create events
Check the warning message and click add ---> sometimes it says overlapping situation. When it occurs, try refresh page and create a new trigger or remove the s3 event and recreate again. then again create a trigger for lambda function
```

- For defining trigger for deleting objects
```bash

Trigger configuration   : S3
Bucket                  : awscapstonec3<name>blog
Event type              : All object delete events
Check the warning message and click add ---> sometimes it says overlapping situation. When it occurs, try refresh page and create a new trigger or remove the s3 event and recreate again. then again create a trigger for lambda function
```

- Go to the code part and select lambda_function.py ---> remove default code and paste a code on below. If you give DynamoDB a different name, please make sure to change it into the code. 

```python
import json
import boto3

def lambda_handler(event, context):
    s3 = boto3.client("s3")
    
    if event:
        print("Event: ", event)
        filename = str(event['Records'][0]['s3']['object']['key'])
        timestamp = str(event['Records'][0]['eventTime'])
        event_name = str(event['Records'][0]['eventName']).split(':')[0][6:]
        
        filename1 = filename.split('/')
        filename2 = filename1[-1]
        
        dynamo_db = boto3.resource('dynamodb')
        dynamoTable = dynamo_db.Table('awscapstoneDynamo')
        
        dynamoTable.put_item(Item = {
            'id': filename2,
            'timestamp': timestamp,
            'Event': event_name,
        })
        
    return "Lambda success"
```

- Click deploy and all set. go to the website and add a new post with photo, then control if their record is written on DynamoDB. 

- WE ALL SET

- Congratulations!! You have finished your AWS Capstone Project

Clean-up
-------------------
1. CloudFront>>>>>Disable>>>>>>Delete
2. RDS 
3. RDS Subnet Group (After RDS Deleted)
4. Lambda Function
5. DynamoDB
6. R53 healthcheck
7. R53 failover records
8. S3 buckets (first objects)
9. IAM roles
10. NAT instance >>>>>terminate
11. ALB
12. TG
13. LT
14. ASG
15. Endpoint
16. internet gateway>>>>>detach>>>>>delete
17. subnets
18. private RT
19. VPC
