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

dnf install nginx -y
validate $? "install nginx"

systemctl enable nginx
systemctl start nginx
validate $? "start nginx"

rm -rf /usr/share/nginx/html/*
validate $? "remove default content"

curl -L -o /tmp/frontend.tar.gz https://raw.githubusercontent.com/daws-92s/expense-documentation/refs/heads/main/artifacts/expense-frontend-v5.tar.gz &>> $logs_file
validate $? "downloading code"

cd /usr/share/nginx/html
tar -xzf /tmp/frontend.tar.gz
validate $? "unzipping code"

# /etc/nginx/default.d/expense.conf

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/expense.conf" 
cp "$scripts_dir/expense.conf" /etc/nginx/default.d/expense.conf
validate $? "Copy conf file"


systemctl restart nginx
validate $? "Restart nginx"



