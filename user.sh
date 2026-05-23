#!/bin/bash
USER_ID=$(id -u)
R='\e[31m'
G='\e[32m'
Y='\e[33m'
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
mkdir -p LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
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
id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "user is created "
else
    echo -e "user already exist"
fi
mkdir /app 
VALIDATE $? "directory for app is created"
curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "downloaded directory into tmp "
 
unzip /tmp/user.zip 
VALIDATE $? "unzipped"
cd /app
npm install &>>$LOG_FILE
VALIDATE $? "nodejs built module is install "

cp $SCRIPT_DIR/user.service  /etc/systemd/system/user.service
# as we are in app directory and needs to move to previous directory to get service file 
systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reloaded"

systemctl enable user &>>$LOG_FILE
VALIDATE $? "enabled user" 

systemctl start user &>>$LOG_FILE
VALIDATE $? "started user"