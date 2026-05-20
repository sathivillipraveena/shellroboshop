#!/bin/bash

USER_ID=$(id -u)
r="\e[31m"   
g="\e[32m"   
y="\e[33m"   

start_time=$(date +%s) 

LOG_FOLDER=/var/log/shellroboshop   

script_name=$(echo $0 | cut -d "." -f1)
SCRIPT_DIR=$PWD


log_file="$LOG_FOLDER/$script_name.log"   

mkdir -p $LOG_FOLDER

if [ $USER_ID -ne 0 ]   
then
    echo -e "$r ERROR: user is not super user" | tee -a $log_file
    exit 1
else
    echo "You are running with root access" | tee -a $log_file   
fi

validate(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is $g successful" | tee -a $log_file
    else
        echo -e "$2 is $r failure" | tee -a $log_file
        exit 1
    fi
}
dnf module disable nodejs -y
validate $?,"nodejs disabled"
dnf module enable nodejs:20 -y
validate $?,"nodejs enabled"
dnf install nodejs -y
validate $?,"installed nodejs"
id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $?,"Creating roboshop system user"
else
    echo -e "roboshop user exist"
fi
mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 

unzip /tmp/catalogue.zip
cd /app 
npm install 
validate $?,"nodejs build tool installed"
cp catalogue.service /etc/systemd/system/catalogue.service
validate $?,"copied catalouge service file"

systemctl daemon-reload
validate $?," daemon reloded"

systemctl enable catalogue 
validate $?,"enabled catalouge"
systemctl start catalogue
validate $?,"catalouge started"