#!/bin/bash

# Redirect all output to a log file
exec > /var/log/user-data.log 2>&1

# Save this script to a file on the instance for future reference
cat << 'EOF' > /home/ec2-user/setup.sh
#!/bin/bash

# Redirect all output to a log file
exec > /var/log/user-data.log 2>&1

# Update the package index
sudo yum update -y

# Install wget if not already installed
sudo yum install -y wget

# Install Java (Amazon Corretto 11)
sudo yum install -y java-11-amazon-corretto

# Change to a directory with write permissions
cd /home/ec2-user

# Install Tomcat
sudo wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.96/bin/apache-tomcat-9.0.96.tar.gz
tar -xvf apache-tomcat-9.0.96.tar.gz

# Set environment variables
echo "export CATALINA_HOME=/home/ec2-user/apache-tomcat-9.0.96" >> ~/.bash_profile
echo "export JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto" >> ~/.bash_profile

# Source the profile to load the new environment variables
source ~/.bash_profile

# Start Tomcat
/home/ec2-user/apache-tomcat-9.0.96/bin/startup.sh
EOF

# Make the script executable
chmod +x /home/ec2-user/setup.sh

# Execute the saved script
/home/ec2-user/setup.sh