## Configuring AWS EC2 instance

### Install dependencies

```
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools python3-venv
```

```
git clone https://github.com/hnrkcode/flask-test-app.git
cd flask-test-app/
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install wheel
pip install -r requirements.txt
```



### Configure gunicorn

```
sudo nano /etc/systemd/system/flask-test-app.service
```

Paste this:

```
[Unit]
Description=Gunicorn instance to serve flask-test-app
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/flask-test-app
Environment="PATH=/home/ubuntu/flask-test-app/venv/bin"
ExecStart=/home/ubuntu/flask-test-app/venv/bin/gunicorn --workers 3 --bind unix:flask-test-app.sock -m 007 app:app

[Install]
WantedBy=multi-user.target
```

```
sudo systemctl start flask-test-app
sudo systemctl enable flask-test-app
```

### Configure nginx

```
sudo apt-get -y update && sudo apt-get -y install nginx
```

```
sudo nano /etc/nginx/nginx.conf
```

Change this:

```
user www-data; -> user ubuntu;

# server_names_hash_bucket_size 64; -> server_names_hash_bucket_size 64;
```

```
sudo nano /etc/nginx/sites-available/flask-test-app
```

Paste this:

```
server {
    listen 80;
    server_name ec2_public_ip *.eu-north-1.compute.amazonaws.com;

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/ubuntu/flask-test-app/flask-test-app.sock;
    }
}
```

```
sudo ln -s /etc/nginx/sites-available/flask-test-app /etc/nginx/sites-enabled
sudo nginx -t
sudo systemctl restart nginx
```

### Configure HTTPS

```
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --nginx -d your_domain -d www.your_domain
```