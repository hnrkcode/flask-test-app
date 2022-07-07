#!/bin/bash

# Update system and install packages.
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install \
    python3-pip \
    python3-dev \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-setuptools \
    python3-venv \
    nginx

# Install dependencies for the application.
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install wheel
pip install -r requirements.txt
deactivate

# Configure gunicorn.
gunicorn_config="
[Unit]\n
Description=Gunicorn instance to serve flask-test-app\n
After=network.target\n\n
[Service]\n
User=ubuntu\n
Group=www-data\n
WorkingDirectory=/home/ubuntu/flask-test-app\n
Environment="PATH=/home/ubuntu/flask-test-app/venv/bin"\n
ExecStart=/home/ubuntu/flask-test-app/venv/bin/gunicorn --workers 3 --bind unix:flask-test-app.sock -m 007 app:app\n\n
[Install]\n
WantedBy=multi-user.target\n
"

sudo echo -e $gunicorn_config >> /etc/systemd/system/flask-test-app.service
sudo systemctl start flask-test-app
sudo systemctl enable flask-test-app

# Configure nginx
sudo sed -i '1s/.*/user ubuntu;/' /etc/nginx/nginx.conf
sudo sed -i '22s/.*/        server_names_hash_bucket_size 64;/' /etc/nginx/nginx.conf

ec2_public_ip=$(curl -s http://checkip.amazonaws.com)
site_available_config="
server {\n
\tlisten 80;\n
\tserver_name ${ec2_public_ip} *.eu-north-1.compute.amazonaws.com;\n\n
\tlocation / {\n
\t\tinclude proxy_params;\n
\t\tproxy_pass http://unix:/home/ubuntu/flask-test-app/flask-test-app.sock;\n
\t}\n
}\n
"

sudo echo -e $gunicorn_config >> /etc/nginx/sites-available/flask-test-app
sudo ln -s /etc/nginx/sites-available/flask-test-app /etc/nginx/sites-enabled
sudo systemctl restart nginx