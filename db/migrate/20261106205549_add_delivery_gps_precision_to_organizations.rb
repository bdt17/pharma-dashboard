class AddDeliveryGpsPrecisionToOrganizations < ActiveRecord::Migration[8.1]
  def change
    # How much of the phone's GPS fix a "delivered" custody event keeps --
    # see CustodyLog#apply_delivery_gps_precision. "approximate" by default:
    # a delivery to a patient's home makes an exact fix health information.
    add_column :organizations, :delivery_gps_precision, :string, default: "approximate", null: false
  end
end
