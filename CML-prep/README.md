Prepare IAM and S3 bucket for CML deployment in AWS

https://www.youtube.com/watch?v=vzgUyO-GQio

https://github.com/CiscoDevNet/cloud-cml/blob/main/documentation/AWS.md


Group cmlterraform is created and also user cml_terraform which is member of the group
Role s3-access-for-ec2 is created

The following policies are created or used:
- AmazonEC2FullAccess (predefined policy)
-- assigned to group cmlterraform
- AmazonSSMManagedInstanceCore (predefined policy)
-- assigned to role s3-access-for-ec2
- cml-s3-access
-- customer managed (created) policy which enables access to s3 bucket named phcmlimages
-- assigned to group cmlterraform and to role s3-access-for-ec2
- pass-role
-- inline policy which enables to pass role s3-access-for-ec2
-- assigned to group cmlterraform


Terraform runs under the user cmlterraform
- it has access to EC2, to specific S3 bucket which contains installation files for CML and it can assume (pass) role s3-access-for-ec2 (this is used to pass this role to created EC2 instance so that it has access to the S3 bucket)

Created EC2 instance has access to S3 bucket and is able to connect to SSM service thanks to role s3-access-for-ec2 which is passed to the EC2 instance
