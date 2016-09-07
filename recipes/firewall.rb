include_recipe 'iptables::default'

iptables_rule 'mysql' do
  action :enable
end

iptables_rule 'http' do
  action :enable
end
