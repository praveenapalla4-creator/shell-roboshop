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
VALIDATE $? "disable deafault nodejs "

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs version 20 "

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs  "

if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
   echo -e "User already existed.. $Y SKIIPING $N"
fi

rm -rf /app/*
VALIDATE $? "Removing existing code"


mkdir -p /app  &>>$LOG_FILE
VALIDATE $? "creating a directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading zip file "

cd /app &>>$LOG_FILE
VALIDATE $? "moving in to app directory "

unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "unzip cart file "

cd /app &>>$LOG_FILE
VALIDATE $? "moving in to app directory "

npm install &>>$LOG_FILE
VALIDATE $? "Installing the modules "

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service 
VALIDATE $? "copy systemctl  service "

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reaload the service "

systemctl enable cart &>>$LOG_FILE
VALIDATE $? "enable the cart server "

systemctl start cart &>>$LOG_FILE
VALIDATE $? " start the cart server "