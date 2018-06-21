require "capybara"
require "capybara/dsl"
require "capybara/poltergeist"
require 'open-uri'

Capybara.current_driver = :poltergeist

Capybara.configure do |config|
  config.run_server = false
  config.javascript_driver = :poltergeist
  config.app_host = "https://www.pakutaso.com"
  config.default_max_wait_time = 60
  config.ignore_hidden_elements = false
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {:timeout=>120, :js=>true, :js_errors=>false})
end

include Capybara::DSL # 警告が出るが動く

page.driver.headers = { "User-Agent" => "Mac Safari" }
agent = page.driver.browser

def wait(selector)
  until has_css?(selector)
    sleep
  end
end

kws = %w(仮想通貨) # you can add keywords such as bitcoin which should be separated by spaces

kws.each do |kw|
  encoded_kw = URI.encode kw

  for page in 1..4 do # 5pages
    path = page * 30 # the number of images instead of pages
    visit("https://www.pakutaso.com/search.html?offset=#{path}&limit=30&search=#{encoded_kw}")
    puts current_url

    wait(".loaded") # wait for load
    puts page.find("body")["outerHTML"]

    for num in 0..29 do # the number of images in each page
      page.all(".entries__thumb")[num].trigger("click")
      wait(".button--downloadM") # wait for load
      download_page = page.find(".button--downloadM")[:href] # download blog size image

      url, filename = download_page, rand(10000).to_s + ".png"

      open(url) do |file|
        open(filename, "w+b") do |out|
          out.write(file.read)
        end
      end

      puts "Succeeded in downloading in " + download_page + " -" + num.to_s
      visit("https://www.pakutaso.com/search.html?offset=#{path}&limit=30&search=#{encoded_kw}") # back
      sleep(rand(10))
    end
  end

end
