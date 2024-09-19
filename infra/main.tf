# Versions 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Authentication to AWS from Terraform code
provider "aws" {
  region  = "ap-south-1"
  profile = "default"
}

terraform {
  backend "s3" {
    bucket = "ims-demobucket"
    key    = "projects_statefile/terraform.state"
    region = "ap-south-1"
  }
}

# Continuous Integration - Jenkins
resource "aws_instance" "IMS_jenkins" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id_1a
  vpc_security_group_ids = ["sg-0079d5b752b2c5e99"]

  #user_data              = file("C:\Users\srava\Desktop\Terraform\Iac-Terraform\jenkins.sh.txt")

  user_data = <<-EOF
  #!/bin/bash
  sudo hostnamectl set-hostname "jenkins.inventorymanagementsystem.io"
  echo "`hostname -I | awk '{ print $1 }'` `hostname`" >> /etc/hosts
  sudo apt-get update
  sudo apt-get install git wget unzip curl tree -y
  sudo apt-get -y install git binutils
  sudo apt-get install openjdk-17-jdk -y
  sudo apt-get install maven -y
  sudo cp -pvr /etc/environment "/etc/environment_$(date +%F_%R)"
  echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/" >> /etc/environment
  echo "MAVEN_HOME=/usr/share/maven" >> /etc/environment
  source /etc/environment
  sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
  echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
  sudo apt-get update
  sudo apt-get install jenkins -y
  sudo systemctl enable jenkins
  sudo systemctl start jenkins
  EOF

  tags = {
    Name        = "Jenkins"
    Environment = "Dev"
    ProjectName = "Inventory Management System"
    ProjectID   = "2024"
    CreatedBy   = "IaC Terraform"
  }
}

# Continuous Static Code Analysis Tool - SonarQube
resource "aws_instance" "IMS_sonarqube" {
  ami                    = var.ami
  instance_type          = var.sonar_instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id_1a
  vpc_security_group_ids = ["sg-0079d5b752b2c5e99"]

   #user_data              = file("C:\Users\srava\Desktop\Terraform\Iac-Terraform\sonarqube.sh.txt")
  user_data = <<-EOF
  #!/bin/bash
  sudo hostnamectl set-hostname "sonarqube.inventorymanagementsystem.io"
  echo "`hostname -I | awk '{ print $1 }'` `hostname`" >> /etc/hosts
  sudo apt-get update
  sudo apt-get install git wget unzip zip curl tree -y
  sudo apt-get install docker.io -y
  sudo usermod -aG docker ubuntu
  sudo chmod 777 /var/run/docker.sock
  sudo systemctl enable docker
  sudo systemctl restart docker
  sudo docker pull sonarqube
  sudo docker images
  docker volume create sonarqube-conf
  docker volume create sonarqube-data
  docker volume create sonarqube-logs
  docker volume create sonarqube-extensions
  docker volume inspect sonarqube-conf
  docker volume inspect sonarqube-data
  docker volume inspect sonarqube-logs
  docker volume inspect sonarqube-extensions
  mkdir /sonarqube
  ln -s /var/lib/docker/volumes/sonarqube-conf/_data /sonarqube/conf
  ln -s /var/lib/docker/volumes/sonarqube-data/_data /sonarqube/data
  ln -s /var/lib/docker/volumes/sonarqube-logs/_data /sonarqube/logs
  ln -s /var/lib/docker/volumes/sonarqube-extensions/_data /sonarqube/extensions
  docker run -d --name Inventorymanagemetsystemsonarqube -p 9000:9000 -p 9092:9092 -v sonarqube-conf:/sonarqube/conf -v sonarqube-data:/sonarqube/data -v sonarqube-logs:/sonarqube/logs -v sonarqube-extensions:/sonarqube/extensions sonarqube


  EOF

  tags = {
    Name        = "SonarQube"
    Environment = "Dev"
    ProjectName = "Inventory Management System"
    ProjectID   = "2024"
    CreatedBy   = "IaC Terraform"
  }
}

# Continuous Binary Code Repository - JFROG
resource "aws_instance" "IMS_jfrog" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id_1a
  vpc_security_group_ids = ["sg-0079d5b752b2c5e99"]

  #user_data              = file("C:\Users\srava\Desktop\Terraform\Iac-Terraform\Jfrog.sh.txt")
  user_data = <<-EOF
  #!/bin/bash
  sudo hostnamectl set-hostname "jfrog.inventorymanagementsystem.io"
  echo "`hostname -I | awk '{ print $1}'` `hostname`" >> /etc/hosts
  sudo apt-get update
  sudo apt-get install vim curl elinks unzip wget tree git -y
  sudo apt-get install openjdk-17-jdk -y
  sudo cp -pvr /etc/environment "/etc/environment_$(date +%F_%R)"
  echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/" >> /etc/environment
  source /etc/environment

  cd /opt/
  
  #sudo wget https://releases.jfrog.io/artifactory/bintray-artifactory/org/artifactory/oss/jfrog-artifactory-oss/[RELEASE]/jfrog-artifactory-oss-[RELEASE]-linux.tar.gz
  
  sudo wget https://releases.jfrog.io/artifactory/bintray-artifactory/org/artifactory/oss/jfrog-artifactory-oss/7.71.3/jfrog-artifactory-oss-7.71.3-linux.tar.gz
  
  tar xvzf jfrog-artifactory-oss-7.71.3-linux.tar.gz
  
  mv artifactory-oss-* jfrog
  
  sudo cp -pvr /etc/environment "/etc/environment_$(date +%F_%R)"
  
  echo "JFROG_HOME=/opt/jfrog" >> /etc/environment
  
  #cd /opt/jfrog/app/bin/
  
  #./artifactory.sh status
  
  # Configure INIT Scripts for JFrog Artifactory
  # sudo vi /etc/systemd/system/artifactory.service

  echo "[Unit]" > /etc/systemd/system/artifactory.service
  echo "Description=JFrog artifactory service" >> /etc/systemd/system/artifactory.service
  echo "After=syslog.target network.target" >> /etc/systemd/system/artifactory.service
  echo "[Service]" >> /etc/systemd/system/artifactory.service
  echo "Type=forking" >> /etc/systemd/system/artifactory.service
  echo "ExecStart=/opt/jfrog/app/bin/artifactory.sh start" >> /etc/systemd/system/artifactory.service
  echo "ExecStop=/opt/jfrog/app/bin/artifactory.sh stop" >> /etc/systemd/system/artifactory.service
  echo "User=root" >> /etc/systemd/system/artifactory.service
  echo "Group=root" >> /etc/systemd/system/artifactory.service 
  echo "Restart=always" >> /etc/systemd/system/artifactory.service
  echo "[Install]" >> /etc/systemd/system/artifactory.service
  echo "WantedBy=multi-user.target" >> /etc/systemd/system/artifactory.service

  sudo systemctl daemon-reload
  sudo systemctl enable artifactory.service
  sudo systemctl restart artifactory.service

  #Sonar admin & admin | Jfrog admin & password 

  EOF
  
  tags = {
    Name        = "JFrog"
    Environment = "Dev"
    ProjectName = "Inventory Management System"
    ProjectID   = "2024"
    CreatedBy   = "IaC Terraform"
  }
}

# Application Server - Apache Tomcat 
resource "aws_instance" "IMS_tomcat" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id_1a
  vpc_security_group_ids = ["sg-0079d5b752b2c5e99"]

    #user_data              = file("C:\Users\srava\Desktop\Terraform\Iac-Terraform\tomcat.sh.txt")
  user_data = <<-EOF
  #!/bin/bash
  sudo hostnamectl set-hostname "tomcat.inventorymanagementsystem.io"
  echo "`hostname -I | awk '{ print $1}'` `hostname`" >> /etc/hosts
  sudo apt-get update
  sudo apt-get install vim curl elinks unzip wget tree git -y
  sudo apt-get install openjdk-17-jdk -y
  sudo cp -pvr /etc/environment "/etc/environment_$(date +%F_%R)"
  echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/" >> /etc/environment
  source /etc/environment
  cd /opt/
  sudo wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.95/bin/apache-tomcat-9.0.95.tar.gz
  tar xvzf apache-tomcat-9.0.95.tar.gz
  mv apache-tomcat-9.0.95 tomcat
  sudo cp -pvr /opt/tomcat/conf/tomcat-users.xml "/opt/tomcat/conf/tomcat-users.xml_$(date +%F_%R)"
  sed -i '$d' /opt/tomcat/conf/tomcat-users.xml

  echo '<role rolename="manager-gui"/>'  >> /opt/tomcat/conf/tomcat-users.xml
  echo '<role rolename="manager-script"/>' >> /opt/tomcat/conf/tomcat-users.xml
  echo '<role rolename="manager-jmx"/>'    >> /opt/tomcat/conf/tomcat-users.xml
  echo '<role rolename="manager-status"/>' >> /opt/tomcat/conf/tomcat-users.xml
  
  echo '<role rolename="admin-gui"/>'     >> /opt/tomcat/conf/tomcat-users.xml
  echo '<role rolename="admin-script"/>' >> /opt/tomcat/conf/tomcat-users.xml

  echo '<user username="admin" password="vahin@030821" roles="manager-gui,manager-script,manager-jmx,manager-status,admin-gui,admin-script"/>' >> /opt/tomcat/conf/tomcat-users.xml
  
  echo "</tomcat-users>" >> /opt/tomcat/conf/tomcat-users.xml

  cd /opt/tomcat/bin/

  ./startup.sh

  EOF

  #To give access to manager and host-manager
    #1.manager
     # vi /opt/tomcat/webapps/manager/META-INF/context.xml
     #give permission as |.* at line 22


     #2.host-manager
     # vi /opt/tomcat/webapps/host-manager/META-INF/context.xml
     #give permission as |.* at line 22
  
  tags = {
    Name        = "tomcat"
    Environment = "Dev"
    ProjectName = "Inventory Management System"
    ProjectID   = "2024"
    CreatedBy   = "IaC Terraform"
  }
}

# Outputs
output "jenkins_ami" {
  value = aws_instance.IMS_jenkins.ami
}
output "jenkins_public_ip" {
  value = aws_instance.IMS_jenkins.public_ip
}
output "jenkins_private_ip" {
  value = aws_instance.IMS_jenkins.private_ip
}

output "sonar_ami" {
  value = aws_instance.IMS_jenkins.ami
}

output "sonar_public_ip" {
  value = aws_instance.IMS_sonarqube.public_ip
}
output "sonar_private_ip" {
  value = aws_instance.IMS_sonarqube.private_ip
}

output "jfrog_ami" {
  value = aws_instance.IMS_jenkins.ami
}

output "jfrog_public_ip" {
  value = aws_instance.IMS_jfrog.public_ip
}
output "jfrog_private_ip" {
  value = aws_instance.IMS_jfrog.private_ip
}

output "tomcat_ami" {
  value = aws_instance.IMS_jenkins.ami
}

output "tomcat_public_ip" {
  value = aws_instance.IMS_tomcat.public_ip
}
output "tomcat_private_ip" {
  value = aws_instance.IMS_tomcat.private_ip
}
