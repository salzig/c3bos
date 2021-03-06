# frozen_string_literal: true

class Order < ActiveRecord::Base
  belongs_to :user
  has_many :order_items
  accepts_nested_attributes_for :order_items

  enum state: %i[pending printed]
end
