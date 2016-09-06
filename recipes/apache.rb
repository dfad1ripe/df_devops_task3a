#
# First, install apache from the community code

# include_recipe 'apache2'

# Place VirtualHost description to apache conf dir.

# cookbook_file '/etc/httpd/sites-enabled/mysql.conf' do
#   source 'apache/mysql.conf'
#   mode '0644'
# end

#
# Allow connections

# cookbook_file '/opt/backups/.htaccess' do
#   source 'apache/.htaccess'
#   mode '0644'
# end

# http_port = 80

#
# Remove COMMIT from iptables config file

# execute 'remove commit step 1 (apache)' do
#   command "grep -v COMMIT /etc/sysconfig/iptables > \
# {Chef::Config['file_cache_path']}/iptables2"
#   not_if "/sbin/iptables --list -n | grep dpt:#{http_port} | grep ACCEPT"
# end

# execute 'remove commit step 2 (apache)' do
#   command "cp #{Chef::Config['file_cache_path']}/iptables2 \
# /etc/sysconfig/iptables"
#   only_if { ::File.exist?("#{Chef::Config['file_cache_path']}/iptables2") }
# end

# file "#{Chef::Config['file_cache_path']}/iptables2" do
#   action :delete
# end

#
# Add and permanently store INPUT rules

# execute 'allow http in iptables INPUT' do
#   command "/sbin/iptables -A INPUT -p tcp --dport #{http_port} -j ACCEPT"
#   not_if "/sbin/iptables --list -n | grep dpt:#{http_port} | grep ACCEPT"
# end

# execute 'store iptables INPUT changes (apache)' do
#   command "echo \"-A INPUT -p tcp --dport #{http_port} -j ACCEPT\" \
# >> /etc/sysconfig/iptables"
#   not_if "grep \"dport #{http_port}\" /etc/sysconfig/iptables | grep ACCEPT"
# end

#
# Add and permanently store OUTPUT rules

# execute 'allow http in iptables OUTPUT' do
#   command "/sbin/iptables -A OUTPUT -p tcp --sport #{http_port} -j ACCEPT"
#   not_if "/sbin/iptables --list -n | grep spt:#{http_port} | grep ACCEPT"
# end

# execute 'store iptables OUTPUT changes (apache)' do
#   command "echo \"-A OUTPUT -p tcp --sport #{http_port} -j ACCEPT\" \
# >> /etc/sysconfig/iptables"
#   not_if "grep \"sport #{http_port}\" /etc/sysconfig/iptables | grep ACCEPT"
# end

#
# Add COMMIT footer

# execute 'iptables commit footer (apache)' do
#   command 'echo "COMMIT" >> /etc/sysconfig/iptables'
#   not_if 'grep COMMIT /etc/sysconfig/iptables'
# end
