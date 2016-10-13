require 'telegram'

Telegram.token = ENV['TELEGRAM_TOKEN']

class App < Bot
  on :echo do |update|
    update.message.chat.reply 'Hi there!'
  end
end

run App.new
