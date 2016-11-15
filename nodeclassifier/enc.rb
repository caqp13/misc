#!/usr/bin/env ruby

require 'yaml'

class Host
  attr_reader :hostname, :puppet_server, :puppet_server_type, :site, :env, :label, :number

  def initialize(hostname)
    @hostname = hostname
    if /([[:alnum:]]{2})-([a-z])?([a-z]{3,4})([0-9]{2})/ =~ hostname    # Standard hostnames
      split_hostname = /([[:alnum:]]{2})-([a-z])?([a-z]{3,4})([0-9]{2})/.match(hostname).to_a
      @site               = split_hostname[1]
      @env                = split_hostname[2]
      @label              = split_hostname[3]
      @number             = split_hostname[4]
    elsif /^h[1-3][a-z]+/ =~ hostname                     # Workaround for puppet masters using incorrect hostname
      @puppet_server      = /^h[1-3][a-z]+/.match(@hostname)
      @puppet_server_type = /h[1-3]([a-z]*)/.match(@hostname)[1]
    else
      raise 'Invalid hostname'
    end

  end

end

class Classifier
  attr_accessor :config

  def initialize(config_file)
    load_config config_file
  end

  def load_config(config_file)
    @config = YAML.load_file(config_file)
  end

  def process_host(hostname)
    host = Host.new hostname

    if host.puppet_server
      role = @config['role_mappings'][host.puppet_server_type]
    else
      role = @config['role_mappings'][host.label]
      raise "No role configured for label '#{host.label}'" if role.nil?

      if role.is_a? Hash
        role = @config['role_mappings'][host.label][host.number]
        role = @config['role_mappings'][host.label]['default'] if role.nil?
        raise "No role configured for label '#{host.label}' and number '#{host.number}' and no default is set." if role.nil?
      end
    end

    response = {'classes' => "role::#{role}"}
    puts response.to_yaml
  end
end

path = File.dirname(__FILE__)

classifier = Classifier.new "#{path}/enc_config.yaml"
classifier.process_host ARGV[0]
