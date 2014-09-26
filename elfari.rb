# Needs rubygems and cinch:
#
# sudo apt-get install rubygems
# gem install cinch
# gem install rest-client
#

$: << File.dirname(__FILE__) + '/lib'
require 'rubygems'
require 'bundler/setup'
require 'cinch'
require 'yaml'
require 'rest-client'
require 'alchemist'
require 'uri'
require 'em-synchrony'
require 'plugins/say'
#require 'plugins/mpd'
require 'plugins/vlc'
#require 'plugins/player'
require 'plugins/twitter'
require 'tweetstream'
require 'typhoeus/adapters/faraday'
require 'rest_client'
require 'nokogiri'
require 'uri'
##$SAFE = 4
require 'util/elfari_util'

module ElFari

  class Config
    def self.config
      YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/config/config.yml')
    end
  end
end

if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

config = ElFari::Config.config

greetings = {
    "destevez" => "http://www.youtube.com/watch?v=onMJBIXjW4Y",
    "scastro" => "http://www.youtube.com/watch?v=wqxvKdKX6Fk",
    "default" => "http://www.youtube.com/watch?v=1CiqkIyw-mA"
}

bot = Cinch::Bot.new do
  configure do |c|
    c.server = config[:server]
    c.channels = config[:channels]
    c.nick = config[:nick]
    c.plugins.plugins = [
      #Plugins::Mpd,Plugins::Player
     Plugins::VLC,
      Plugins::Tuiter,
      Plugins::Say]

    c.plugins.options= {
#      Plugins::Player => { :mplayer_bin => config[:mplayer], :database => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:database]}" },
      Plugins::VLC => { :bin => config[:vlc][:bin],
                        :port => config[:vlc][:port],
                        :args => config[:vlc][:args],
                        :host => config[:vlc][:host],
                        :database => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:database]}",
                        :apm => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:apm]}",
                        :apm_folder => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:apm_folder]}",
                        :internet_song => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:internet_song]}",
                        :streaming_port => config[:vlc][:streaming_port],
                        :streaming => config[:vlc][:streaming],
                        :greetings => greetings},
	#Plugins::Mpd => {:database => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:database]}"},
         Plugins::Tuiter => {:lang => config[:twitter][:lang]}
    }
    c.timeouts.connect = config[:timeout]
    c.verbose = true
  end
end

EM.defer {
  bot.start
}

TweetStream.configure do |c|
  c.consumer_key = ENV['GENARDO_TWITTER_CONSUMER_KEY']
  c.consumer_secret = ENV['GENARDO_TWITTER_CONSUMER_SECRET']
  c.oauth_token = ENV['GENARDO_TWITTER_OAUTH_TOKEN']
  c.oauth_token_secret = ENV['GENARDO_TWITTER_OAUTH_TOKEN_SECRET']
  c.auth_method = :oauth
end

until @channel do
  bot.channels.each do |c|
    if c.name == config[:twitter][:channel]
      @channel = c
    end
  end
  sleep 1
end

screen_names = config[:twitter][:screen_names] || ""
TweetStream::Client.new.on_error do |error|
  @channel.msg "No pueeeeedo: #{error}"
  end.on_direct_message do |msg|
    @channel.msg "Mensaje de #{msg.sender_screen_nametrack} para #{msg.recipient_screen_name}: #{msg.text}"
  end.track(screen_names.split(',')) do |status|
  @channel.msg "Mencionan en twitter @#{status.user.screen_name}: #{status.text}"
end

