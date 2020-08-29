#!/bin/bash

sudo systemctl enable docker 
sudo systemctl start docker ¨
git clone https://github.com/laradock/laradock.git 
cd laradock && cp env-example .env 
sudo usermod -aG docker vagrant 
sudo docker-compose up -d nginx postgres
