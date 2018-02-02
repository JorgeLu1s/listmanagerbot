class Item < ActiveRecord::Base
  def check(action)
    if action == 'confirmed'
      confirmed?
    else
      !confirmed?
    end
  end
end
