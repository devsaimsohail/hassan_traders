class AddNoteToSupplierPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :supplier_payments, :note, :string
  end
end
