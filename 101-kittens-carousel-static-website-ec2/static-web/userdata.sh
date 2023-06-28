#! /bin/bash -x
yum update -y
yum install httpd -y
cd /var/www/html
FOLDER="https://raw.githubusercontent.com/tulinakdnz/my-repository/main/101-kittens-carousel-static-website-ec2/static-web/index.html/"
             wget ${FOLDER}index.html
            wget ${FOLDER}cat0.jpg
            wget ${FOLDER}cat1.jpg
            wget ${FOLDER}cat2.jpg
            systemctl start httpd
            systemctl enable httpd