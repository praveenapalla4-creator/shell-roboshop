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
MYSQL_HOST=mysql.daws86.help
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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing maven "
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating system user"
else
   echo -e "User already existed.. $Y SKIIPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "creating app directory "

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading shipping file"

rm -rf /app/*
VALIDATE $? "Removing existing code"

cd /app &>>$LOG_FILE
VALIDATE $? "moving to app directory"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping the shipping file"

cd /app &>>$LOG_FILE
VALIDATE $? "moving to app directory"



mvn clean package &>>$LOG_FILE
mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "copy systemctl service "

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reload the server "

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "enable the shipping server "

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "starting the server "

####### MYSQL_CLIENT############
dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Installing the mysql server "


mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Disable redis "