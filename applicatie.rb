#!/usr/local/bin/ruby
# http://www.railstation.eu
# Peter Dierx - 2013

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'sinatra'
require 'sinatra/reloader'
require 'nokogiri'
require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-constraints'

# RELOAD
also_reload "#{ settings.root }/applicatie.rb"

class Vacature
  
  include DataMapper::Resource

  property :id,       Serial
  property :functie,  String
  property :uren,     Integer
  property :locatie,  String


end

configure :development do

  DataMapper.setup( :default, "sqlite3://#{ Dir.pwd }/database.sqlite3")

end


DataMapper.auto_upgrade!


get '/' do
  erb :index
end

get '/string' do
  @html_doc = Nokogiri::HTML( '<html><body><h1>Mr. Belvedere Fan Club</h1></body></html>' )
  erb :string, :layout => false
end

get '/bestand' do
  bestand   = File.open( "#{ settings.root }/bestanden/demo.html" )
  @html_doc = Nokogiri::HTML( bestand )
  bestand.close
  erb :string, :layout => false
end

get '/acteur' do
  bestand  = File.open( "#{ settings.root }/bestanden/shows.xml" )
  xml_doc = Nokogiri::XML( bestand )
  @acteurs = xml_doc.xpath( '//character' )
  bestand.close
  erb :acteur
end

get '/serie' do
  xml_doc = Nokogiri::XML( File.open( "#{ settings.root }/bestanden/shows.xml" ) )
  @series = xml_doc.xpath( '//name')
  erb :serie
end

get '/drama' do
  # css selector
  xml_doc = Nokogiri::XML( File.open( "#{ settings.root }/bestanden/shows.xml" ) )
  @drama  = xml_doc.css( 'dramas name' ).first
  erb :drama
end

get '/functies' do
  html_doc   = Nokogiri::HTML( File.open( "#{ settings.root }/bestanden/starapple.html" ) )
  @functies = html_doc.xpath( '//functie' )
  erb :functie
end

get '/vacatures' do
  html_doc   = Nokogiri::HTML( File.open( "#{ settings.root }/bestanden/starapple.html" ) )
  @vacatures = html_doc.css( '#omschrijving' )

  @vacatures.each do |vacature|

    jobs = Vacature.new
    jobs.functie  = vacature.elements[0].content
    jobs.locatie  = vacature.elements[1].content
    jobs.uren     = vacature.elements[2].content
    jobs.save

  end

  if params['reeks']
    @reeks = params['reeks']
  else
    @reeks = ["Test"]
  end

  erb :vacature
end

get '/argumenten' do

  "#{params.inspect}"

end

get '/form' do

  erb :form
end

post '/verwerk' do

  #vac = Vacature.new

  #vac.functie   = params[:functie]
  #vac.locatie   = params[:locatie]
  #vac.uren      = params[:uren]

  #vac.save

  #reeks = [vac.uren]

  redirect "/try?u=#{params[:uren]};c=0"

end

post '/locatie' do

  redirect "/try?u=#{params[:locatie]};c=1"

end

post '/functie' do

  redirect "/try?u=#{params[:functie]};c=2"

end

post '/match' do

  redirect "/try?u=#{params[:locatie]};a=#{params[:uren]};b=#{params[:functie]};c=3"

end


get '/try' do

  reeks = params
  @summary = params

  val = reeks[:c].to_i

  if val == 0
    @vac = Vacature.all(:uren => reeks[:u])
  elsif val == 1
    @vac = Vacature.all(:locatie => reeks[:u])
  elsif val == 2
    @vac = Vacature.all(:functie => reeks[:u])
  elsif val == 3

    
    if reeks[:b] == ''
      @best = Vacature.all(:locatie => reeks[:u], :uren => reeks[:a], :functie => reeks[:b])
    else
      @best = Vacature.all(:locatie => reeks[:u], :uren => reeks[:a], :functie.like => ("%" + reeks[:b] + "%"))  
    end
    

    @lu = Vacature.all(:locatie => reeks[:u], :uren => reeks[:a])

    if reeks[:b] == ''
      @lf = Vacature.all(:locatie => reeks[:u], :functie => reeks[:b])
    else
      @lf = Vacature.all(:locatie => reeks[:u], :functie.like => ("%" + reeks[:b] + "%"))
    end

    
    if reeks[:b] == ''
      @uf = Vacature.all(:uren => reeks[:a], :functie => reeks[:b])
    else
      @uf = Vacature.all(:uren => reeks[:a], :functie.like => ("%" + reeks[:b] + "%"))
    end

  end
  erb :try

end