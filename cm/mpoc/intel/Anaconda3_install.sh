os=uname
arc=lscpu | grep Arch | awk '{print $2}'
os_version=$os-$arc
echo $os_version

wget https://repo.anaconda.com/archive/Anaconda3-5.0.0-$os_version.sh
bash Anaconda3-5.0.0-Linux-x86_64.sh -b -f -p /opt/anaconda3
echo "PATH=/opt/anaconda3/bin:$PATH" > /etc/environment
printf 'Please run the command: "source /etc/environment" to enable anaconda utils on environment \n'
rm Anaconda3-5.0.0-Linux-x86_64.sh 
