#
# Cookbook Name:: Task3
# Recipe:: default
#
# Copyright (c) 2016 Dmytro

#
# First, disable selinux as the community code for MySQL requires

include_recipe 'selinux::disabled'

#
# Second, using community code to install MySQL

include_recipe 'yum_mysql_community'

mysql_pwd = 'devops'

# For future, hashed with SHA-512:
# 2e04c978070fb9756cde6a684aebd608c330ab6734aac6e6f52c642191
# 32cc383e0d00dd31bc6a696c7a14fd69e2c83a8800bb54148b6769de19f9bb1098806d

mysql_port = '3306' # it's used few times later

mysql_service 't3' do
  bind_address '0.0.0.0'
  port mysql_port
  version '5.6'
  # Because 5.7 is not available in mysql_community_* packages yet.
  initial_root_password mysql_pwd
  action [:create, :start]
end

#
# Since that moment, we need to address correct MySQL socket.
# The code below is NOT cross-platform.

mysql_socket = '-S /var/run/mysql-t3/mysqld.sock'
mysql_cmd = "mysql #{mysql_socket} -p#{mysql_pwd}"

#
# Create connection info as an external ruby hash

# mysql_connection_info = {
#   :host     => '127.0.0.1',
#   :username => 'root',
#   :password => mysql_pwd
# }

#
# Create mysql users

# db_users = data_bag('db_users')
# db_users.each do |dbu|
#   db_user = data_bag_item('db_users', dbu)
#   db_username = db_user['username']
#   db_full_username = "'#{db_username}'@'localhost'"
#   mysql_arg = "create user #{db_full_username} identified by '#{db_username}'"
#   mysql_database_user db_username do
#     connection mysql_connection_info
#     password   'devops'
#     action     :create
#   end
# end
