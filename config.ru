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
      "/cancel - Cancel an item in a list - use: /cancel The Godfather in Movies\n\n" +
      "Tip: you have a default list, you can add items to it if don't provide a list name, examples:\n" +
      "/add item\n/list\n/confirm item\n/remove item"

    update.message.chat.reply response
  end

  on '/add' do |update|
    text = update.message.text[4..update.message.text.length]
    resource = text.split(%r{[ ]to[ ]})
    response = crud('add', resource, update.message) do |item, list, chat|
      add item, list, chat
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
    response = crud('remove', resource, update.message) do |item, list, chat|
      remove item, list, chat
    end

    update.message.chat.reply response
  end

  on '/delete' do |update|
    text = update.message.text[7..update.message.text.length]
    response = delete text, update.message.chat.id

    update.message.chat.reply response
  end

  on '/confirm' do |update|
    text = update.message.text[8..update.message.text.length]
    resource = text.split(%r{[ ]in[ ]})
    response = crud('confirm', resource, update.message) do |item, list, chat|
      confirm item, list, chat, true
    end

    update.message.chat.reply response
  end

  on '/cancel' do |update|
    text = update.message.text[8..update.message.text.length]
    resource = text.split(%r{[ ]in[ ]})
    response = crud('confirm', resource, update.message) do |item, list, chat|
      confirm item, list, chat, false
    end

    update.message.chat.reply response
  end

  private

  def get_username(user)
    username = nil
    username = user.username unless user.username.nil?
    username ||= user.first_name unless user.first_name.nil?

    return username
  end

  def crud(action, resource, message)
    return "Please specify an item to #{action}" if resource.empty?
    item = resource[0]

    if resource.count == 1
      list = 'default'
      return "Please specify an item to #{action}" if resource[0] == '@listmanagerbot'
    elsif resource.count > 1
      return "Please specify a list to #{action} the item" if resource[1].empty?
      list = resource[1]
    end

    if resource[0].strip == 'me'
      username = get_username message.from
      return "Sorry, I can not #{action} you because you don't have a username" if username.nil?
      item = username
    end

    yield(item, list, message.chat.id)
  end

  def add(item, list, chat)
    unless item.nil? && list.nil? && chat.nil?
      records = Item.where(name: item.strip, list: list.strip, chat: chat.to_s)
      return "#{item} is already in #{list} list" if records.count > 0
      Item.create! name: item.strip, list: list.strip, chat: chat
      return "#{item} added to #{list} list"
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
        name = item.name
        name << " \xE2\x9C\x85" if item.confirmed?
        lista += i.to_s + '. ' + name + "\n"
        i += 1
      end
    end

    return lista
  end

  def lists(chat)
    items = Item.select(:list).where(chat: chat).distinct

    if items == 0
      lista = 'You have no lists'
    else
      i = 1
      lista = "which list do you want to see?\n"
      items.each do |item|
        lista += i.to_s + '. ' + item.list + "\n"
        i += 1
      end
    end

    return lista
  end

  def remove(item, list, chat)
    records = Item.where(name: item.strip, list: list.strip, chat: chat.to_s)
    return "#{item} is not in the #{list} list" if records.count == 0
    Item.where('name like ? and list = ? and chat = ?', "%#{item.strip}%", list.strip, chat.to_s).first.delete
    return "#{item} removed from #{list} list"
  end

  def delete(list, chat)
    list = 'default' if list.empty?
    records = Item.where(list: list.strip, chat: chat.to_s)
    return "#{list} list does not exist" if records.count == 0
    Item.where(list: list.strip, chat: chat).delete_all
    return "#{list} list deleted"
  end

  def confirm(item_name, list, chat, sw)
    action = sw ? 'confirmed' : 'canceled'
    item = Item.where('name like ? and list = ? and chat = ?', "%#{item_name.strip}%", list.strip, chat.to_s).first
    item.confirmed = sw
    item.save
    return "#{item.name} #{action} in #{list} list"
  end
end

run App.new
