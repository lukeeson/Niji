provider "aws" {
    region = "us-east-1"
    access_key = "AKIA4MTWOAC7BPMETF6E"
    secret_key = ""
 }


#Create EC2 Instance Jenkins
resource "aws_instance" "Jenkins_tholcapian_lukeeson" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.cicdSecGrp_tholcapian_lukeeson.id                                                                                                                                                             ]
  key_name      = aws_key_pair.ssh_key_tholcapian_lukeeson.key_name
  tags = {
    Name = "Jenkkins"
  }

#Bootstrap Jenkins Install/Start
user_data = <<-EOF
#!/bin/bash
sudo apt update -y
sudo touch /etc/apt/keyrings/adoptium.asc
sudo wget -O /etc/apt/keyrings/adoptium.asc https://packages.adoptium.net/artifa                                                                                                                                                             ctory/api/gpg/key/public
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.n                                                                                                                                                             et/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) mai                                                                                                                                                             n" | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo apt update -y
sudo apt install temurin-17-jdk -y
/usr/bin/java --version
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /                                                                                                                                                             usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins                                                                                                                                                             .io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev                                                                                                                                                             /null
sudo apt-get update -y
sudo apt-get install jenkins -y
sudo systemctl start jenkins
  EOF
user_data_replace_on_change = true
}


#Create EC2 instance Prometheus-Grafana
resource "aws_instance" "Prometheus-Grafana_tholcapian_lukeeson" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.cicdSecGrp_tholcapian_lukeeson.id                                                                                                                                                             ]
  key_name      = aws_key_pair.ssh_key_tholcapian_lukeeson.key_name
  tags = {
    Name = "Prometheus-Grafana"
  }

  #Bootstrap Prometheus & Grafana Install/Start
  user_data = <<-EOF
#!/bin/bash
 sudo useradd --system --no-create-home --shell /bin/false prometheus
 sudo apt install wget -y
 wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometh                                                                                                                                                             eus-2.47.1.linux-amd64.tar.gz
 tar -xvf prometheus-2.47.1.linux-amd64.tar.gz
 sudo mkdir -p /data /etc/prometheus
 cd prometheus-2.47.1.linux-amd64/
 sudo mv prometheus promtool /usr/local/bin/
 sudo mv consoles/ console_libraries/ /etc/prometheus/
 sudo mv prometheus.yml /etc/prometheus/prometheus.yml
 sudo chown -R prometheus:prometheus /etc/prometheus/ /data/
 cd
 rm -rf prometheus-2.47.1.linux-amd64.tar.gz
 sudo touch /etc/systemd/system/prometheus.service
 echo "
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml                                                                                                                                                              --storage.tsdb.path=/data --web.console.templates=/etc/prometheus/consoles --we                                                                                                                                                             b.console.libraries=/etc/prometheus/console_libraries --web.listen-address=0.0.0                                                                                                                                                             .0:9090
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/prometheus.service

sudo systemctl enable prometheus
sudo systemctl start prometheus


sudo apt-get install -y apt-transport-https software-properties-common
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt                                                                                                                                                             /keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stab                                                                                                                                                             le main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get -y install grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
 EOF
user_data_replace_on_change = true
}


#Create Security Group
resource "aws_security_group" "cicdSecGrp_tholcapian_lukeeson" {
  name        = "cicdSecGrp"
  description = "CICD Security Group"

  #Allow Inbound SSH Traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow Inbound HTTP Traffic
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "ssh_key_tholcapian_lukeeson" {
  key_name   = "ssh_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

output "instance_public_ip_Jenkins_tholcapian_lukeeson" {
  description = "Public IP address of the EC2 Jenkins instance"
  value       = aws_instance.Jenkins_tholcapian_lukeeson.public_ip
}

output "instance_public_ip_Prometheus_Grafana_tholcapian_lukeeson" {
  description = "Public IP address of the EC2 Prometheus-Grafana instance"
  value       = aws_instance.Prometheus-Grafana_tholcapian_lukeeson.public_ip
}
