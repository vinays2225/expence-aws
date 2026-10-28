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
validate $? "Install nginx"

rm -f /etc/nginx/nginx.conf
validate $? "removing nginx.conf"

#/etc/nginx/nginx.conf

sed -i "s/DOMAIN_NAME/$domain_name" "$scripts_dir/lb.conf"
cp "$scripts_dir/lb.conf" /etc/nginx/nginx.conf

systemctl enable nginx
validate $? "nginx enable"

systemctl start nginx
validate $? "Nginx start"