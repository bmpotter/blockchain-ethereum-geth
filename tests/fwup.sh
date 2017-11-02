iptables -I OUTPUT 1 -p tcp --sport 22 -j ACCEPT -m comment --comment "ssh_output"
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT -m comment --comment "ssh_input"
iptables -A OUTPUT -j DROP -m comment --comment "output_drop"
iptables -A INPUT -j DROP -m comment --comment "input_drop"
iptables -L -n -v --line-numbers
