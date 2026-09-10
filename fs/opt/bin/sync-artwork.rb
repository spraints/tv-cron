#!/usr/bin/ruby

require "digest/sha1"
require "net/http"
require "nokogiri"
require "thread"
require "yaml"

def main
  frame_host = ENV["FRAME_TV_ADDR"] or raise "FRAME_TV_ADDR must be set in the environment"
  frame_mac  = ENV["FRAME_TV_MAC"]  or raise "FRAME_TV_MAC must be set in the environment"
  data_dir   = ENV["DATA_DIR"]      or raise "DATA_DIR must be set in the environment"

  state_file = File.join(data_dir, "state.yml")
  token_file = File.join(data_dir, "tv-token")

  now = Time.now
  today = now.strftime("%Y-%m-%d")
  state = State.new(state_file)

  wol = Thread.new do
    puts "Waking up TV ..."
    system_must "samsungtv", "--host", frame_host, "--token-file", token_file,
      "wol", frame_mac
  end

  today_image_info = state["images"].find { |i| i["date"] == today }
  if today_image_info.nil?
    puts "[#{today}] Getting wikiart's image of the day..."
    image_url = get_wikiart_image_of_the_day
    puts "==> #{image_url}"

    wol.value

    IO.popen(["samsungtv", "--host", frame_host, "--token-file", token_file,
              "art-upload", "--url", image_url]) do |f|
      output = f.read
      if output =~ /OK: uploaded -> (.*)/
        today_image_info = {
          "url" => image_url,
          "content_id" => $1,
          "date" => today,
          "uploaded_at" => now.to_i,
        }
        state["images"] << today_image_info
        state.save!
      else
        puts output
        exit 1
      end
    end
  end

  IO.popen(["samsungtv", "--host", frame_host, "--token-file", token_file,
            "art-mode"]) do |f|
    mode = f.read.strip
    puts "*** Art mode is currently #{mode} ***"

    if mode == "on"
      puts "Setting artwork to #{today_image_info.inspect}"
      wol.value
      system_must "samsungtv", "--host", frame_host, "--token-file", token_file,
        "art-display", today_image_info.fetch("content_id")
    end
  end
end

class State
  def initialize(path)
    @path = path
    @data = YAML.load(File.read(path))
  rescue Errno::ENOENT
    @data = {"images" => []}
  end

  def [](key)
    @data.fetch(key)
  end

  def save!
    File.write(@path, YAML.dump(@data))
  end
end

def get_wikiart_image_of_the_day
  html = fetch("https://wikiart.org/")
  doc = Nokogiri::HTML(html)
  img = doc.css(".artwork-of-the-day img[ng-show=showPreloadedMainImage]").first
  if img.nil?
    raise "no image found!"
  end
  img["src"].split("!").first
end

def fetch(url)
  10.times do
    response = Net::HTTP.get_response(URI(url))
    case response
    when Net::HTTPRedirection
      url = response['location'] or raise "redirection without location"
    when Net::HTTPOK
      return response.body
    else
      response.value
      raise "bad response"
    end
  end
  raise "too many redirects"
end

def system_must(*cmd)
  system(*cmd) or raise "#{cmd.first} failed!"
end

main
