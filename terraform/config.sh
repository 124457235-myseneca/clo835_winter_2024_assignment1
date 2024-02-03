#!/bin/bash
sudo yum update -y
sudo yum install -y docker git
sudo usermod -a -G docker ec2-user
sudo systemctl start docker
sudo systemctl enable docker

