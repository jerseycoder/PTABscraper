#!/usr/bin/env ruby
require 'pdf-reader'
require 'open-uri'
require 'net/http'
require 'net/https'
require 'rubygems'
require 'mechanize'

revcnt = 0
affcnt = 0
clmno = 0
numofdays = 10 # default to 10 days
numofdays = ARGV[0]
#Call up the HTML page with the most recent set of PTAB decisions
p4h = Mechanize.new
  #{|a| a.ssl_version, a.verify_mode = 'SSLv3', OpenSSL::SSL::VERIFY_NONE}
page = p4h.get("https://e-foia.uspto.gov/Foia/DispatchBPAIServlet?RetrieveRecent=" + numofdays.to_s)
# listings are odd or even, get both sets and we have full listing
# page.body will have the HTML content we now parse
#entrylist = page.parser.xpath("//tr[@class='odd']/td[.=' - (D)']")
entrylist = page.parser.xpath("//tr[@class='odd']")
entrylist = entrylist + page.parser.xpath("//tr[@class='even']")
# we want to iterate through the entry items
entrylist.each_with_index do |item, i|
  # Extract the URL from each listed PTAB decision
  decisionURL = item.xpath("//tr/td/a[@target='_self']/@href")[i].text.strip
 #puts decisionURL
  io     = open('https://e-foia.uspto.gov/Foia/'+decisionURL)
  reader = PDF::Reader.new(io)
  decisiontext = ""
  start = 0
  len = 0
  reader.pages.each do |page|
  # puts page.fonts
    decisiontext = decisiontext + page.text
  end
  start = decisiontext.index("DECISION\n")
  # If there is a DECISION text:
    if (start != 0 && !start.nil?)
      len = start + 100
      decisiontext = decisiontext[start..-1]
      # check for affirmed or reversed
      if decisiontext.downcase().include? "affirmed"
        clmno = decisiontext.index("claim")
        if (clmno != 0 && !clmno.nil?)
          decisiontext = decisiontext[clmno..(clmno+20)]
          # decisiontext will have the text of the claims decided upon
        end
        affcnt = affcnt + 1
      elsif decisiontext.downcase().include? ("reversed" or "reverse")
        clmno = decisiontext.index("claim")
        if (clmno != 0 && !clmno.nil?)
          decisiontext = decisiontext[clmno..(clmno+20)]
          # decisiontext will have the text of the claims decided upon
        end
        revcnt = revcnt + 1
      end
    end
end
puts "Number of Affirmed decisions: " + affcnt.to_s
puts "Number of Reversed decisions: " + revcnt.to_s