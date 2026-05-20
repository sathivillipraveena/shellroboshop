#!/bin/bash

USER_ID=$(id -u)
r="\e[31m"   # ✅ fix 1: missing \ before e
g="\e[32m"   # ✅ fix 1: missing \ before e
y="\e[33m"   # ✅ fix 1: missing \ before e

start_time=$(date +%s)   # ✅ fix 2: $date → date

LOG_FOLDER=/var/log/shellroboshop   # ✅ fix 3: unified case

script_name=$(echo $0 | cut -d "." -f1)

log_file="$LOG_FOLDER/$script_name.log"   # ✅ fix 3: log_Folder → LOG_FOLDER

mkdir -p $LOG_FOLDER

if [ $USER_ID -ne 0 ]   # ✅ fix 4: USER_ID → $USER_ID (missing $)
then
    echo -e "$r ERROR: user is not super user" | tee -a $log_file
    exit 1
else
    echo "You are running with root access" | tee -a $log_file   # ✅ fix 5: $LOG_FILE → $log_file
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

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "mongodb repo copied"   # ✅ fix 6: comma → space between $? and message

dnf install mongodb-org -y &>>$log_file   # ✅ fix 7: log_file → $log_file (missing $)
validate $? "mongodb installation is"

systemctl enable mongod &>>$log_file   # ✅ fix 7
validate $? "mongodb is enabled"

systemctl start mongod &>>$log_file   # ✅ fix 7
validate $? "mongodb is started"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf

systemctl restart mongod &>>$log_file   # ✅ fix 7
validate $? "mongodb restarted"

end_time=$(date +%s)   # ✅ fix 8: $date → date
time_taken=$((end_time - start_time))
echo "Time taken for total execution: ${time_taken} seconds" | tee -a $log_file