require 'rubygems'
require 'cinch'
require 'net/http'

module Plugins
  class Say
    include Cinch::Plugin

    def initialize(*args)
      super
      voicersskey = config[:voicerss_key]
      if RUBY_PLATFORM =~ /linux/
        @cmd_es = "mpg123 -q 'http://api.voicerss.org/?key=#{voicersskey}&hl=es-es&src="
        @cmd_en = "mpg123 -q 'http://api.voicerss.org/?key=#{voicersskey}&hl=en-us&src="
        @cmd_de = "mpg123 -q 'http://api.voicerss.org/?key=#{voicersskey}&hl=de-de&src="
      elsif RUBY_PLATFORM =~ /^win/
        raise Cinch::Exceptions::UnsupportedFeature.new "This plugin is only compatible with linux or mac"
      else
        @cmd_en = "say -v Vicki '"
        @cmd_es = "say -v Monica '"
      end
      # Initialize bingo
      @numbers = []
      @chosen = []
      @bingo_master = config[:nick]
    end

    match "cuenta un chiste", method: :joke, :use_prefix => false
    match /dimelo\s*(.*)/, method: :say, :use_prefix => false
    match /say\s*(.*)/, method: :english, :use_prefix => false
    match /aleman\s*(.*)/, method: :german, :use_prefix => false
    match /^abibingo$/, method: :bingo_start, :use_prefix => false
    match /^linea$/, method: :bingo_line, :use_prefix => false
    match /^bingo$/, method: :bingo_bingo, :use_prefix => false
    match /^cantamelo$/, method: :bingo_next, :use_prefix => false
    match /^anumeros$/, method: :bingo_chosen, :use_prefix => false

    def say(m, text)
      cmd = "#{@cmd_es}#{text}'"
      %x[ #{cmd} ] 
    end

    def english(m, text)
      cmd = "#{@cmd_en}#{text}'"
      %x[ #{cmd} ]
    end

    def german(m, text)
      cmd = "#{@cmd_de}#{text}'"
      %x[ #{cmd} ]
    end

    def joke(m)
      joke = ''
      i = 4
      while joke.empty? and i > 0
        response = Nokogiri::HTML(RestClient.get URI.encode("http://www.chistescortos.eu/random"))
        response.css('a[class=oldlink]').each do |j|
          joke = j.text.gsub(/\r?\n/, ',,').gsub(/-/, ',,') if j.text.length < 140
        end
        i = i - 1
      end
      return if joke.empty? and i == 0
      cmd = "#{@cmd_es}#{joke}'"
      %x[ #{cmd} ] 
    end

    def bingo_start(m)
      @numbers =* (1..90)
      @bingo_master = m.user.nick
      @chosen = []
      cmd = "#{@cmd_es}Vamos chavalotes, que empieda el Abi Bingo!'"
      %x[ #{cmd} ]
    end

    def bingo_line(m)
      cmd = "#{@cmd_es}#{m.user.nick} canta linea...'"
      %x[ #{cmd} ]
    end

    def bingo_bingo(m)
      cmd = "#{@cmd_es}#{m.user.nick} canta bingo... Bukkake!'"
      %x[ #{cmd} ]
    end

    def bingo_chosen(m)
      if m.user.nick == @bingo_master
        m.reply "Estos son los que ya han salido, tontaco!\n#{@chosen.sort().to_s}"
      end
    end

    def bingo_next(m)
      if m.user.nick == @bingo_master
        unless @numbers.empty?
          num = @numbers.delete_at(Random.rand(@numbers.size()))
          @chosen << num
          rhyme = _getRhyme(num)

          txt = "El #{num}!"
          txt += " #{num / 10}, #{num % 10}." if num > 9

          cmd = "#{@cmd_es}#{txt} #{rhyme}'"
          m.reply "El #{num}. #{rhyme}"
        else
          cmd = "#{@cmd_es}Bingo terminado!'"
        end
        %x[ #{cmd} ]
      end
    end

    def _getRhyme(number)
      rhyme = ''
      begin
        http = Net::HTTP.new('rimamelo.herokuapp.com', 80)
        request = Net::HTTP::Get.new("/web/api?model.rhyme=#{number}")
        response = http.request(request)
        if response.code == '200'
          rhyme = response.body()
          rhyme = "#{rhyme.force_encoding('iso-8859-1')}"
        end
      rescue
        # Ignore the rhyme if it cannot be retrieved
      end
      rhyme
    end
  end
end

