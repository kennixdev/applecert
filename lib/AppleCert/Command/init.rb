
require 'thor'
require File.expand_path('../../Core/Provision/provisioning',__FILE__)
module AppleCert
  class Command
    class Init < Thor
      desc "prov [command]", "for manager provisioning, can be -d, -f. -de"
      option :d, :desc => "Delete file by UUID"
      option :f, :desc => "Show info for UUID"
      option :de, :desc => "Delete Expired"
      def prov()
        man = AppleCert::Provisioning.new()
        if !options[:f].nil?
          man.showInfo(options[:f])
        elsif !options[:d].nil?
          man.removefile(options[:d])
        elsif !options[:de].nil?
          man.removeExpired
        else
          man.list
        end
      end
    end
  end
end
