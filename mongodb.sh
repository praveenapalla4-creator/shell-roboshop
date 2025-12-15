
#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

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

cp mongo.repo vim /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding mongo repo"

dnf install mongodb-org -y
VALIDATE $? "Installing mongodb"

systemctl enable mongod 
VALIDATE $? "enable mongodb"

systemctl start mongod 
VALIDATE $? "start mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to mongodb"

systemctl restart mongodb
VALIDATE $? "Resatarted MongoDB"
