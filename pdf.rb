require 'pdf/reader'

filename = File.expand_path(File.dirname(__FILE__)) + "/nise.pdf"

PDF::Reader.open(filename) do |reader|
  reader.pages.each do |page|
    puts page.text
  end
end