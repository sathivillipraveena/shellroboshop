#!/bin/bash
USER_ID=$(id -u)
r='\e[31m'
g='\e[32m'
y='\e[33m'

start_time=$(($date +%s))
Log_Folder=/var/log/shellroboshop

script_name=$(echo $0 | cut -d "." -f1)

log_file="$log_Folder/$script_name.log"

mkdir -p $Log_Folder

if [ USER_ID -ne 0 ]
then
    echo " ${r} ERROR: user is not super user" | tee -a $log_file
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

validate(){
    if [ $1 -eq 0 ]
    then
        echo "$2 is ${g} successfull" | tee -a $log_file
    else
        echo "$2 is ${r} failure" | tee -a $log_file
        exit 1 # as the case is failure other than 0 every number after exit is failure
    fi
}
cp mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-org -y &>>log_file
validate $?,"mongodb installation is"

systemctl enable mongod &>>log_file
validate $?,"mongodb is enabled" 

systemctl start mongod &>>log_file
validate $?,"mongodb is started"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf

systemctl restart mongod &>>log_file
validate $?,"system restarted"

end_time=$(($date +%s))
time_taken=$(($end_time - $start_time))
echo "time taken for the total execution is ${time_taken}" | tee -a $log_file