require 'cinch'
require 'yaml'
require 'vlcrc'
require 'ruby-youtube-dl'
require 'uri'
require 'cgi'
require 'net/http'

require File.dirname(__FILE__) + '/../util/elfari_util'
require File.dirname(__FILE__) + '/../util/google_youtube'


module Plugins

  class VLC
    include Cinch::Plugin

    match /^shh/, method: :pause, :use_prefix => false
    match /^volumen\s*(\d*)/, method: :volume, :use_prefix => false
    match /^quita esta mierda/, method: :next_song, :use_prefix => false
    match /^apunta\s+(.+)/, method: :add_song_db, :use_prefix => false
    match /^apuntaapm\s+(.+)/, method: :add_song_apm, :use_prefix => false
    match /^vino/, method: :wine, :use_prefix => false
    match /^que\stiene/, method: :list, :use_prefix => false
    match /^list\s?apm/, method: :list_apm, :use_prefix => false
    match /^ponme\s*er\s*(.*)/, method: :play_known, :use_prefix => false
    match /^saluda\s*a?\s*(.*)/, method: :greet, :use_prefix => false
    match /^apm\s*(.*)/, method: :play_apm, :use_prefix => false
    match /^aluego(.*)/, method: :aluego, :use_prefix => false
    match /^meh (.*)/, method: :cached_aluego, :use_prefix => false
    match /^meh\?/, method: :meh_status, :use_prefix => false
    match /^trame\s*(.*)/, method: :trame, :use_prefix => false
    match /^ponmelo.*/, method: :deprecated, :use_prefix => false
    match /^mele.*/, method: :melee, :use_prefix => false
    match /^a\s*cuanto/, method: :get_volume, :use_prefix => false
    match /^volumen\+\+$/, method: :increase_volume, :use_prefix => false
    match /^volume--$/, method: :decrease_volume, :use_prefix => false
    match /^dale$/, method: :play, :use_prefix => false
    match /^ponme argo\s*(.*)/, method: :play_known_random, :use_prefix => false
    match /^que es esta mierda(.*)/, method: :current, :use_prefix => false
    match /^afuego\s+(.*)/, method: :fire, :use_prefix => false
    match /^playlist\s+(.*)/, method: :add_playlist, :use_prefix => false

    match /^puerta!$/, method: :puerta, :use_prefix => false
    match /^palante!$/, method: :palante, :use_prefix => false
    match /^zuul\s*(.*)/, method: :zuul_say, :use_prefix => false

    def initialize(*args)
      super
      @youtube = GoogleYoutube.new(config[:youtube_key]) if @youtube.nil?

      @db_song = config[:database]
      @db_apm = config[:apm]
      @apm_folder = config[:apm_folder]
      @greetings = config[:greetings]
      @zuul = config[:zuul][:api]
      @camera = config[:zuul][:camera]

      @mehs = Hash.new

      @streaming = config[:streaming] || false
      config[:host] ||= 'localhost'
      config[:port] ||= 1234
      config[:args] ||= '--no-video -I lua --lua-intf cli --ignore-config'
      config[:streaming_port] ||= 8888
      if @streaming
        config[:args] << " --sout-keep --sout '#duplicate{dst=display,dst=standard{access=http,mux=asf,dst=#{config[:host]}:#{config[:streaming_port]}}}'"
      end
      if config[:bin].nil?
        @vlc = VLCRC::VLC.new config[:host], config[:port], config[:args]
      else
        @vlc = VLCRC::VLC.new config[:host], config[:port], config[:bin], config[:args]
      end
      @vlc.launch

      # Connect to it (have to wait for it to launch though)
      until @vlc.connected?
        sleep 0.1
        @vlc.connect
      end

      @vlc.clear_playlist
      @vlc.add_stream 'http://www.youtube.com/watch?v=7nQ2oiVqKHw'
      @vlc.playing = true

      @vol = 200
    end

    listen_to :join
    def listen(m)
      _greet(m.user.nick)
    end

    def greet(m, query)
        _greet(query)
    end

    def _greet(who)
      greets = @greetings[who]
      if greets.is_a? Array
        greeting = greets.sample
      else
        greeting = greets
      end
      if greeting.nil?
          greeting = @greetings["default"]
      end
      if @vlc.playing
        @vlc.add_stream greeting
      else
        @vlc.stream = greeting
      end
    end

    listen_to :disconnect, method: :inet_down
    def inet_down(m)
      puts @internet_song
      @vlc.stream= @internet_song
      @vlc.playing= true
    end

    def pause(m)
      @vlc.pause
      m.reply "pausa"
    end

    def volume(m, query)
      if @streaming
        n = ([query.to_i, 512].min / 512.0) * 100
        `amixer -D pulse sset Master #{n}%`
        @vol = n
      else
        @vlc.volume = query.to_i
        @vol = query.to_i
      end
    end

    def increase_volume(m)
      vol = @vlc.volume
      if vol.nil? or vol == ""
        vol = 1
      end
      vol = vol.to_i + 10
      volume(m, vol)
    end

    def decrease_volume(m)
      vol = @vlc.volume
      if vol.nil? or vol == ""
        vol = 1
      end
      vol = vol.to_i - 10
      @vlc.volume(m, vol)
    end

    def next_song(m)
      @vlc.next
    end

    def add_song_db(m, query)
      add_song_file(m, query, @db_song)
    end

    def add_song_apm(m, query)
      if query.match(/^http/)
        `youtube-dl --verbose -o '#{@apm_folder}/%(title)s-%(id)s.%(ext)s' #{query}`.strip
        m.reply "Ya es nuestro \"#{YoutubeDL::Downloader.video_title(query)}\"!"
      else
        m.reply "eso no es una uri"
      end
    end

    def add_song_file(m, query, filename)
      if query.match(/^http/)
        title = YoutubeDL::Downloader.video_title(query)
        if title.nil?
          m.reply "No me suena"
        else
          File.open(filename, 'a') { |n| n.puts "#{query} - #{title}\n"}
          m.reply "Apuntado #{title} en la base de datos"
        end
      else
        m.reply "eso no es una uri"
      end
    end

    def wine(m)
      @vlc.stream= 'http://www.youtube.com/watch?v=-nQgsEbU9C4'
      m.reply "Viva el vino!!!"
    end

    def play_known(m, query)
      play_from_file(m, query, @db_song, false)
    end

    def play_apm(m, query)
      song = Dir.glob("#{@apm_folder}/*#{query}*", File::FNM_CASEFOLD).sample
      if song
        @vlc.clear_playlist
        @vlc.stream=song
        m.reply "Toma, chato #{song.split('/').last}!"
      else
        m.reply "No tengo #{query}"
      end
    end

    def play_from_file(m, query, filename, force)
      db = File.readlines(filename)
      found = false
      db.each do |line|
        if line =~ /#{query}/i
          play = line.split(/ /)[0]
          #cached = cache_file(m, play)
          if @vlc.playing and !force
            @vlc.add_stream play
          else
            @vlc.clear_playlist
            @vlc.stream = play
          end
          title = YoutubeDL::Downloader.video_title(play)
          m.reply "Tomalo, chato: #{title}"
          found = true
          break
        end
      end
      m.reply "No tengo er: #{query}" if !found

      @vlc.playing=true if found
    end

    def list(m)
      list_file(m, @db_song)
    end

    def list_apm(m)
      m.reply "Toma APM"
      Dir["#{@apm_folder}/*"].each do |song|
        m.reply song.split('/').last
      end
    end

    def list_file(m, filename)
      db = File.readlines(filename)
      m.reply "Tengo esto piltrafa:\n"
      db.each do |line|
        m.reply line
      end
    end

    def trame(m, query)
      @vlc.playing=false
      @vlc.clear_playlist
      execute_aluego(m, query, false)
    end
    
    def aluego(m, query)
      execute_aluego(m, query, false)
    end

    def cached_aluego(m, query)
      execute_aluego(m, query, true)
    end

    def execute_aluego(m, query, cached)
      duration = "UNKNOWN LENGTH"
      if /^http/.match(query)
        uri = query
        title = YoutubeDL::Downloader.video_title(uri)
        video_id = CGI.parse(URI.parse(uri).query)['v'][0]
        details = @youtube.get_content_details(video_id)
        duration = @youtube.parse_duration(details.duration)
      else
        uri, title, duration = @youtube.get_video(query)
      end
      if uri.nil?
        m.reply "no veo el #{query}"
      else
        #play_url = `youtube-dl -g #{uri}`.strip
        play_uri = cached ? cache_file(m, uri) : uri
        
        if @vlc.playing
          @vlc.add_stream play_uri
        else
          @vlc.clear_playlist
          @vlc.stream = play_uri
        end
        @vlc.playing=true
        m.reply "encolado " + title + " #{uri} (#{duration})"
      end
    end

    def cache_file(m, uri)
      vid = URI.parse(uri).query.split('=')[1]
      cached_file = "/var/cache/elfari/#{vid}"
      unless File.exists?(cached_file)
        m.reply "Descargando #{uri} ..."
        download = "youtube-dl --newline -f best -o '#{cached_file}' #{uri}"
        IO.popen(download) do |io|
          while (line = io.gets) do
            @mehs[vid] = line
          end
        end
        # youtube-dl always appends the extension. Just remove it
        `mv #{cached_file}.* #{cached_file}`
        @mehs.delete(vid)
      end
      cached_file
    end

    def meh_status(m)
      if @mehs.empty?
        m.reply "No estoy descargando nada, payo!"
      else
        m.reply "Aqui tienes como va la cosa:"
        @mehs.each do |id,status|
          m.reply "#{id} -> #{status}"
        end
      end
    end

    def add_playlist(m, query)
      if /^http/.match(query)
        query = CGI.parse(URI.parse(query).query)['list'][0]
      end
      uri, title, items = @youtube.get_playlist(query)
      if uri.nil?
        m.reply "no veo el #{query}"
      else
        m.reply "Encolando #{items} videos de #{title}"
        videos = `youtube-dl -q -g --skip-download '#{uri}'`
        videos.split.each do |video_url|
          if @vlc.playing
            @vlc.add_stream video_url
          else
            @vlc.clear_playlist
            @vlc.stream = video_url
          end
          @vlc.playing = true
        end
        m.reply "Done!"
      end
    end

    def melee(m)
      execute_aluego(m, 'bdsSCF6QpCI', false)
    end

    def get_volume(m)
      the_vol = @vol
      if @streaming
        vol = @vlc.volume
        the_vol = vol.to_i if !vol.nil? and vol != ""
      end
      m.reply "la cosa suena a #{the_vol}"
    end

    def deprecated(m)
      m.reply "esta pasado de moda, mejor encola la cancion con aluego"
    end

    def play_known_random(m)
      db = File.readlines(@db_song)
      return unless db
      song = db.at(Random.rand(db.length))
      play = song.split(/ /)[0]
      #cached = cache_file(m, play)
      if @vlc.playing
        @vlc.add_stream play
      else
        @vlc.clear_playlist
        @vlc.stream = play
      end
      title =YoutubeDL::Downloader.video_title(play)
      m.reply "Tomalo, chato: #{title}"
      @vlc.playing=true
    end

    def play()
      @vlc.playing=true
    end

    def current(m, query)
      media = @vlc.media || "Nada, pon tu mierda!"
      m.reply media
    end

    def fire(m, query)
      m.reply "#{query.strip}"
      q = query.strip
      if q.match(/^http/)
        if @vlc.playing
          @vlc.add_stream q
        else
          @vlc.clear_playlist
          @vlc.stream=q
        end
        @vlc.playing=true
        m.reply "Para ti #{q}"
      else
        m.reply "La uri debe empezar con http://. #{q}"
      end
    end

    def puerta(m)
      m.reply "Abriendo la puerta..."
      if @vlc.playing
        @vlc.add_stream @camera
      else
        @vlc.clear_playlist
        @vlc.stream=@camera
      end
      @vlc.playing=true
      Net::HTTP.get(URI.parse("#{@zuul}/puerta"))
    end

    def palante()
      Net::HTTP.get(URI.parse("#{@zuul}/palante"))
    end
    
    def zuul_say(m, query)
      Net::HTTP.post_form(URI.parse("#{@zuul}/dimelo"), {'text' => query.strip})
    end
  end
end
