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


PROMETHEUS_VERSION="2.41.0"  # Cambia esto a la ultima version estable
NODE_EXPORTER_VERSION="1.5.0"  # Cambia esto a la ultima version estable

# --- Actualizacion del sistema y descarga de herramientas basicas ---
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget tar

# --- Instalacion de Prometheus ---
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
tar -xvf prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
sudo mv prometheus-$PROMETHEUS_VERSION.linux-amd64 /usr/local/prometheus

# Crear el archivo de configuracion prometheus.yml
sudo tee /usr/local/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Crear el servicio systemd para Prometheus
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
User=root
ExecStart=/usr/local/prometheus/prometheus --config.file=/usr/local/prometheus/prometheus.yml

[Install]
WantedBy=multi-user.target
EOF

# Iniciar y habilitar Prometheus
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

# --- Instalacion de Node Exporter ---
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
tar -xvf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
sudo mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin/

# Crear el servicio systemd para Node Exporter
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Iniciar y habilitar Node Exporter
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# --- Documentacion ---
# Crear el archivo prometheus_setup.txt si no existe y escribir en el
touch /home/vagrant/prometheus_setup.txt

echo "Documentacion de rutas y archivos de configuracion:" > /home/vagrant/prometheus_setup.txt
echo "Prometheus:" >> /home/vagrant/prometheus_setup.txt
echo "  Configuracion: /usr/local/prometheus/prometheus.yml" >> /home/vagrant/prometheus_setup.txt
echo "  Ejecucion: /etc/systemd/system/prometheus.service" >> /home/vagrant/prometheus_setup.txt
echo "Node Exporter:" >> /home/vagrant/prometheus_setup.txt
echo "  Ejecucion: /etc/systemd/system/node_exporter.service" >> /home/vagrant/prometheus_setup.txt

# Documentacion de metricas del sistema
echo "Documentacion de metricas:" >> /home/vagrant/prometheus_setup.txt
echo "1. **Uso de CPU (`node_cpu_seconds_total`)**: Muestra la cantidad total de tiempo que la CPU ha pasado en diferentes estados (usuario, sistema, inactivo, etc.), util para monitorear el uso general de CPU y la carga de trabajo." >> /home/vagrant/prometheus_setup.txt
echo "2. **Memoria disponible (`node_memory_MemAvailable_bytes`)**: Indica la cantidad de memoria libre que puede ser utilizada por aplicaciones y procesos; es util para monitorear la disponibilidad de recursos de memoria." >> /home/vagrant/prometheus_setup.txt
echo "3. **Espacio en disco (`node_filesystem_avail_bytes`)**: Muestra la cantidad de espacio disponible en los sistemas de archivos montados; ayuda a prever problemas de almacenamiento y prevenir que se quede sin espacio." >> /home/vagrant/prometheus_setup.txt


echo "Accede a Prometheus en http://localhost:9090 para ver las metricas."
#Run application
#cd /home/vagrant/webapp
#export FLASK_APP=run.py
#/usr/local/bin/flask run --host=0.0.0.0
