require 'cinch'
require 'yaml'

require 'vlcrc'
require 'ruby-youtube-dl'
require 'youtube_it'

require File.dirname(__FILE__) + '/../util/elfari_util'


module Plugins

  class VLC
    include Cinch::Plugin

    match /shh/, method: :pause, :use_prefix => false
    match /volumen\s*(\d*)/, method: :volume, :use_prefix => false
    match /quita esta mierda/, method: :next_song, :use_prefix => false
    match /apunta\s+(.+)/, method: :add_song_db, :use_prefix => false
    match /apuntaapm\s+(.+)/, method: :add_song_apm, :use_prefix => false
    match /vino/, method: :wine, :use_prefix => false
    match /que\stiene/, method: :list, :use_prefix => false
    match /^list\s?apm/, method: :list_apm, :use_prefix => false
    match /ponme\s*er\s*(.*)/, method: :play_known, :use_prefix => false
    match /^apm\s*(.*)/, method: :play_apm, :use_prefix => false
    match /aluego(.*)/, method: :execute_aluego, :use_prefix => false
    match /trame\s*(.*)/, method: :trame, :use_prefix => false
    match /ponmelo.*/, method: :deprecated, :use_prefix => false
    match /melee time/, method: :melee, :use_prefix => false
    match /a cuanto/, method: :get_volume, :use_prefix => false
    match /^volumen\+\+$/, method: :increase_volume, :use_prefix => false
    match /^volume--$/, method: :decrease_volume, :use_prefix => false
    match /^dale$/, method: :play, :use_prefix => false
    match /^ponme argo\s*(.*)/, method: :play_known_random, :use_prefix => false
    match /que es esta mierda(.*)/, method: :current, :use_prefix => false
    match /afuego\s+(.*)/, method: :fire, :use_prefix => false

    def initialize(*args)
      super
      @youtube = YouTubeIt::Client.new if @youtube.nil?

      @db_song = config[:database]
      @db_apm = config[:apm]
      @apm_folder = config[:apm_folder]

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
      @vlc.add_stream   YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=7nQ2oiVqKHw')
      @vlc.add_stream   YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=1CiqkIyw-mA')
      @vlc.playing = true

    end

    listen_to :join
    def listen(m)
      if @vlc.playing
        if m.user.nick =~ /destevez/i
          @vlc.add_stream YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=onMJBIXjW4Y')
        else
          @vlc.add_stream YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=1CiqkIyw-mA')
        end
      else
        if m.user.nick =~ /destevez/i
          @vlc.stream= YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=onMJBIXjW4Y')
        else
          @vlc.stream= YoutubeDL::Downloader.url_flv('http://www.youtube.com/watch?v=1CiqkIyw-mA')
        end
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
      else
        @vlc.volume=query.to_i
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
          flv = YoutubeDL::Downloader.url_flv(play)
          if @vlc.playing and !force
            @vlc.add_stream flv
          else
            @vlc.clear_playlist
            @vlc.stream=flv
          end
          title =YoutubeDL::Downloader.video_title(play)
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
      execute_aluego(m, query)
    end

    def execute_aluego(m, query)
      length = "UNKNOWN LENGTH"
      if /http:\/\//.match(query)
        uri = query
      else
        video = @youtube.videos_by(:query => query, :max_results => 1).videos.at(0)
        uri = video.player_url unless video.nil?
      end
      if uri.nil?
        m.reply "no veo el #{query}"
      else
        flv = YoutubeDL::Downloader.url_flv(uri)
        if @vlc.playing
          @vlc.add_stream flv
        else
          @vlc.clear_playlist
          @vlc.stream= flv
        end
        @vlc.playing=true
        length = Time.at(video.duration).utc.strftime("%T") unless video.nil?
        m.reply "encolado " + YoutubeDL::Downloader.video_title(uri) + " #{uri} (#{length})"
      end
    end

    def melee(m)
      play_known(m, 'franzl')
    end

    def get_volume(m)
      vol = @vlc.volume
      if vol.nil? or vol == ""
        m.reply "Ahora no esta sonando nada!"
      else
        m.reply "el volume: #{vol.to_i}"
      end
    end

    def deprecated(m)
      m.reply "esta pasado de moda, mejor encola la cancion con aluego"
    end

    def play_known_random(m)
      db = File.readlines(@db_song)
      return unless db
      song = db.at(Random.rand(db.length))
      play = song.split(/ /)[0]
      flv = YoutubeDL::Downloader.url_flv(play)
      if @vlc.playing
        @vlc.add_stream flv
      else
        @vlc.clear_playlist
        @vlc.stream=flv
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
  end
end
