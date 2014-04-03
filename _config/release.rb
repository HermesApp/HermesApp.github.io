#!/usr/bin/env ruby
# Usage: ruby release.rb version path/to/versions.xml path/to/CHANGELOG.md

require 'rubygems'
require 'redcarpet'
require 'nokogiri'

include Redcarpet

version           = ARGV[0]
versions_xml_file = ARGV[1]
changelog         = ARGV[2]

html_root = File.expand_path '../..', __FILE__

index = File.join html_root, 'index.html'
s = File.read(index)
s = s.gsub(/(class=.download. href.*Hermes-)[\d\.]+(\.zip)/, "\\1#{version}\\2")
File.open(index, 'wb') { |f| f << s }

versions = File.expand_path('../../versions.xml', __FILE__)
new_xml = File.read(versions_xml_file).gsub("\t", '  ')

s = Nokogiri::XML File.read(versions)
has_item = s.css('item title').any? do |node|
  if node.content == "Version #{version}"
    node.parent.replace s.fragment(new_xml)
  end
end

if !has_item
  s.css('language').first.add_next_sibling s.fragment(new_xml)
end
File.open(versions, 'wb') { |f| f << s.to_xhtml(:indent => 2) }

File.open(File.join(html_root, '/changelog.html'), 'wb') { |f|
  f << Markdown.new(Render::HTML).render(File.read(changelog))
}
