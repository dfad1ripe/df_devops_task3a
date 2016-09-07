require 'chefspec'
require 'chefspec/berkshelf'

describe 'Task3::default' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new
    runner.converge(described_recipe)
  end

  it 'converges successfully' do
    expect { chef_run }.to raise_error(RuntimeError, 'chefspec not supported!')
  end

  packages = ['mysql-community-server', 'mysql-community-client', 'httpd']

  packages.each do |package|
    it "installs #{package}" do
      expect(chef_run).to raise_error(RuntimeError, 'chefspec not supported!')
      expect(chef_run).to install_package package
    end
  end
end

# it "enables the #{service} service" do
#   expect(chef_run).to enable_service service
# end

# it "starts the #{service} service" do
#   expect(chef_run).to start_service service
# end
