require 'nokogiri'
require 'em-http'
require 'open-uri'

# This file is reloaded every time, work with it.
class Processor
  module Socket
    def onopen
      puts "New Client."
      sockets << req_socket
    end
    
    def onclose
      puts '  x Client Disconnected.'
      sockets.delete req_socket
    end
    
    def onmessage(mes)
      puts "  Message: #{mes}"
      case mes
        when 'start' then start_crawling
        when 'stop' then stop_crawling
        when 'cache' then crawl_cache
      else
        send_all mes
      end
    end
    
    # Send the message to everyone
    def send_all(mes)
      sockets.each { |s| s.send mes }
    end
  end
  
  module Crawler
    def get_image(node)
      url = node.css('a.hoverinfo_trigger').attr('href').to_s
      puts "Opening #{url}"
      doc = Nokogiri::HTML open(URI.encode(url))
      img = doc.css('#content img').first
      File.open(cache_file, 'a') {|f| f.write(img.to_html + "\n") }
      send_all img.to_html
    end
    
    def start_crawling(config = {:page => false})
      config[:url] ||= base_url
      if config[:page]
        send_all 'Crawling next page.'
      else
        send_all 'Starting Crawl, cleaning cache.'
        File.open(cache_file, 'w'){|f| f.write("") }
      end
      EventMachine.run do
        EM::HttpRequest.new(config[:url]).get.callback { |http|
          EventMachine.defer(proc {
            doc   = Nokogiri::HTML(http.response)
            nodes = doc.css('#content tr')
            nodes.each_with_index do |node, index|
              get_image(node)
              if nodes.last == node
                puts 'Last Node reached'
                # Next Link
                puts doc.css('h2 a').last.attr('href')
                start_crawling :page => true, :url => base_url + doc.css('h2 a').last.attr('href').to_s
              end
            end
          })
        }
      end
    end

    def crawl_cache
      send_all "Accessing Cache."
        EventMachine.defer(proc {
          File.readlines(cache_file).each do |line|
            puts "Sending address via Cache..."
            send_all line
            sleep(0.5)
          end
        })
    end
  end

  include Processor::Socket
  include Processor::Crawler
end
