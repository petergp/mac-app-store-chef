# Encoding: UTF-8
#
# Cookbook Name:: mac-app-store
# Library:: helpers
#
# Copyright 2015 Jonathan Hartman
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/exceptions'

module MacAppStoreCookbook
  # A set of helper methods for interacting with the Mac App Store
  #
  # @author Jonathan Hartman <j@p4nt5.com>
  module Helpers
    #
    # Perform the installation of an App Store app
    #
    # @param [String] app_name
    # @param [Fixnum] timeout
    #
    # @raise [MacAppStoreCookbook::Exceptions::Timeout]
    #
    def self.install!(app_name, timeout)
      return nil if installed?(app_name)
      press(install_button(app_name))
      wait_for_install(app_name, timeout)
    end

    #
    # Wait up to the resource's timeout attribute for the app to download and
    # install
    #
    # @param [String] app_name
    # @param [Fixnum] timeout
    #
    # @return [TrueClass]
    #
    # @raise [MacAppStoreCookbook::Exceptions::Timeout]
    #
    #
    def self.wait_for_install(app_name, timeout)
      (0..timeout).each do
        # Button might be 'Installed' or 'Open' depending on OS X version
        term = /^(Installed,|Open,)/
        return true if app_page(app_name).main_window.search(:button,
                                                             description: term)
        sleep 1
      end
      fail(Exceptions::Timeout, "'#{app_name}' installation")
    end

    #
    # Find the latest version of a package available, via the "Information"
    # sidebar in the app's store page
    #
    # @param [String] app_name
    # @return [String]
    #
    def self.latest_version(app_name)
      app_page(app_name).main_window.static_text(value: 'Version: ').parent
        .static_text(value: /^[0-9]/).value
    end

    #
    # Find the install button in the app row
    #
    # @param [String] app_name
    # @return [AX::Button]
    #
    def self.install_button(app_name)
      app_page(app_name).main_window.web_area.group.group.button
    end

    #
    # Follow the app link in the Purchases list to navigate to the app's
    # main page, and return the Application instance whose state was just
    # altered
    #
    # @param [String] app_name
    # @return [AX::Application]
    #
    def self.app_page(app_name)
      purchased?(app_name) || fail(Chef::Exceptions::Application,
                                   "App '#{app_name}' has not been purchased")
      press(row(app_name).link)
      unless wait_for(:web_area,
                      ancestor: app_store.main_window,
                      description: app_name)
        fail(Exceptions::Timeout, "'#{app_name}' app page")
      end
      app_store
    end

    #
    # Check whether an app is purchased or not
    #
    # @param [String] app_name
    # @return [TrueClass, FalseClass]
    #
    def self.purchased?(app_name)
      !row(app_name).nil?
    end

    #
    # Find the row for the app in question in the App Store window
    #
    # @param [String] app_name
    # @return [AX::Row, NilClass]
    #
    def self.row(app_name)
      purchases.main_window.search(:row, link: { title: app_name })
    end

    #
    # Set focus to the App Store, navigate to the Purchases list, and return
    # the Application object whose state was just altered
    #
    # @return [AX::Application]
    # @raise [MacAppStoreCookbook::Exceptions::Timeout]
    # @raise [Chef::Exceptions::ConfigurationError]
    #
    def self.purchases
      unless signed_in?
        fail(Chef::Exceptions::ConfigurationError,
             'User must be signed into App Store to install apps')
      end
      select_menu_item(app_store, 'Store', 'Purchases')
      unless wait_for(:group, ancestor: app_store, id: 'purchased')
        fail(Exceptions::Timeout, 'Purchases page')
      end
      app_store
    end

    #
    # Sign out of the App Store if a user is currently signed in
    #
    def self.sign_out!
      return unless signed_in?
      select_menu_item(app_store, 'Store', 'Sign Out')
    end

    #
    # Go to the Sign In menu and sign in as a user.
    # Will return immediately if any user is signed in, whether or not it's
    # the same user as provided to this function.
    #
    # @param [String] username
    # @param [String] password
    #
    def self.sign_in!(username, password)
      return if signed_in? && current_user? == username
      sign_out! if signed_in?
      sign_in_menu
      set(username_field, username)
      set(password_field, password)
      press(sign_in_button)
      wait_for_sign_in
    end

    #
    # Wait for the 'Store' -> 'Sign Out' menu to load (for after signing in)
    #
    # @raise [MacAppStoreCookbook::Exceptions::Timeout]
    #
    def self.wait_for_sign_in
      unless wait_for(:menu_item,
                      ancestor: app_store.menu_bar_item(title: 'Store'),
                      title: 'Sign Out')
        fail(Exceptions::Timeout, 'sign in')
      end
    end

    #
    # Find and return the 'Sign In' button from the popup menu.
    # This requires that the sign in menu has already been selected.
    #
    # @return [AX::Button]
    #
    def self.sign_in_button
      sign_in_menu.main_window.sheet.button(title: 'Sign In')
    end

    #
    # Find and return the 'Apple ID' text field from the sign in popup.
    # This requires that the sign in menu has already been selected.
    #
    # @return[AX::TextField]
    #
    def self.username_field
      sign_in_menu.main_window.sheet.text_field(
        title_ui_element: sign_in_menu.main_window.sheet.static_text(
          value: 'Apple ID '
        )
      )
    end

    #
    # Find and return the 'Password' text field from the sign in popup.
    # This requires that the sign in menu has already been selected.
    #
    # @return [AX::SecureTextField]
    #
    def self.password_field
      sign_in_menu.main_window.sheet.secure_text_field(
        title_ui_element: sign_in_menu.main_window.sheet.static_text(
          value: 'Password'
        )
      )
    end

    #
    # If not already displaying the 'Sign In' popup menu, select 'Store' ->
    # 'Sign In...' from the menu bar and return the application instance.
    #
    # @return [AX::Application]
    #
    def self.sign_in_menu
      unless app_store.main_window.search(:button, title: 'Sign In')
        select_menu_item(app_store, 'Store', 'Sign In…')
        unless wait_for(:button,
                        ancestor: app_store.main_window,
                        title: 'Sign In')
          fail(Exceptions::Timeout, 'Sign In window')
        end
      end
      app_store
    end

    #
    # Find and return the user currently signed in, or nil if nobody is signed
    # in
    #
    # @return [NilClass, String]
    #
    def self.current_user?
      return nil unless signed_in?
      app_store.menu_bar_item(title: 'Store')
        .menu_item(title: /^View My Account /)
        .title[/^View My Account \((.*)\)/, 1]
    end

    #
    # Check whether a user is currently signed into the App Store or not
    #
    # @return [TrueClass, FalseClass]
    #
    def self.signed_in?
      !app_store.menu_bar_item(title: 'Store').search(:menu_item,
                                                      title: 'Sign Out').nil?
    end

    #
    # Quit the App Store app
    #
    def self.quit!
      app_store.terminate if running?
    end

    #
    # Find the App Store application running or launch it
    #
    # @return [AX::Application]
    # @raise [MacAppStoreCookbook::Exceptions::Timeout]
    #
    def self.app_store
      require 'ax_elements'
      app_store = AX::Application.new('com.apple.appstore')
      unless wait_for(:menu_item, ancestor: app_store, title: 'Purchases')
        fail(Exceptions::Timeout, 'App Store')
      end
      app_store
    end

    #
    # Return whether the App Store app is running or not
    #
    # @return [TrueClass, FalseClass]
    #
    def self.running?
      require 'ax_elements'
      !NSRunningApplication.runningApplicationsWithBundleIdentifier(
        'com.apple.appstore'
      ).empty?
    end
  end

  class Exceptions
    # A custom exception class for App Store task timeouts
    #
    # @author Jonathan Hartman <j@p4nt5.com>
    class Timeout < StandardError
      def initialize(task)
        super("Timed out waiting for #{task} to load")
      end
    end
  end
end
