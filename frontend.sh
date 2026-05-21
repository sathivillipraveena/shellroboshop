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
dnf module disable nginx -y &>>$log_file
validate $? "nginx disabled"

dnf module enable nginx:1.24 -y &>>$log_file
validate $? "nginx enabled"

dnf install nginx -y &>>$log_file
validate $? "installed nginx"

systemctl enable nginx 
validate $? "enabling nginx"

systemctl start nginx 
validate $? "starting nginx"

rm -rf /usr/share/nginx/html/*

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
validate $? "downloaded frontend ZIP"

cd /usr/share/nginx/html 

unzip /tmp/frontend.zip
validate $? "unzipped frontend"
cp SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf

systemctl restart nginx 
validate $? "restarting nginx"