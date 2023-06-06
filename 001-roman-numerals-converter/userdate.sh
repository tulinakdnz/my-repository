#!/bin/bash

yum update -y
yum install python3 -y
yum install python3-pip -y
pip3 install flask
cd /home/ec2-userwget
wget https://raw.githubusercontent.com/tulinakdnz/my-repository/main/001-roman-numerals-converter/app.py
mkdir templates
cd templates
wget https://raw.githubusercontent.com/tulinakdnz/my-repository/main/001-roman-numerals-converter/templates/index.html 
wget https://raw.githubusercontent.com/tulinakdnz/my-repository/main/001-roman-numerals-converter/templates/result.html
cd ..
python3 app.py







