#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
scripts_dir=$(dirname "$(realpath "$0")")
domain_name="yanvisol.online"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


check_root(){
    if [ $user_id -ne 0 ]; then
        echo "Please run this script with sudo access.."
        exit 1
    fi
}

timestamp(){
    date "+%F %T" 
}

mkdir -p $logs_folder
echo -e "$(timestamp) [INFO] ==== Script started Execution =====" | tee -a $logs_file

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] ${2}..${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "$(timestamp) [INFO] ${2}..${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

dnf module disable nodejs -y
dnf module enable nodejs:24 -y
dnf install nodejs -y
validate $? "Installing nodejs"

rm -rf /app
validate $? "Removing old code"

mkdir -p /app
validate $? "Creating app directory"

id expense &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "expense system user" expense &>> $logs_file
    validate $? "Creating system user"
else
    echo -e "$(timestamp) [INFO] System user roboshop already exist...${Y}SKIPPING${N}"
fi

curl -L -o /tmp/backend.tar.gz https://raw.githubusercontent.com/daws-92s/expense-documentation/refs/heads/main/artifacts/expense-backend-v5.tar.gz &>> $logs_file
validate $? "Downloading Code"

cd /app
tar -xzf /tmp/backend.tar.gz
validate $? "Unzipping Code"

npm install
validate $? "Installing dependencies"

#/etc/systemd/system/backend.service

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/backend.service"
cp "$scripts_dir/backend.service" /etc/systemd/system/backend.service
validate $? "copy backend service"

systemctl daemon-reload
validate $? "daemon reload"

systemctl enable backend
validate $? "backend enable "

systemctl start backend
validate $? "start backend"

dnf install mysql -y
validate $? "install mysql client"

mysql -h mysql.$domain_name -u root -pExpenseApp@1 < /app/schema/backend.sql
validate $? "load schema"


systemctl restart backend
validate $? "re-start backend"
