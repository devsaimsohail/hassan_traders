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

[
  [ "Cotton Yarn 20s", "raw_material", "kg", 720, nil, 800, 2400 ],
  [ "Grey Cloth (Lawn)", "raw_material", "meter", 210, nil, 3000, 9000 ],
  [ "Reactive Dye", "raw_material", "kg", 2600, nil, 150, 180 ],
  [ "Sewing Thread Cones", "raw_material", "cone", 180, nil, 200, 600 ],
  [ "Buttons", "raw_material", "gross", 450, nil, 40, 120 ],
  [ "Packing Cartons", "raw_material", "pcs", 95, nil, 500, 1500 ],
  [ "Lawn Suit 3-Piece", "product", "suit", 2350, 3400, 300, 900 ],
  [ "Bedsheet Double (King)", "product", "pcs", 1650, 2400, 250, 700 ],
  [ "Cotton Kurta (Men)", "product", "pcs", 1100, 1650, 300, 800 ],
  [ "Towel Set (3 pcs)", "product", "set", 880, 1350, 200, 150 ]
].each do |name, category, unit, rate, sale_price, reorder_level, opening_qty|
  company.items.find_or_create_by!(name:) do |item|
    item.assign_attributes(category:, unit:, rate:, sale_price:, reorder_level:, opening_qty:)
  end
end

if company.stock_moves.none?
  store = User.find_by!(mobile: "03001110004")
  yarn, cloth, dye = company.items.where(name: [ "Cotton Yarn 20s", "Grey Cloth (Lawn)", "Reactive Dye" ]).order(:code)
  [ 21, 14, 7 ].each do |days_ago|
    issue = ProductionIssue.new(company:, user: store, date: days_ago.days.ago.to_date, note: "Weekly issue")
    issue.lines = [ { item_id: yarn.id, qty: 380 }, { item_id: cloth.id, qty: 1450 }, { item_id: dye.id, qty: 28 } ]
    issue.save || raise(issue.errors.full_messages.to_sentence)
  end
end

[
  [ "Kohinoor Yarn Traders", "Faisalabad", "041-2634410", "Cotton yarn" ],
  [ "Sitara Weaving Mills", "Faisalabad", "041-8786521", "Grey cloth" ],
  [ "Pak Dyes & Chemicals", "Lahore", "042-37225190", "Dyes" ],
  [ "Usman Stitching Unit (CMT)", "Faisalabad", "0302-7741296", "Finished goods" ]
].each do |name, city, phone, supplies|
  company.suppliers.find_or_create_by!(name:) { |s| s.assign_attributes(city:, phone:, supplies:) }
end

if company.purchase_orders.none?
  partner = User.find_by!(mobile: "03001110001")
  accountant = User.find_by!(mobile: "03001110003")
  store = User.find_by!(mobile: "03001110004")
  item = ->(name) { company.items.find_by!(name:) }
  supplier = ->(name) { company.suppliers.find_by!(name:) }
  make = lambda do |name, days_ago, by, lines|
    company.purchase_orders.create!(supplier: supplier.(name), date: days_ago.days.ago.to_date, created_by: by,
      lines_attributes: lines.map { |n, qty, rate| { item_id: item.(n).id, qty:, rate: } })
  end

  old = make.("Kohinoor Yarn Traders", 30, accountant, [ [ "Cotton Yarn 20s", 1500, 720 ] ])
  old.submit!(by: accountant)
  old.approve!(by: partner)
  old.receive!(by: store, on: 25.days.ago.to_date)
  old.pay!(by: accountant, amount: old.total, method: "bank_transfer", ref: "IBFT · Meezan · 77310012", date: 20.days.ago.to_date)

  dyes = make.("Pak Dyes & Chemicals", 8, partner, [ [ "Reactive Dye", 120, 2850 ] ])
  dyes.submit!(by: partner)
  dyes.receive!(by: store, on: 5.days.ago.to_date)
  dyes.pay!(by: accountant, amount: 150_000, method: "cheque", ref: "Chq #004512 · HBL", date: 3.days.ago.to_date)

  cmt = make.("Usman Stitching Unit (CMT)", 3, accountant, [ [ "Towel Set (3 pcs)", 600, 920 ], [ "Lawn Suit 3-Piece", 300, 2350 ] ])
  cmt.submit!(by: accountant)
  cmt.approve!(by: partner)

  cloth = make.("Sitara Weaving Mills", 1, accountant, [ [ "Grey Cloth (Lawn)", 6000, 215 ] ])
  cloth.submit!(by: accountant)

  make.("Kohinoor Yarn Traders", 0, accountant, [ [ "Sewing Thread Cones", 500, 185 ] ])
end
