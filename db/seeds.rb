# Development data. Everyone below logs in with their mobile number and DEV_PASSWORD.
DEV_PASSWORD = "hassan-dev-2026"

company = Company.find_or_create_by!(name: "Hassan Traders") do |c|
  c.legal_name = "Hassan Traders"
  c.city = "Faisalabad"
  c.address = "Kapra Market, Jhang Bazar"
  c.phone = "041-2600000"
  c.mobile = "0300-6600000"
end

[
  [ "Muhammad Hassan", "03001110001", :partner, "Faisalabad" ],
  [ "Ali Hassan", "03001110002", :partner, "Lahore" ],
  [ "Bilal Ahmed", "03001110003", :accountant, "Faisalabad" ],
  [ "Shahid Iqbal", "03001110004", :store_incharge, "Faisalabad" ],
  [ "Asif Ali", "03001110005", :sales_officer, "Faisalabad" ]
].each do |name, mobile, role, city|
  user = User.find_or_create_by!(mobile:) do |u|
    u.name = name
    u.city = city
    u.password = DEV_PASSWORD
  end
  user.assign_role!(role, company)
end
