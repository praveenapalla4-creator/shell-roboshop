#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.daws86.fun

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

######### NODEJS ############ 
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Diableing Nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling  Nodejs 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Nodejs"

id roboshop &>>$LOG_FILE

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
   echo -e "User already existed.. $Y SUCCESS $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory "

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue applictaion "

cd /app 
VALIDATE $? "Changing to  app directory "

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "UNzip catalogue "

cd /app 
VALIDATE $? "Changing to app directory "

npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies "

cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copy systemctl service "

systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "enable catalogue "

systemctl start catalogue
VALIDATE $? "Creating app directory "

############# MONGODB CLIENT ##########
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo "

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install mongodb client "

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Load catalogue products "

systemctl restart catalogue
VALIDATE $? "Restart catalogue "
