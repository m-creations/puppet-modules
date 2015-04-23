require 'spec_helper'

describe 'zookeeper::os::redhat', :type => :class do
  shared_examples 'redhat-install' do |os, codename|
    let(:facts) {{
      :operatingsystem => os,
      :osfamily => 'RedHat',
      :lsbdistcodename => codename,
    }}

    it { should contain_package('zookeeper') }
    it { should_not contain_package('cron') }

    context 'with cron' do
      let(:user) { 'zookeeper' }
      let(:group) { 'zookeeper' }

      let(:params) { {
        :snap_retain_count => 5,
        :manual_clean      => true,
      } }

      it { should contain_package('zookeeper') }
      it { should contain_package('cron') }

      it 'installs cron script' do
        should contain_cron('zookeeper-cleanup').with({
          'ensure'    => 'present',
          'command'   => '/usr/lib/zookeeper/bin/zkCleanup.sh /var/lib/zookeeper 5',
          'user'      => 'zookeeper',
          'hour'      => '2',
          'minute'      => '42',
        })
      end
    end

    context 'allow installing multiple packages' do
      let(:user) { 'zookeeper' }
      let(:group) { 'zookeeper' }

      let(:params) { {
        :packages => [ 'zookeeper', 'zookeeper-devel' ],
      } }

      it { should contain_package('zookeeper') }
      it { should contain_package('zookeeper-devel') }
    end

    context 'removing package' do
      let(:user) { 'zookeeper' }
      let(:group) { 'zookeeper' }

      let(:params) { {
        :ensure => 'absent',
      } }

      it {

        should contain_package('zookeeper').with({
        'ensure'  => 'absent',
        })
      }
      it {
        should_not contain_package('zookeeperd').with({
        'ensure'  => 'present',
        })
      }
      it { should_not contain_package('cron') }
    end

  end

  context 'on RedHat-like system' do
    let(:user) { 'zookeeper' }
    let(:group) { 'zookeeper' }

    let(:params) { {
      :snap_retain_count => 1,
    } }

    it_behaves_like 'redhat-install', 'RedHat', '6'
    it_behaves_like 'redhat-install', 'CentOS', '5'
    it_behaves_like 'redhat-install', 'Fedora', '20'
  end
end
