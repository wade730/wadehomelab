# Here are some example custom monitoring checks I have produced when needed

# This is a custome ceph check I wrote when we awere having some issues with CEPH and needed to identify servers in need of maintenance

mpo=$(ceph -s | grep 'objects misplaced' | cut -b 11-13); if [ $mpo -lt 2 ]; then exit 0 ;
elif [ $mpo -gt 2 -a -lt 5 ] ; then echo 'Warning: misplaced objects are at $mpo'; exit 1 ; 
elif [ $mpo -gt 5 ] ; then echo 'Critical: misplaced objects are at $mpo' ; exit 2 ; fi ;

# This is a custom check to see if a CEPH node is synced with an NTP server

sync=$(timedatectl status | grep 'NTP enabled' -a1 | grep 'synchronized:' | cut -b 19-21); 
if [[ $sync == yes ]]; then echo 'This CEPH node is synced with NTP'; exit 0; 
else echo 'This CEPH node is NOT synced with NTP'; exit 1; fi;

# This is a custom check to see if New Relic was installed on a server

file=/etc/newrelic-infra/integrations.d/flex-buffer.yml; 
if [[ -f $file ]]; then echo '$file exists'; exit 0; 
else echo '$file does not exist'; exit 1; fi;

# These are custom checks I wrote to see what version of crowdstrike was on a server and to identify where it was causing issues
# This was needed as the InfoSec team I worked for at the time pushed an untested version of CrowdStrike
# and it brought our entire infrastructure to its knees. We had to see what servers had this version and 
# downgrade via Ansible

cs_version=$(sudo /opt/CrowdStrike/falconctl -g --version | cut -b 11-14); 
if [[ $cs_version == 6.24 ]]; then echo 'Crowd Strike is version 6.24!'; exit 0; 
else echo 'This server needs to have CrowdStrike version changed to 6.24!'; exit 1; fi;

cpu=$(ps aux | grep evbsync | tr -s ' ' | cut -d ' ' -f 3 |  awk '{ sum += int($1)} END { print sum }'); 
if [ $cpu -gt 50 ]; then echo 'Falcon is causing HIGH CPU usage'; exit 2; 
elif [ $cpu -lt 51 ]; then echo 'Falcon is not causing high CPU usage'; exit 0; fi;

# this custom check looks at uptime on a server and warns us if it has been up for a little too long

systemuptime=$(uptime | awk '{print $3}'); if [[ $systemuptime -gt 365 ]]; 
then echo \"WARNING: This server has been up for $systemuptime days\"; exit 1 ; 
elif [[ $systemuptime -lt 365 ]]; 
then echo \"OK: This server has been up for $systemuptime days\"; exit 0; fi;

# this custom check looks at cpu usage on a node

cpu_usage=$(ps -eo pcpu | awk 'NR>1' | awk '{sum+=$1} END {print sum}')
if (( $(echo "$cpu_usage > 85" | bc -l) )); then
  echo "WARNING: CPU usage is over 85% ($cpu_usage%)"
  exit 1
fi

# this custom check looks at memory usage on a node

mem_usage=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100}')
if [[ $mem_usage -gt 90 ]]; then
  echo "CRITICAL: Memory usage is at ${mem_usage}%"
  exit 2
fi

# This custom check look at disk usage on a node

disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $disk_usage -gt 90 ]]; then
  echo "ALERT: Root disk usage is at ${disk_usage}%"
  exit 2
fi

# This custom check looks a log file size and alerts if it gets too large 

log_dir="/var/log"
max_size_gb=5
max_size_kb=$((max_size_gb * 1024 * 1024))
alerted=0

echo "Checking for log files over ${max_size_gb}GB in $log_dir..."

# Find all regular files (excluding symlinks) under /var/log
find "$log_dir" -type f | while read -r log; do
  size_kb=$(du -k "$log" | cut -f1)
  if [[ $size_kb -gt $max_size_kb ]]; then
    size_gb=$(awk "BEGIN {printf \"%.2f\", $size_kb/1024/1024}")
    echo "ALERT: Log file $log is ${size_gb}GB – exceeds ${max_size_gb}GB"
    alerted=1
  fi
done

if [[ $alerted -eq 1 ]]; then
  exit 1
else
  echo "All log files are under ${max_size_gb}GB."
  exit 0
fi

# This custom check look to see if the server is Quanta brand and what BIOS it is

hw_type=$(sudo dmidecode | grep 'System Information' -a1 | grep 'Manufacturer' | cut -b  16-21); 
if [[ $hw_type == Quanta ]]; then bios_version=$(sudo dmidecode | grep -A1 Megatrends | grep Version | cut -b 17-18); 
if [[ $bios_version -gt 18 ]]; then echo 'This BIOS is up to date'; exit 0; 
elif [[ $bios_version -lt 19 ]]; then echo 'This BIOS needs to be updated!'; exit 1; fi 
else echo 'This is not a Quanta Server!'; exit 0; fi;

# This custom check looks for whether a reboot is required because of updated system libraries, kernel, or services that haven’t been restarted

if sudo needs-restarting -r &>/dev/null; then
    echo "This server does not need to be restarted."
    exit 0
else
    echo "This server needs to be restarted to apply yum updates."
    exit 1
fi

# checks the zombie process count on a server 

zombie_count=$(ps aux | awk '{ if ($8 == "Z") print $0; }' | wc -l)

if [ "$zombie_count" -gt 0 ]; then
    echo "Found $zombie_count zombie processes!"
    exit 1
else
    echo "No zombie processes found."
    exit 0
fi

# Checks for low disk usage 

threshold=80
usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$usage" -ge "$threshold" ]; then
    echo "Disk usage critical: $usage% used."
    exit 1
else
    echo "Disk usage OK: $usage% used."
    exit 0
fi

# This is a keepalive check used to see if a server is up and running pinging it

host=$(hostname -I | awk '{print $1}') 
count=3

if ping -c $count "$host" > /dev/null 2>&1; then
    echo "Keep-alive successful: $host ($host) is reachable."
    exit 0
else
    echo "Keep-alive failed: $host is NOT responding to ping."
    exit 1
fi

# This check looks for a critical process and ensures it is running 

process="harvester"
if pgrep "$process" > /dev/null; then
  echo "$process is running"
  exit 0
else
  echo "$process is NOT running"
  exit 1
fi


# Here are some checks that are built into sensu monitoring that I utilized

. /opt/yodlee/sensu_vars && check-file-size.rb -f /var/log/keystone/keystone.log -w 21474883648 -c 3221225472

. /opt/yodlee/sensu_vars && check-process.rb -p falcon-sensor


