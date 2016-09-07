# # encoding: utf-8

# Inspec test for recipe Task3::default

# The Inspec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec_reference.html

# describe selinux do
#   it { should be_disabled }
# end

describe package 'mysql-community-server' do
  it { should be_installed }
end

describe package 'mysql-community-client' do
  it { should be_installed }
end

describe service 'mysql-t3' do
  it { should be_enabled }
  it { should be_running }
end

describe port 3306 do
  it { should be_listening }
end

describe user('backup') do
  it { should exist }
end

describe directory('/opt/backups') do
  it { should exist }
end

describe file('/etc/cron.d/mysql_backup_prod') do
  it { should exist }
end

describe file('/etc/cron.d/mysql_backup_stage') do
  it { should exist }
end

describe package 'httpd' do
  it { should be_installed }
end

describe service 'httpd' do
  it { should be_enabled }
  it { should be_running }
end

describe port 80 do
  it { should be_listening }
end

# We can't check for presence of backup files in HTTP response because
# there is low chance that cron generated them to the current moment.
# So we check for "Last modified" instead to ensure it's directory listing,
# not default Apache welcome page.

describe command 'curl -L Task3' do
  its('stdout') { should match 'Last modified' }
end
