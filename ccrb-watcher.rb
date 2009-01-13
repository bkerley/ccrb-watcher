#!/usr/bin/env ruby
require 'rss/2.0'
require 'open-uri'

class Project
  attr_accessor :status, :id, :date
  def initialize(rss_item)
    self.date = rss_item.date
    words = rss_item.title.split
    self.status = words[-1]
    self.id = words[-2]
  end
  
  def opinion
    return "bad" if successful?
    return "meh" if stale?
    return "ok"
  end
  
  def successful?
    status == 'success'
  end
  
  def stale?
    date < 1.week.ago
  end
  
  def to_growlnotify
    "growlnotify -n cc.rb --image cc-icon_#{opinion}.png -m \"#{id} at #{date} is #{opinion}\" \"#{opinion} for you!\""
  end
end

class Watcher
  attr_accessor :uri
  def initialize(uri)
    self.uri = uri
  end
  
  def last_project
    Project.new(rss.items[0])
  end
  
  private
  def rss
    @rss ||= fetch
  end
  
  def fetch
    content = nil
    open(uri) do |s|
      content = s.read
    end
    
    RSS::Parser.parse(content, false)
  end
end
