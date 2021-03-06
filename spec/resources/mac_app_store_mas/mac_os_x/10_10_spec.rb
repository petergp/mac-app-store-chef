require_relative '../../../spec_helper'
require_relative '../../../../libraries/helpers_mas'

describe 'resource_mac_app_store_mas::mac_os_x::10_10' do
  let(:name) { 'default' }
  %i(source version username password system_user use_rtun action).each do |p|
    let(p) { nil }
  end
  %i(
    installed?
    installed_version?
    installed_by?
    signed_in_as?
    latest_version?
    upgradable_apps?
  ).each do |p|
    let(p) { nil }
  end
  let(:getlogin) { 'vagrant' }
  let(:runner) do
    ChefSpec::SoloRunner.new(
      step_into: 'mac_app_store_mas', platform: 'mac_os_x', version: '10.10'
    ) do |node|
      %i(
        name source version username password system_user use_rtun action
      ).each do |p|
        unless send(p).nil?
          node.set['resource_mac_app_store_mas_test'][p] = send(p)
        end
      end
    end
  end
  let(:converge) { runner.converge('resource_mac_app_store_mas_test') }

  before(:each) do
    allow(Kernel).to receive(:load).and_call_original
    allow(Kernel).to receive(:load)
      .with(%r{mac-app-store/libraries/helpers_mas\.rb}).and_return(true)
    {
      latest_version?: latest_version?,
      installed?: installed?,
      installed_version?: installed_version?,
      installed_by?: installed_by?,
      signed_in_as?: signed_in_as?,
      upgradable_apps?: upgradable_apps?
    }.each do |k, v|
      allow(MacAppStore::Helpers::Mas).to receive(k).and_return(v)
    end
    allow(Etc).to receive(:getlogin).and_return(getlogin)
  end

  context 'the default action (:install)' do
    let(:action) { nil }
    let(:username) { 'example@example.com' }
    let(:password) { 'abc123' }
    let(:latest_version?) { '1.3.0' }

    context 'the default source (:direct)' do
      let(:source) { nil }

      context 'not already installed' do
        let(:installed?) { false }
        cached(:chef_run) { converge }

        it 'downloads mas-cli.zip from GitHub' do
          expect(chef_run).to create_remote_file(
            "#{Chef::Config[:file_cache_path]}/mas-cli.zip"
          ).with(source: 'https://github.com/argon/mas/releases/download/' \
                         'v1.3.0/mas-cli.zip')
        end

        it 'unzips mas-cli.zip into place' do
          expect(chef_run).to run_execute('Extract Mas-CLI zip file').with(
            command: 'unzip -d /usr/local/bin/ -o ' \
                     "#{Chef::Config[:file_cache_path]}/mas-cli.zip"
          )
        end
      end

      context 'already installed' do
        let(:installed?) { true }
        let(:installed_version?) { '1.1.0' }
        let(:installed_by?) { :direct }
        cached(:chef_run) { converge }

        it 'does not download mas-cli.zip from GitHub' do
          expect(chef_run).to_not create_remote_file(
            "#{Chef::Config[:file_cache_path]}/mas-cli.zip"
          )
        end

        it 'does not unzip mas-cli.zip into place' do
          expect(chef_run).to_not run_execute('Extract Mas-CLI zip file')
        end
      end
    end

    context 'the :homebrew source' do
      let(:source) { :homebrew }

      context 'not already installed' do
        let(:installed?) { false }
        cached(:chef_run) { converge }

        before(:each) do
          stub_command('which git').and_return('git')
        end

        it 'includes the homebrew default recipe' do
          expect(chef_run).to include_recipe('homebrew')
        end

        it 'installs Mas via Homebrew' do
          expect(chef_run).to install_homebrew_package('mas')
        end
      end

      context 'already installed' do
        let(:installed?) { true }
        let(:installed_version?) { '1.1.0' }
        let(:installed_by?) { :direct }
        cached(:chef_run) { converge }

        it 'does not include the homebrew default recipe' do
          expect(chef_run).to_not include_recipe('homebrew')
        end

        it 'does not install Mas via Homebrew' do
          expect(chef_run).to_not install_homebrew_package('mas')
        end
      end
    end

    context 'username property missing' do
      let(:username) { nil }
      cached(:chef_run) { converge }

      it 'raises an error' do
        expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed)
      end
    end

    context 'password property missing' do
      let(:password) { nil }
      cached(:chef_run) { converge }

      it 'raises an error' do
        expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed)
      end
    end
  end

  context 'the :upgrade action' do
    let(:action) { :upgrade }
    let(:latest_version?) { '1.5.0' }

    context 'the default source (:direct)' do
      let(:source) { nil }

      context 'not already installed' do
        let(:installed?) { false }
        cached(:chef_run) { converge }

        it 'downloads mas-cli.zip from GitHub' do
          expect(chef_run).to create_remote_file(
            "#{Chef::Config[:file_cache_path]}/mas-cli.zip"
          ).with(source: 'https://github.com/argon/mas/releases/download/' \
                         'v1.5.0/mas-cli.zip')
        end

        it 'unzips mas-cli.zip into place' do
          expect(chef_run).to run_execute('Extract Mas-CLI zip file').with(
            command: 'unzip -d /usr/local/bin/ -o ' \
                     "#{Chef::Config[:file_cache_path]}/mas-cli.zip"
          )
        end
      end

      context 'already installed' do
        let(:installed?) { true }
        let(:installed_version?) { '1.5.0' }
        let(:installed_by?) { :direct }
        cached(:chef_run) { converge }

        it 'does not download mas-cli.zip from GitHub' do
          expect(chef_run).to_not create_remote_file(
            "#{Chef::Config[:file_cache_path]}/mas-cli.zip"
          )
        end

        it 'does not unzip mas-cli.zip into place' do
          expect(chef_run).to_not run_execute('Extract Mas-CLI zip file')
        end
      end

      context 'installed but in need of an upgrade' do
        let(:installed?) { true }
        let(:installed_version?) { '1.4.0' }
        let(:installed_by?) { :direct }
        cached(:chef_run) { converge }

        it 'downloads mas-cli.zip from GitHub' do
          expect(chef_run).to create_remote_file(
            "#{Chef::Config[:file_cache_path]}/mas-cli.zip"
          ).with(source: 'https://github.com/argon/mas/releases/download/' \
                         'v1.5.0/mas-cli.zip')
        end

        it 'unzips mas-cli.zip into place' do
          expect(chef_run).to run_execute('Extract Mas-CLI zip file').with(
            command: 'unzip -d /usr/local/bin/ -o ' \
                     "#{Chef::Config[:file_cache_path]}/mas-cli.zip"
          )
        end
      end
    end

    context 'the :homebrew source' do
      let(:source) { :homebrew }

      context 'not already installed' do
        let(:installed?) { false }
        cached(:chef_run) { converge }

        before(:each) do
          stub_command('which git').and_return('git')
        end

        it 'includes the homebrew default recipe' do
          expect(chef_run).to include_recipe('homebrew')
        end

        it 'upgrades Mas via Homebrew' do
          expect(chef_run).to upgrade_homebrew_package('mas')
        end
      end

      context 'already installed' do
        let(:installed?) { true }
        let(:installed_version?) { '1.5.0' }
        let(:installed_by?) { :direct }
        cached(:chef_run) { converge }

        it 'does not include the homebrew default recipe' do
          expect(chef_run).to_not include_recipe('homebrew')
        end

        it 'does not upgrade Mas via Homebrew' do
          expect(chef_run).to_not upgrade_homebrew_package('mas')
        end
      end

      context 'installed but in need of an upgrade' do
        let(:installed?) { true }
        let(:installed_version?) { '1.4.0' }
        let(:installed_by?) { :direct }
        cached(:chef_run) { converge }

        before(:each) do
          stub_command('which git').and_return('git')
        end

        it 'includes the homebrew default recipe' do
          expect(chef_run).to include_recipe('homebrew')
        end

        it 'upgrades Mas via Homebrew' do
          expect(chef_run).to upgrade_homebrew_package('mas')
        end
      end
    end
  end

  context 'the :remove action' do
    let(:action) { :remove }

    context 'the default source (:direct)' do
      let(:source) { nil }
      cached(:chef_run) { converge }

      it 'deletes the mas file' do
        expect(chef_run).to delete_file('/usr/local/bin/mas')
      end
    end

    context 'the :homebrew source' do
      let(:source) { :homebrew }
      cached(:chef_run) { converge }

      before(:each) do
        stub_command('which git').and_return('git')
      end

      it 'includes the homebrew default recipe' do
        expect(chef_run).to include_recipe('homebrew')
      end

      it 'removes Mas via Homebrew' do
        expect(chef_run).to remove_homebrew_package('mas')
      end
    end
  end

  context 'the :sign_in action' do
    let(:action) { :sign_in }
    let(:installed?) { true }
    let(:installed_version?) { '1.2.3' }
    let(:installed_by?) { :direct }
    let(:username) { 'example@example.com' }
    let(:password) { 'abc123' }

    context 'not signed in' do
      let(:signed_in_as?) { nil }

      context 'the default system_user property' do
        let(:system_user) { nil }
        let(:chef_run) { converge }

        it 'signs into Mas with the correct system user' do
          expect(chef_run).to run_execute("Sign in to Mas as #{username}")
            .with(command: "mas signin '#{username}' '#{password}'",
                  user: getlogin,
                  returns: [0, 6],
                  sensitive: true)
        end
      end

      context 'an overridden system_user property' do
        let(:system_user) { 'testme' }
        cached(:chef_run) { converge }

        it 'signs into Mas with the correct user' do
          expect(chef_run).to run_execute("Sign in to Mas as #{username}")
            .with(command: "mas signin '#{username}' '#{password}'",
                  user: 'testme',
                  returns: [0, 6],
                  sensitive: true)
        end
      end

      context 'an overridden use_rtun property' do
        let(:use_rtun) { true }
        cached(:chef_run) { converge }

        it 'ensures RtUN is installed' do
          expect(chef_run).to include_recipe('reattach-to-user-namespace')
        end

        it 'signs into Mas using RtUN' do
          expect(chef_run).to run_execute("Sign in to Mas as #{username}")
            .with(command: 'reattach-to-user-namespace mas signin ' \
                           "'#{username}' '#{password}'",
                  user: getlogin,
                  returns: [0, 6],
                  sensitive: true)
        end
      end
    end

    context 'already signed in' do
      let(:signed_in_as?) { 'example@example.com' }
      cached(:chef_run) { converge }

      it 'does not sign into Mas' do
        expect(chef_run).to_not run_execute("Sign in to Mas as #{username}")
      end
    end

    context 'signed in as someone else' do
      let(:signed_in_as?) { '2@example.com' }
      cached(:chef_run) { converge }

      it 'signs into Mas' do
        expect(chef_run).to run_execute("Sign in to Mas as #{username}")
          .with(command: "mas signin '#{username}' '#{password}'",
                user: getlogin,
                returns: [0, 6],
                sensitive: true)
      end
    end

    context 'username property missing' do
      let(:username) { nil }
      cached(:chef_run) { converge }

      it 'raises an error' do
        expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed)
      end
    end

    context 'password property missing' do
      let(:password) { nil }
      cached(:chef_run) { converge }

      it 'raises an error' do
        expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed)
      end
    end
  end

  context 'the :sign_out action' do
    let(:action) { :sign_out }
    let(:installed?) { true }
    let(:installed_version?) { '1.2.3' }
    let(:installed_by?) { :direct }

    context 'signed in' do
      let(:signed_in_as?) { 'example@example.com' }

      context 'the default system_user property' do
        let(:system_user) { nil }
        cached(:chef_run) { converge }

        it 'signs out of Mas with the correct system user' do
          expect(chef_run).to run_execute('Sign out of Mas')
            .with(command: 'mas signout', user: getlogin)
        end
      end

      context 'an overridden system_user property' do
        let(:system_user) { 'testme' }
        cached(:chef_run) { converge }

        it 'signs out of Mas with the correct system user' do
          expect(chef_run).to run_execute('Sign out of Mas')
            .with(command: 'mas signout', user: 'testme')
        end
      end

      context 'an overridden use_rtun property' do
        let(:use_rtun) { true }
        cached(:chef_run) { converge }

        it 'ensures RtUN is installed' do
          expect(chef_run).to include_recipe('reattach-to-user-namespace')
        end

        it 'signs out of Mas using RtUN' do
          expect(chef_run).to run_execute('Sign out of Mas')
            .with(command: 'reattach-to-user-namespace mas signout')
        end
      end
    end

    context 'not signed in' do
      let(:signed_in_as?) { nil }
      cached(:chef_run) { converge }

      it 'does not sign out of Mas' do
        expect(chef_run).to_not run_execute('Sign out of Mas')
      end
    end
  end

  context 'the :upgrade_apps action' do
    let(:action) { :upgrade_apps }
    let(:installed?) { true }
    let(:installed_version?) { '1.1.0' }
    let(:installed_by?) { :direct }

    context 'upgrades available' do
      let(:upgradable_apps?) { true }

      context 'all default properties' do
        cached(:chef_run) { converge }

        it 'runs a Mas upgrade' do
          expect(chef_run).to run_execute('Upgrade all installed apps')
            .with(command: 'mas upgrade', user: getlogin)
        end
      end

      context 'an overridden use_rtun property' do
        let(:use_rtun) { true }
        cached(:chef_run) { converge }

        it 'ensures RtUN is installed' do
          expect(chef_run).to include_recipe('reattach-to-user-namespace')
        end

        it 'runs a Mas upgrade using RtUN' do
          expect(chef_run).to run_execute('Upgrade all installed apps')
            .with(command: 'reattach-to-user-namespace mas upgrade',
                  user: getlogin)
        end
      end
    end

    context 'no upgrades available' do
      let(:upgradable_apps?) { false }
      cached(:chef_run) { converge }

      it 'does not run a Mas upgrade' do
        expect(chef_run).to_not run_execute('Upgrade all installed apps')
      end
    end
  end
end
