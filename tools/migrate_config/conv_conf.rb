#!/usr/bin/env ruby

require 'digest/md5'
require 'optparse'

class FileWriter
  def initialize(fn)
    if fn == $stdout then
      @f = fn
    else
      @f = open(fn, "w")
    end
  end

  def write_file(buff)
    buff.length.times do |i|
      @f.write(buff[i])
    end
  end

  def close_file
    unless $n_conf_fn == $stdout then
      unless @f.closed? then
        @f.close
      end
    end
  end
end

class FileReader
  def initialize(fn, flg)
    @f = open(fn, "r")
    @type = ''
    @row = 0
    @buff = Array.new()
    while l = @f.gets
      t = detect_type(l)
      unless t == nil then
        @type = t
      end
      if flg == true then
        unless /^#.*/ =~ l || l == "\n" then
          @buff.push(l)
        end
      else
        @buff.push(l)
      end
    end
  end

  def detect_type(l)
    if /^## LeoFS - Manager Configuration (MASTER).*/ =~ l then
      t = 'M0'
    elsif /^# LeoFS - Manager Configuration (SLAVE).*/ =~ l then
      t = 'M1'
    elsif /^# LeoFS - Storage Configuration.*/ =~ l then
      t = 'S'
    elsif /^# LeoFS - Gateway Configuration.*/ =~ l then
      t = 'G'
    else
      t = nil
    end
  end

  def get_type
    @type
  end

  def get_line
    if @row < @buff.length then
      @row += 1
      @buff[@row - 1]
    else
      nil
    end
  end

  def get_file
    @buff
  end

  def replace_value(l)
    arr = l.split(" ")
    @buff.length.times do |i|
      m = @buff[i].dup
      m.gsub!("#", "")
      m.lstrip!
      if /^(.*)\s=\s.*$/ =~ m
        if arr[0] == $1 then
          unless /^## obj_containers\.path = \[\/var\/leofs\/avs\/1, \/var\/leofs\/avs\/2\].*$/ =~ @buff[i] \
              || /^## obj_containers\.num_of_containers = \[32, 64\].*$/ =~ @buff[i] \
              || /^system_version.*$/ =~ @buff[i] then
            @buff[i] = l
          end
        end
      end
    end
  end
end

class Main
  def initialize
    template_file = FileReader.new($t_conf_fn, false)
    current_file = FileReader.new($c_conf_fn, true)
    new_file = FileWriter.new($n_conf_fn)

    unless template_file.get_type == current_file.get_type then
      raise "File type is different."
    end

    while (l = current_file.get_line) != nil
      template_file.replace_value(l)
    end

    new_file.write_file(template_file.get_file)

  end
end

$n_conf_fn = $stdout
o = OptionParser.new
o.banner = "Usage : #{__FILE__} -t template_conf_file -c current_conf_file -o output_conf_file"
o.on('-t template_conf_file', '[template config file name]') {|v| $t_conf_fn = v }
o.on('-c current_conf_file', '[current config file name]') {|v| $c_conf_fn = v }
o.on('-o output_conf_file', '[output new config file name]', '(default=STDOUT)') {|v| $n_conf_fn = v }
begin
  o.parse!
rescue
  STDERR.puts o.help
  puts "ERROR : unrecognized option"
  exit
end

if $t_conf_fn == nil || $c_conf_fn == nil then
  STDERR.puts o.help
  exit 1
end

begin
  Main.new
rescue => e
  puts e.to_s
end

exit 0
