require_relative '../models/item'

class ItemsController
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
      items = item.split(',') if item.include?(',')
      records = []

      unless items.nil?
        items.each do |i|
          record = Item.where(name: i.strip, list: list.strip, chat: chat.to_s).first
          records << record.name unless record.nil?
        end

        if records.count > 0
          response = "#{records.inspect} already in #{list} list"
          items.collect!(&:strip)
          items = items - records
        end

        items.each do |i|
          Item.create! name: i.strip, list: list.strip, chat: chat
        end

        return "#{response} \n #{items.inspect} added to #{list} list"
      else
        records = Item.where(name: item.strip, list: list.strip, chat: chat.to_s)
        return "#{item} is already in #{list} list" if records.count > 0
        Item.create! name: item.strip, list: list.strip, chat: chat
      end

      return "#{item} added to #{list} list"
    end
  end

  def list(list, chat)
    list = 'default' if list.nil?

    items = Item.where(list: list.strip, chat: chat).order(:id)
    lista = list.strip.titleize + " list:\n"

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
      lista = "Your current lists:\n"
      items.each do |item|
        lista += i.to_s + '. ' + item.list + "\n"
        i += 1
      end
    end

    return lista
  end

  def remove(item, list, chat)
    items = item.split(',') if item.include?(',')
    records = []

    unless items.nil?
      items.each do |i|
        records << Item.where(name: i.strip, list: list.strip, chat: chat.to_s).first
      end
      return "#{items.inspect} not in #{list} list" if records.compact.count == 0

      items.each do |i|
        Item.where('name like ? and list = ? and chat = ?', "%#{i.strip}%", list.strip, chat.to_s).first.delete
      end
      return "#{items.inspect} removed from #{list} list"
    else
      records = Item.where('name like ? and list = ? and chat = ?', "%#{item.strip}%", list.strip, chat.to_s)
      return "#{item} is not in #{list} list" if records.count == 0
      record = Item.where('name like ? and list = ? and chat = ?', "%#{item.strip}%", list.strip, chat.to_s).first
      record.delete
    end

    return "#{record.name} removed from #{list} list"
  end

  def delete(list, chat)
    list = 'default' if list.empty?
    records = Item.where(list: list.strip, chat: chat.to_s)
    return "#{list} list does not exist" if records.count == 0

    Item.where(list: list.strip, chat: chat).delete_all
    return "#{list} list deleted"
  end

  def confirm(item, list, chat, sw)
    action = sw ? 'confirmed' : 'canceled'
    items = item.split(',') if item.include?(',')
    records = []

    unless items.nil?
      items.each do |i|
        record = Item.where(name: i.strip, list: list.strip, chat: chat.to_s).first
        records << record.name unless record.nil? || !record.check(action)
      end

      if records.count > 0
        response = "#{records.inspect} already #{action} in #{list} list"
        items.collect!(&:strip)
        items = items - records
      end

      items.each do |i|
        Item.where('name like ? and list = ? and chat = ?', "%#{i.strip}%", list.strip, chat.to_s).first.update(confirmed: sw)
      end

      return "#{response} \n #{items.inspect} #{action} in #{list} list"
    else
      records = Item.where(name: item.strip, list: list.strip, chat: chat.to_s)
      unless records.empty?
        return "#{item} is already #{action} in #{list} list" if records.first.check action
      end
      record = Item.where('name like ? and list = ? and chat = ?', "%#{item.strip}%", list.strip, chat.to_s).first
      return "#{item} is not in #{list} list" if record.nil?
      return "#{record.name} is already #{action} in #{list} list" if record.check action
      record.update(confirmed: sw)
    end

    return "#{record.name} #{action} in #{list} list"
  end
end
