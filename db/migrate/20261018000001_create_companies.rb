class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :legal_name
      t.string :ntn
      t.string :strn
      t.string :address
      t.string :city
      t.string :phone
      t.string :mobile
      t.string :email
      t.string :brand_color, null: false, default: "#0F766E"
      t.string :currency, null: false, default: "PKR"
      t.string :fiscal_year_start, null: false, default: "1 July"
      t.timestamps
    end
  end
end
