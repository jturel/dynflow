#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'example_helper'

class MyEvent
  def initialize(value)
    @value = value
  end

  def run(current_value)
    new_value = current_value + @value
    # STDOUT.puts "Computed new value of #{new_value}"
    new_value
  end
end

def server_world
  ExampleHelper.create_world do |config|
    config.persistence_adapter = persistence_adapter
    config.connector           = connector
  end
end

def client_world
  ExampleHelper.create_world do |config|
    config.persistence_adapter = persistence_adapter
    config.connector           = connector
  end
end

def db_path
  File.expand_path('agent_remote_executor_db.sqlite', __dir__)
end

def persistence_conn_string
  ENV['DB_CONN_STRING'] || "sqlite://#{db_path}"
end

def persistence_adapter
  Dynflow::PersistenceAdapters::Sequel.new persistence_conn_string
end

def connector
  proc { |world| Dynflow::Connectors::Database.new(world) }
end

command = ARGV.first || 'server'

if $PROGRAM_NAME == __FILE__
  case command
  when 'server'
    puts <<~MSG
      The server is starting…. You can send the work to it by running:

         #{$PROGRAM_NAME} client

    MSG

    world = server_world
    world.register_agent('example', value: 0)
    world.agent_event('example', MyEvent, [1])
    ExampleHelper.run_web_console(world)

    puts "Final value: #{world.find_agent('example')[:instance].value}"
  when 'client'
    world = client_world
    100.times do |i|
      world.agent_event('example', MyEvent, [i])
      puts "Sent MyEvent with value #{i} to the server"
    end
  else
    puts "Unknown command #{command}"
    exit 1
  end
end
