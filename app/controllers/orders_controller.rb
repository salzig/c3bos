class OrdersController < ApplicationController

  def index

    @orders = Order.order('id desc').paginate(page: params[:page])
  end

  def new
    @order = Order.new
    @order.order_items = Beverage.all.map do |beverage|
      OrderItem.new(beverage: beverage)
    end

    @last_order = Order.where(user: current_user).order('created_at desc').first
  end

  def create
    @order = Order.new(order_params)
    @order.user = current_user

    @order.pending!

    if @order.save
      submit_order_to_queue(@order)
      redirect_to root_url, :success => "Order placed. Thank you!"

    else
      render "new"
    end
  end

  private
  def order_params
    params.require(:order).permit(:location_id, order_items_attributes: [:beverage_id, :amount])
  end

  def submit_order_to_queue(order)
    connection = Bunny.new(:host => "rabbitmq",
                           :port => "5672",
                           :user => ENV["RABBITMQ_USER"],
                           :password => ENV["RABBITMQ_PASS"],
                           :vhost => ENV["RABBITMQ_VHOST"])
    connection.start

    channel = connection.create_channel
    exchange  = channel.default_exchange

    serialized_order = order.to_json(:include => {
      :order_items => {
        :include =>  :beverage  }
    })
    exchange.publish(serialized_order, :routing_key => "c3bos.orders")
  end
end
