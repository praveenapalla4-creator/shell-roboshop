


#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop"
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


dnf install python3 gcc python3-devel -y &>>$LOG_FILE
 VALIDATE $? "Installing Python3"

if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating system user"
else
   echo -e "User already existed.. $Y SKIIPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory "

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading payment applictaion "

cd /app 
VALIDATE $? "Changing to  app directory "

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "UNzip catalogue "

cd /app 
VALIDATE $? "Changing to app directory "

pip3 install -r requirements.txt l &>>$LOG_FILE
VALIDATE $? "Install dependencies "

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service 
VALIDATE $? "Copy systemctl service "



systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reload systemctl service "

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "enable systemctl service "

systemctl start payment &>>$LOG_FILE
VALIDATE $? "start systemctl service "