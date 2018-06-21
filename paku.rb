require "capybara"
require "capybara/dsl"
require "capybara/poltergeist"
require "open-uri"
require "pry"

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

if ARGV[0].nil?
  puts "第一引数には、ダウンロードしたい画像の数を入力してください。"
  exit!
end

if ARGV[1].nil?
  puts "第二引数以降には、ダウンロードしたい画像のキーワードを1つ以上入力してください。"
  exit!
end

def wait_for(selector)
  sleep until has_css?(selector)
end

kws = ARGV[1..-1]
num_of_downloading_pics = ARGV[0].to_i
pages = 1 + (num_of_downloading_pics / 30).to_i # ∵ 1ページあたり画像30枚

kws.each do |kw|
  encoded_kw = URI.encode kw

  for page in 1..pages do # TODO: ページ数変えられるようにする

    # URLに含まれるパラメータoffsetはページ数ではなく、
    # そのページの最初の画像のindexであるため
    visit("https://www.pakutaso.com/search.html?offset= \
      #{(page - 1) + 30}&limit=30&search=#{encoded_kw}")

    wait_for(".loaded")

    # 1ページあたり画像30枚（再）
    for num in 0..[num_of_downloading_pics - 1, 29].min do
      page.all(".entries__thumb")[num].trigger("click")
      wait_for(".button--downloadM")

      # download blog size image
      download_page = page.find(".button--downloadM")[:href]
      filename =
        "images/" + Time.now.to_i.to_s + "_" +
          kw + "_" + page.to_s + "-" + num.to_s + ".png"
      open(download_page) do |file|
        open(filename, "w+b") do |out|
          out.write(file.read)
        end
      end

      puts "Succeeded in downloading in " + download_page + " -" + num.to_s

      visit("https://www.pakutaso.com/search.html?offset= \
        #{(page - 1) + 30}&limit=30&search=#{encoded_kw}") # back
      sleep(rand(10))
    end
  end

end
