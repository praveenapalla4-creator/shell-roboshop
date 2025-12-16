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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable deafualt nodejs "

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable  nodejs 20 version "

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs"

id roboshop 
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating system user"
else
   echo -e "User already existed.. $Y SKIIPING $N"
fi

rm -rf /app/*
VALIDATE $? "Removing existing code"

mkdir -p /app 

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue applictaion "

cd /app 
VALIDATE $? "Changing to  app directory "

unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unzip user file"

cd /app 
VALIDATE $? "Changing to app directory "

cp $SCRIPT_DIR/user.service  /etc/systemd/system/user.service
VALIDATE $? "Copy systemctl service "

npm install &>>$LOG_FILE
VALIDATE $? "Install nodejs "

systemctl daemon-reload 
systemctl enable user  &>>$LOG_FILE

systemctl start user