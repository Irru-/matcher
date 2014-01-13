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
