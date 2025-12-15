#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop"
START_TIME=$(date +%s)
SCRIPT_NAME=$( echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
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

dnf module disable nodejs -y
dnf module enable nodejs:20 -y

dnf install nodejs -y

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

mkdir /app 
curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
cd /app 
unzip /tmp/user.zip
cd /app 
npm install 
systemctl daemon-reload
systemctl enable user 
systemctl start user