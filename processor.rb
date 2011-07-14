require 'rubygems'
require 'eventmachine'
require 'em-websocket'
require './processor/socket.rb'

# Processor == App Name.
class Processor
  attr_accessor :sockets, :port, :req_socket, :mode, :cache_file, :base_url
  def initialize(config)
    puts "Starting server on port: #{config[:port]}"
    @port       = config[:port]
    @mode       = config[:mode]
    @cache_file = 'cache.txt'
    @base_url   = 'http://myanimelist.net/topanime.php'
    @sockets    = []
    run_event_machine
  end
  
  def self.run!(config = {:port => 8080, :mode => :development})
    self.new(config)
  end
  
  # Reload the file very single time.
  def prepare(ws)
    return unless mode == :development
    @req_socket = ws
    load './processor/socket.rb'
  end
  
  # Run the Event machine and binds.
  def run_event_machine
    EventMachine.run do
      # ws = Current Web Socket.
      EventMachine::WebSocket.start(:host => '0.0.0.0', :port => port) do |ws|
        
        ws.onopen do
          prepare(ws)
          onopen
        end

        ws.onmessage do |mes|
          prepare(ws)
          onmessage mes
        end
           
        ws.onclose do
          prepare(ws)
          onclose
        end
      end
    end
    
  end
end

Processor.run!
