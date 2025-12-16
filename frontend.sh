#!/bin/bash

set -euo pipefail

trap 'echo "there is an error in $LINENO, Command is: $BASH_COMMAND"' ERR

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.daws86s.help
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
   echo -e "ERROR: Please run this script with root privilege"
   exit 1 # if we not use this then it will proceed with next lines
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
   echo  -e " $2  ... $R FAILURE $N" | tee -a $LOG_FILE
   exit 1
else
    echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
fi

}

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disable deafult nginx "

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enable nginx version"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx server "

systemctl enable nginx  &>>$LOG_FILE
VALIDATE $? " Enable nginx "

systemctl start nginx  &>>$LOG_FILE
VALIDATE $? "Start nginx "


rm -rf /usr/share/nginx/html/* 

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Download the application "

cd /usr/share/nginx/html  

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipping frontend application "

rm -rf /etc/nginx/nginx.conf
cp $SCRIPT_DIR/nginx.con /etc/nginx/nginx.conf

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting Nginx"