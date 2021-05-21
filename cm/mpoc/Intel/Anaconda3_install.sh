wget https://repo.anaconda.com/archive/Anaconda3-5.0.0-Linux-x86_64.sh
bash Anaconda3-5.0.0-Linux-x86_64.sh -b -f -p /opt/anaconda3
echo "PATH=/opt/anaconda3/bin:$PATH" > /etc/environment
source /etc/environment
