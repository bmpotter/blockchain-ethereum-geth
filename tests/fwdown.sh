

iptables -L -n -v --line-numbers

iptables -D INPUT $(iptables -L -n -v --line-numbers | grep input_drop | awk '{print $1}')
iptables -D OUTPUT $(iptables -L -n -v --line-numbers | grep output_drop | awk '{print $1}')
iptables -D INPUT $(iptables -L -n -v --line-numbers | grep ssh_input | awk '{print $1}')
iptables -D OUTPUT $(iptables -L -n -v --line-numbers | grep ssh_output | awk '{print $1}')

iptables -L -n -v --line-numbers
