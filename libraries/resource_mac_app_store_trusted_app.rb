# Encoding: UTF-8
#
# Cookbook Name:: mac-app-store
# Library:: resource_mac_app_store_trusted_app
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

require 'chef/resource/lwrp_base'

class Chef
  class Resource
    # A Chef resource for modifying OS X's Accessibility settings to trust
    # an app with control
    #
    # @author Jonathan Hartman <j@p4nt5.com>
    class MacAppStoreTrustedApp < Resource::LWRPBase
      self.resource_name = :mac_app_store_trusted_app
      actions :create
      default_action :create

      #
      # Attribute for the app's created status
      #
      attribute :created,
                kind_of: [NilClass, TrueClass, FalseClass],
                default: nil
      alias_method :created?, :created

      #
      # Offer the option of creating the trust rule at compile time
      #
      attribute :compile_time,
                kind_of: [NilClass, TrueClass, FalseClass],
                default: false

      #
      # After resource creation, run actions during the compile phase if
      # compile_time is set
      #
      def after_created
        compile_time && Array(action).each { |a| run_action(a) }
      end
    end
  end
end