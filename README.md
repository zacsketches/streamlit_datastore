# streamlit_datastore
This is the IaC to deploy an AWS free tier data store for my streamlit exploration

To use this file log into the local directory where it is cloned, verify that there is an AWS key-pair named `my-key-pair` and run
```
terraform plan
```
Then if that looks good follow up with
```
terraform apply -auto-approve
```
Log into the new machine by ssh'ing into the output IP address with
```
ssh -i my-key-pair.pem ec2-user@<public-ip>
```
Then check to make sure that the test SQLite DB is in place by running
```
ls /mnt/sqlite-data
```
And verify that three users were inserted into the DB by the user_data script with
```
sqlite3 /mnt/sqlite-data/my_database.db "SELECT * FROM users;"
```
Even better the EC2 instance now has a Flask API to get the users RESTfully
```
curl http://<EC2_PUBLIC_IP>:5000/users
```
And it has a POST endpoint to add a user. Use the POST like this which is looking for an environment variable called `EC2_IP`
```
curl -X POST "http://${EC2_IP:-127.0.0.1}:5000/create" \
     -H "Content-Type: application/json" \
     -d '{"name": "David"}'
```
## Then destroy the infrastructure to conserve resources for a test VM
```
terraform destroy
```
---
If you need to generate teh key-pair then use this awscli command
```
aws ec2 create-key-pair --key-name my-key-pair --query "KeyMaterial" --output text > my-key-pair.pem
```
Then set the corret permissions on the key-pair with
```
chmod 400 my-key-pair.pem
```
The aws cli commands will only run after you have run 
```
aws configure
```
This configuration will require the AWS `access key id` and the `secret key id` that are generated in the AWS console.
