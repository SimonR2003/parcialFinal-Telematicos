#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# Update the package index
echo "Updating package index..."
sudo apt-get update

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg2 \
    lsb-release \
    openssl \
    nginx

# Start nginx and enable it on boot
sudo systemctl start nginx
sudo systemctl enable nginx

# Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg


# Set up the Docker stable repository
echo "Setting up Docker's stable repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package index again
echo "Updating package index again..."
sudo apt-get update

# Install Docker Engine and related packages
echo "Installing Docker Engine, CLI, and Containerd..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
echo "Starting Docker service..."
sudo systemctl start docker

# Enable Docker to start on boot
echo "Enabling Docker to start on boot..."
sudo systemctl enable docker

# Verify Docker installation
echo "Verifying Docker installation..."
sudo docker --version

echo "Docker installation completed successfully!"

# Install MySQL
echo "Installing MySQL"

debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

sudo apt update
sudo apt install mysql-server -y
sudo systemctl start mysql.service

#Create and fill Database
echo "Creating and filling database"
sudo mysql -h localhost -u root -proot < /home/vagrant/init.sql

#Adding permissions to remote access
echo "Adding permissions to remote access"
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql.service

# Instal Python Flask and Flask-MySQLdb
sudo apt install python3-dev default-libmysqlclient-dev build-essential pkg-config mysql-client python3-pip -y
pip3 install Flask==2.3.3
pip3 install flask-cors
pip3 install Flask-MySQLdb
pip install Flask-SQLAlchemy
pip install gunicorn

#Run application
#cd /home/vagrant/webapp
#export FLASK_APP=run.py
#/usr/local/bin/flask run --host=0.0.0.0
