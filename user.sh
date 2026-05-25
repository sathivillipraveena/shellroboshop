#!/bin/bash

START_TIME=$(date +%s)
USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "nodejs disabled"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "nodejs20 enabled"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "nodejs installed"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "user is created"
else
    echo -e "user already exists" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "directory for app is created"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "downloaded into tmp"

rm -rf /app/*
cd /app
unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unzipped"

npm install &>>$LOG_FILE
VALIDATE $? "nodejs built module installed"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Copying user service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reloaded"

systemctl enable user &>>$LOG_FILE
VALIDATE $? "enabled user"

systemctl start user &>>$LOG_FILE
VALIDATE $? "started user"

END_TIME=$(date +%s)
TOTAL_TIME=$(( END_TIME - START_TIME ))
echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE