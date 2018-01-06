require 'telegram'
require 'active_record'
require_relative 'controllers/items_controller'

Message.class_eval("attr_reader :from")
Telegram.token = ENV['TELEGRAM_TOKEN']

class App < Bot

  def initialize
    ActiveRecord::Base.establish_connection
    @list_manager = ItemsController.new
  end

  on '/start' do |update|
    name = 'guys'
    name = update.message.chat.first_name if update.message.chat.type == 'private'

    response = "Hi #{name}, I am Javier, use me to manage your lists. Type /help to know how to control me."
    update.message.chat.reply response
  end

  on '/help' do |update|
    response = "You can control me by sending these commands:\n" +
      "`/list list_name` - Show all the items from a list\n" +
      "`/lists` - Show all your lists\n" +
      "`/add item to list_name` - Add items to the list (send items separated by commas to add multiple records)\n" +
      "`/confirm item in list_name` - Confirm an item in a list (send items separated by commas to add multiple records)\n" +
      "`/cancel item in list_name` - Cancel an item in a list (send items separated by commas to add multiple records)\n" +
      "`/remove item from list_name` - Remove an item from a list (send items separated by commas to add multiple records)\n" +
      "`/delete list_name` - Delete a list\n" +
      "`/start` - start a conversation with me\n\n" +
      "*Tip:* you have a default list, you can add items to it if don't provide a list name, examples:\n" +
      "`/add item`\n`/list`\n`/confirm item`\n`/remove item`"

    update.message.chat.reply response, parse_mode: 'Markdown'
  end

  on '/add' do |update|
    text = update.message.text[4..update.message.text.length]
    resource = text.split(%r{[ ]to[ ]})
    response = @list_manager.crud('add', resource, update.message) do |item, list, chat|
      @list_manager.add item, list, chat
    end
    update.message.chat.reply response
  end

  on '/list' do |update|
    text = update.message.text.split
    if text[0][-1, 1] != 's'
      response = @list_manager.list text[1], update.message.chat.id
      update.message.chat.reply response
    end
  end

  on '/lists' do |update|
    response = @list_manager.lists update.message.chat.id
    update.message.chat.reply response
  end

  on '/remove' do |update|
    text = update.message.text[7..update.message.text.length]
    resource = text.split(%r{[ ]from[ ]})
    response = @list_manager.crud('remove', resource, update.message) do |item, list, chat|
      @list_manager.remove item, list, chat
    end
    update.message.chat.reply response
  end

  on '/delete' do |update|
    text = update.message.text[7..update.message.text.length]
    response = @list_manager.delete text, update.message.chat.id
    update.message.chat.reply response
  end

  on '/confirm' do |update|
    text = update.message.text[8..update.message.text.length]
    resource = text.split(%r{[ ]in[ ]})
    response = @list_manager.crud('confirm', resource, update.message) do |item, list, chat|
      @list_manager.confirm item, list, chat, true
    end
    update.message.chat.reply response
  end

  on '/cancel' do |update|
    text = update.message.text[7..update.message.text.length]
    resource = text.split(%r{[ ]in[ ]})
    response = @list_manager.crud('cancel', resource, update.message) do |item, list, chat|
      @list_manager.confirm item, list, chat, false
    end
    update.message.chat.reply response
  end
end

run App.new
