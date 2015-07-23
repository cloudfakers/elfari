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
#require 'plugins/twitter'
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
    "nacx" => "http://www.youtube.com/watch?v=iLZitwSekBM",
    "destevez" => "http://www.youtube.com/watch?v=onMJBIXjW4Y",
    "scastro" => "http://www.youtube.com/watch?v=wqxvKdKX6Fk",
    "DanFaizer" => "http://www.youtube.com/watch?v=Gl_22W0GilI",
    "eruiz" => "http://www.youtube.com/watch?v=jvZVMMTFut0",
    "spena" => "http://www.youtube.com/watch?v=nPrYcD79Qm4",
    "lmonte" => "http://www.youtube.com/watch?v=0t7JowCZHQE",
    "chirauki" => "http://www.youtube.com/watch?v=0wXYx-cUGWg",
    "apuig" => "http://www.youtube.com/watch?v=ZeKop5CqIIU",
    "maryjane" => "http://www.youtube.com/watch?v=jFO9siTkJ_Y",
    "mjsmyth" => "http://www.youtube.com/watch?v=jFO9siTkJ_Y",
    "merixoni" => "http://www.youtube.com/watch?v=jFO9siTkJ_Y",
    "xthevenot" => "http://www.youtube.com/watch?v=ftbYFZkNTtw",
    "PelicanMan" => "http://www.youtube.com/watch?v=ftbYFZkNTtw",
    "mmorata" => "http://www.youtube.com/watch?v=UI16A1Datfo",
    "MarcMorata" => "http://www.youtube.com/watch?v=UI16A1Datfo",
    "dnieto" => "http://www.youtube.com/watch?v=XHOWiJus2m8",
    "xfernandez" => "http://www.youtube.com/watch?v=FlJJS6DRNS4",
    "wayko" => "http://www.youtube.com/watch?v=55OcHGlsV7Q",
    "becario" => "http://www.youtube.com/watch?v=55OcHGlsV7Q",
    "dd" => "http://www.youtube.com/watch?v=55OcHGlsV7Q",
    "chiconuevo" => "http://www.youtube.com/watch?v=jO4pjulBuL8",
    "antxon" => "http://www.youtube.com/watch?v=jO4pjulBuL8",
    "aprete" => "http://www.youtube.com/watch?v=JUXFXXnw8TM",
    "ggonzalez" => "http://www.youtube.com/watch?v=6_4eTvtQ3h4",
    "genardo" => "http://www.youtube.com/watch?v=6_4eTvtQ3h4",
    "nardo" => "http://www.youtube.com/watch?v=6_4eTvtQ3h4",
    "cmartinez" => "http://www.youtube.com/watch?v=Pigwo0fxvSs",
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
    #  Plugins::Tuiter,
      Plugins::Say]

    c.plugins.options= {
#      Plugins::Player => { :mplayer_bin => config[:mplayer], :database => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:database]}" },
      Plugins::Say => { :nick => config[:nick] },
      Plugins::VLC => { :bin => config[:vlc][:bin],
                        :port => config[:vlc][:port],
                        :args => config[:vlc][:args],
                        :host => config[:vlc][:host],
                        :youtube_key => config[:youtube][:key],
                        :database => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:database]}",
                        :apm => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:apm]}",
                        :apm_folder => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:apm_folder]}",
                        :internet_song => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:internet_song]}",
                        :streaming_port => config[:vlc][:streaming_port],
                        :streaming => config[:vlc][:streaming],
                        :greetings => greetings},
	#Plugins::Mpd => {:database => "#{File.expand_path(File.dirname(__FILE__))}/#{config[:database]}"},
        #Plugins::Tuiter => {:lang => config[:twitter][:lang]}
    }
    c.timeouts.connect = config[:timeout]
    c.verbose = true
  end
end

#EM.defer {
  bot.start
#}

=begin
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
=end
