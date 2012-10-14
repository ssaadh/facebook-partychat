class AddHttpEndpointColumnToFbThread < ActiveRecord::Migration
  def change
    add_column :fb_threads, :post_http_endpoint, :string
    add_column :fb_threads, :receive_http_endpoint, :string
  end
end
