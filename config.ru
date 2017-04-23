require 'telegram'
require 'active_record'
require './models/item'

Message.class_eval("attr_reader :from")
Telegram.token = ENV['TELEGRAM_TOKEN']

class App < Bot

  ActiveRecord::Base.establish_connection

  on '/start' do |update|
    if update.message.chat.type == 'private'
      response = 'Hi ' + update.message.chat.first_name +
        ", I am Javier, use me to manage your lists, " +
        "type help to know how to control me.\n"
    else
      response = 'Hi I am Javier, use me to manage your lists, ' +
        "type help to know how to control me.\n"
    end

    update.message.chat.reply response
  end

  on '/help' do |update|
    response = "You can control me by sending these commands:\n" +
      "/start - start a conversation with me :P\n" +
      "/add - Add items to the list - use: /add The Godfather to Movies\n" +
      "/list - Show all the items from a list - use: /list Movies\n" +
      "/lists - Show all your lists\n" +
      "/remove - Remove an item from a list - use: /remove The Godfather from Movies\n" +
      "/delete - Delete a list - use: /delete Movies\n" +
      "/confirm - Confirm an item in a list - use: /confirm The Godfather in Movies\n\n" +
      "Tip: you have a default list, you can add items to it if don't provide a list name, examples:\n" +
      "/add item\n/list\n/confirm item\n/remove item"

    update.message.chat.reply response
  end

  on '/add' do |update|
    text = update.message.text[4..update.message.text.length]
    resource = text.split(%r{[ ]to[ ]})
    response = crud(resource, update.message, 'add') do |item, list, chat|
      add item, list, chat
      item + ' added to ' + list + ' list'
    end

    update.message.chat.reply response
  end

  on '/list' do |update|
    text = update.message.text.split
    if text[0][-1, 1] != 's'
      response = list text[1], update.message.chat.id
      update.message.chat.reply response
    end
  end

  on '/lists' do |update|
    response = lists update.message.chat.id
    update.message.chat.reply response
  end

  on '/remove' do |update|
    text = update.message.text[7..update.message.text.length]
    resource = text.split(%r{[ ]from[ ]})
    response = crud(resource, update.message, 'remove') do |item, list, chat|
      remove item, list, chat
      item + ' removed from ' + list + ' list'
    end

    update.message.chat.reply response
  end

  on '/delete' do |update|
    text = update.message.text[7..update.message.text.length]
    delete text, update.message.chat.id
    response = text + ' list deleted'

    update.message.chat.reply response
  end

  on '/confirm' do |update|
    text = update.message.text[8..update.message.text.length]
    resource = text.split(%r{[ ]in[ ]})
    response = crud(resource, update.message, 'confirm') do |item, list, chat|
      confirm item, list, chat
      item + ' confirmed in ' + list + ' list'
    end

    update.message.chat.reply response
  end

  private

  def get_username(user)
    if user.username.nil?
      if user.first_name.nil?
        username = nil
      else
        username = user.first_name
      end
    else
      username = user.username
    end

    username
  end

  def crud(resource, message, action)
    if resource.count == 1
      if resource[0].strip == 'me'
        username = get_username message.from
        if username.nil?
          response = 'sorry I can not ' + action + 'you, because you have no username'
        else
          response = yield(username, 'default', message.chat.id)
        end
      elsif resource[0].nil?
        response = 'please send me an item to ' + action
      elsif resource[0] != '@listmanagerbot'
        response = yield(resource[0], 'default', message.chat.id)
      end
    elsif resource.count > 1
      if resource[1].to_s.strip.length == 0
        response = 'please send me an item to ' + action
      else
        response = yield(resource[0], resource[1], message.chat.id)
      end
    end

    response
  end

  def add(item, list, chat)
    unless item.nil? && list.nil? && chat.nil?
      Item.create! name: item.strip, list: list.strip, chat: chat
    end
  end

  def list(list, chat)
    if list.nil?
      items = Item.where(list: 'default', chat: chat)
      lista = "Default list:\n"
    else
      items = Item.where(list: list.strip, chat: chat)
      lista = list.strip + " list:\n"
    end

    if items.count == 0
      lista = 'List empty'
    else
      i = 1
      items.each do |item|
        lista += i.to_s + '. ' + item.name + "\n"
        i += 1
      end
    end

    lista
  end

  def lists(chat)
    items = Item.select(:list).where(chat: chat).distinct

    if items == 0
      lista = 'You have no list'
    else
      i = 1
      lista = "which list do you want to see?\n"
      items.each do |item|
        lista += i.to_s + '. ' + item.list + "\n"
        i += 1
      end
    end

    lista
  end

  def remove(name, list, chat)
    Item.where('name like ? and list = ? and chat = ?', "%#{name.strip}%", list.strip, chat.to_s).first.delete
  end

  def delete(list, chat)
    Item.where(list: list.strip, chat: chat).delete_all
  end

  def confirm(item_name, list, chat)
    item = Item.where('name like ? and list = ? and chat = ?', "%#{item_name.strip}%", list.strip, chat.to_s).first
    name = item.name
    item.name = name << " \xE2\x9C\x85"
    item.save
  end
end

run App.new
