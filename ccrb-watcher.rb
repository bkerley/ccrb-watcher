#!/usr/bin/env ruby
require 'rubygems'
require 'rss/2.0'
require 'open-uri'
require 'active_support'

class Build
  attr_accessor :status, :id, :date
  def initialize(rss_item)
    self.date = rss_item.date
    words = rss_item.title.split
    self.status = words[-1]
    self.id = words[-2]
  end
  
  def opinion
    return "bad" if !successful?
    return "meh" if stale?
    return "ok"
  end
  
  def successful?
    status == 'success'
  end
  
  def stale?
    date < 1.week.ago
  end
  
  def growlnotify
    cmd = "growlnotify -n cc.rb --image cc-icon_#{opinion}.png -m - \"#{opinion} for you!\""
    message = "#{id} at #{date.localtime.strftime "%c"} is #{opinion}"
    IO.popen cmd, 'w' do |c|
      c.puts message
    end
  end
end

class Watcher
  attr_accessor :uri, :builds
  def initialize(uri)
    self.uri = uri
    self.builds = {}
  end
  
  def check_last_build
    b = Build.new(@rss.items[0])
    new_build b if !seen_build?(b)
  end
  
  def new_build(b)
    builds[b.id] = b
    b.growlnotify
  end
  
  def seen_build?(b)
    builds.include? b.id
  end
  
  def watch
    while true
      fetch
      check_last_build
      sleep 60*10
    end
  end
  
  def fetch
    content = nil
    open(uri) do |s|
      content = s.read
    end
    
    @rss = RSS::Parser.parse(content, false)
  end
end

begin
  if $0 == __FILE__
    url = ARGV[0]
    w = Watcher.new(url)
    w.watch
  end
rescue Exception => e
  $stderr.puts "barf!"
  $stderr.puts e.backtrace.join("\n")
  $stderr.puts e.inspect
  exit -1
end