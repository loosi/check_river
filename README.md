## check_river.rb
Small ruby script to check if all rivers from elasticsearch are running up-to-date  
Uses the sequences (last_sequence) from ES and Couchdb and compares them with crit/warning threshold  

Output formated for use with Icinga/Nagios

Tested with Ruby 2.0 but should work with 1.9% too  

You need the following gems installed  

    gem install couchrest elasticsearch

####Usage: check_river.rb
   
    check_river.rb -h, --help
    check_river.rb -v, --debug
    check_river.rb -p 9200, --elasticsearch-port 9200, default 9200
    check_river.rb -a 127.0.0.1 ,--elasticsearch-address 127.0.0.1, default 127.0.0.1
    check_river.rb -w, --warning, default nil (no warning, always critical)
    check_river.rb -c 50, --critical, default is 50 (sequence difference)

Deploy the script on machines that has http access to elasticsearch and couchdb