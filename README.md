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
Then check to make sure that the test SQLite DB is in place by running
```
ls /mnt/sqlite-data
```
And verify that three users were inserted into the DB by the user_data script with
```
sqlite3 /mnt/sqlite-data/my_database.db "SELECT * FROM users;"
```
