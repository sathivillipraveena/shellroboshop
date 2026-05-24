#!/bin/bash

USERID=$(id -u)
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
VALIDATE $? "nodejs enabled"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "nodejs installed"
id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "user roboshop is created"
else
    echo -e " user already exist"
fi
mkdir -p /app 
# -p denotes if the directory is present it won't create a new one or else it does 
curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
rm -rf /app/*
cd /app 
unzip /tmp/cart.zip
VALIDATE $? "cart file is unzipped"

npm install &>>$LOG_FILE
VALIDATE $? "build tool installation"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "service file is loaded"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reloaded"
systemctl enable cart &>>$LOG_FILE
VALIDATE $? "enabled cart"
systemctl start cart &>>$LOG_FILE
VALIDATE $? "started cart"
END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE