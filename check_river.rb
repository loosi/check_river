#!/usr/bin/env ruby

# ### README ####
#
# Check if river is updating and alert/warn if not
#
# gem install elasticsearch
# gem install couchrest
#

require 'rubygems'
require 'couchrest'
require 'elasticsearch'
require 'optparse'

#Variables
@es_client    = ''
@couch_client = ''
@options      = {:es_port => 9200, :es_address => '127.0.0.1', :warning => nil, :crit => 50}
@couches      = Array.new
@rivers       = Array.new
@results      = Array.new

def check_river
  be_debug if @options[:debug]
  init_elastic
  get_rivers
  compare_seq
  output_status
end

def init_elastic
  @es_client = Elasticsearch::Client.new host: "http://#{@options[:es_address]}:#{@options[:es_port]}"
  puts "Connecting to #{@options[:es_address]}:#{@options[:es_port]}" if @options[:debug]
end

def init_couch(address, port)
  p "Connecting to couchdb #{address}:#{port}" if @options[:debug]
  return CouchRest.new("http://#{address}:#{port}")
end

def be_debug
  @options.each do |key, value|
    puts "#{key} => #{value}"
  end
end

def couch_seq(name, address, port)
  couch_client = init_couch(address, port)
  begin
    couch_db = couch_client.database("#{name}")
    return couch_db.info["update_seq"]
  rescue RestClient::ResourceNotFound
    nil
  end
end

def find_in_couches(type)
  puts "unknown error" && exit(3) if type.nil?
  @couches.each do |f|
    return f if f['_type'] == type
  end
end

def compare_seq
  @rivers.each_with_index do |f, index|
    matched_couch = find_in_couches(f['_type'])
    if f['_type'] == matched_couch['_type']
      es_seq = f['_source']['couchdb']['last_seq'].to_i
      cd_seq = couch_seq(matched_couch['_source']['couchdb']['db'],matched_couch['_source']['couchdb']['host'],matched_couch['_source']['couchdb']['port']).to_i
      #cd_seq = couch_seq(@couches[index]['_source']['couchdb']['db'],@couches[index]['_source']['couchdb']['host'],@couches[index]['_source']['couchdb']['port'])
      p "ES #{@couches[index]['_source']['couchdb']['db']} seq: #{es_seq}" if @options[:debug]
      p "Couch #{@couches[index]['_source']['couchdb']['db']} seq : #{cd_seq}" if @options[:debug]
      populate_results(es_seq, cd_seq)
    end
  end
end

def populate_results(es_seq, cd_seq)
  if @options[:warning]
    @results << 1 if es_seq-cd_seq>=@options[:warning]
  elsif es_seq-cd_seq>=@options[:crit]
    @results << 2
  else
    @results << 0
  end
end

#list floating rivers
def get_rivers
  rivers = @es_client.search index: '_river', q: '*'
  #exit if no rivers
  p "no rivers found" && exit(3) if rivers['_shards']['failed'] > 0
  #sort result
  rivers['hits']['hits'].each do |f|
    @couches << f if f['_id'] == '_meta'
    @rivers << f if f['_id'] == '_seq'
  end
  if @options[:debug]
     @couches.each do |f|
      p "db => #{f['_source']['couchdb']['db']}"
      p "host => #{f['_source']['couchdb']['host']}"
      p "port => #{f['_source']['couchdb']['port']}"
    end
  end
end

def output_status
  p @results.inspect if @options[:debug]
  if @results.include? 2
    print "CRITICAL - ",count=@results.select {|e| e == 2}.size," rivers of #{@results.count} outdated"
    exit(2)
  elsif @results.include? 1
    print "WARNING - ",count=@results.select {|e| e == 1}.size," rivers of #{@results.count} floating bumpy"
    exit(1)
  else
    p "OK - #{@results.count} rivers floating flawlessly"
  end
end

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: check_river - takes couchdb from active rivers and checks it river is up-to-date"
  opts.on("-h", "--help", "print options") do |p|
    puts opts
    exit
  end
  opts.on("-v", "--debug", "debug") do |p|
    @options[:debug] = true
  end
  opts.on("-p", "--elasticsearch-port PORT", "elasticsearch port, default 9200") do |p|
    @options[:es_port] = p
  end
  opts.on("-a", "--elasticsearch-address ADDRESS", "elasticsearch address, default 127.0.0.1") do |q|
    @options[:es_address] = q
  end
  opts.on("-w", "--warning [OPT]", "warning threshold, default 0 (no warning, always critical)") do |q|
    @options[:warning] = q.to_i
  end
  opts.on("-c", "--critical CRITICAL", "Critical threshold, default is 50 (sequence difference)") do |q|
    @options[:crit] = q.to_i
  end
end
optparse.parse!


###############
#execute program
check_river