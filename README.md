# To Run application

## Start and SSH into Vagrant VM 

```
vagrant up
vagrant ssh servidorWeb
```

## Run the webApp

```
cd /home/vagrant/webapp
gunicorn -b 0.0.0.0:5000 run:app

```
