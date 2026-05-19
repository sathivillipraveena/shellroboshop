#!/bin/bash
r='\e[31m'
g='\e[32m'
y='\e[33m'
Log_Folder=/var/log/shellroboshop
script_name=$(echo $0 | cut -d "." -f1)
log_file="$log_Folder/$script_name.log"
mkdir -p $Log_Folder
validate(){
    if [ $1 -eq 0 ]
    then
        echo "$2 is ${g} successfull" | tee -a $log_file
    else
        echo "$2 is ${r} failure" | tee -a $log_file
    fi
}
cp mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-org -y &>>log_file
validate $?,"mongodb installation is"
systemctl enable mongod
validate $?,"mongodb is enabled" 
systemctl start mongod 
validate $?,"mongodb is started"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
systemctl restart mongod
validate $?,"system restarted"

