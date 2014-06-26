## check_river.rb
Small ruby script to check if all rivers from elasticsearch are running up-to-date  
Uses the sequences (last_sequence) from ES and Couchdb and compares them with crit/warning threshold  

Output formated for use with Icinga/Nagios

Tested with Ruby 2.0 but should work with 1.9% too  

You need the following gems installed  

    gem install couchrest elasticsearch

####Usage: check_river.rb
   
    ruby check_river.rb -h, --help
    ruby check_river.rb -v, --debug
    ruby check_river.rb -p, --elasticsearch-port, default 9200
    ruby check_river.rb -a ,--elasticsearch-address, default 127.0.0.1
    ruby check_river.rb -w, --warning, default nil (no warning, always critical)
    ruby check_river.rb -c, --critical, default is 50 (sequence difference)

Deploy the script on machines that has http access to elasticsearch and couchdb