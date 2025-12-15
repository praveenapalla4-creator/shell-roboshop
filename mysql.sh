
#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1)
START_TIME=$(date +%s)

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

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing MySql server "

systemctl enable mysqld
VALIDATE $? "enable mysql server"

systemctl start mysqld
VALIDATE $? "Starting MySql server "  

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "Setting up root password "  


END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script executed in: $Y $TOTAL_TIME seconds: $N"