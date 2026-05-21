#!/bin/bash

USER_ID=$(id -u)
r="\e[31m"   
g="\e[32m"   
y="\e[33m" 
n="\e[0m"  

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
        echo -e "$2 is $g successful $n" | tee -a $log_file
    else
        echo -e "$2 is $r failure $n" | tee -a $log_file
        exit 1
    fi
}
dnf module disable nodejs -y &>>$log_file
validate $? "nodejs disabled"

dnf module enable nodejs:20 -y &>>$log_file
validate $? "nodejs enabled"

dnf install nodejs -y &>>$log_file
validate $? "installed nodejs"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating roboshop system user"
else
    echo -e "roboshop user exist"
fi

mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$log_file
validate $? "downloading catalouge file"

rm -rf /app/*

cd /app 
unzip /tmp/catalogue.zip &>>$log_file

npm install &>>$log_file
validate $? "nodejs build tool installed"

cp catalogue.service /etc/systemd/system/catalogue.service
validate $? "copied catalouge service file"

systemctl daemon-reload &>>$log_file
validate $? " daemon reloded"

systemctl enable catalogue &>>$log_file
validate $? "enabled catalouge"

systemctl start catalogue &>>$log_file
validate $? "catalouge started"

cp $SCRIPT_DIR/mongo.repo  /etc/yum.repos.d/mongo.repo
validate $? "mongo.repo is copied"

dnf install mongodb-mongosh -y &>>$log_file
validate $? "Installing MongoDB Client"

STATUS=$(mongosh --host mongodb.daws84s.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.daws84s.site </app/db/master-data.js &>>$log_file
    validate $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $y skipping $n "
fi