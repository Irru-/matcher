Dit is de match web applicatie van JobHearted. 

Om te launchen, zijn verschillende ruby gems nodig, onder ruby 1.9.3:

- Nokogiri
- dm-core
- dm-constraints
- dm-timestamps
- dm-aggregates
- dm-migrations
- dm-validations
- sinatra
- sinatra-reloader
- pdf-reader
- dm-mysql-adapter
- haml

Wanneer deze gems geinstalleerd zijn kan de applicatie uitgevoerd worden via de command line:

ruby applicatie.rb -o 0.0.0.0 -p 8080

hierna is deze te gebruiken op http://localhost:8080/