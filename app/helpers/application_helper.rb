module ApplicationHelper
  ICONS = {
    dashboard: "M4 4h6v7H4zM14 4h6v4h-6zM14 12h6v8h-6zM4 15h6v5H4z",
    stock: "M21 8l-9-5-9 5 9 5 9-5zM3 8v8l9 5 9-5V8M12 13v8",
    purchases: "M3 4h2l2.4 11h11L21 7H6M9 20h.01M18 20h.01",
    sales: "M9 3h6v3H9zM7 4.5H5V21h14V4.5h-2M8.5 11h7M8.5 15h5",
    invoices: "M6 3h12v18l-3-2-3 2-3-2-3 2zM9 8h6M9 12h6M9 16h3",
    payments: "M3 7h18v12H3zM3 11h18M7 15h3",
    customers: "M9 11a4 4 0 100-8 4 4 0 000 8zM2 21a7 7 0 0114 0M16 3.5a4 4 0 010 7.5M22 21a7 7 0 00-4.5-6.5",
    khata: "M5 4h10a3 3 0 013 3v14H8a3 3 0 01-3-3zM5 18a3 3 0 013-3h10M9 8h5",
    activity: "M12 21a9 9 0 100-18 9 9 0 000 18zM12 7v5l3 2",
    settings: "M4 7h9M17 7h3M4 17h3M11 17h9M15 5v4M9 15v4",
    plus: "M12 5v14M5 12h14",
    logout: "M15 4h4v16h-4M10 8l-4 4 4 4M6 12h11",
    pdf: "M12 4v11M7 10l5 5 5-5M5 20h14",
    info: "M12 21a9 9 0 100-18 9 9 0 000 18zM12 11v5M12 8h.01"
  }.freeze

  NAV = [
    [ "Overview", [ { label: "Dashboard", icon: :dashboard, path: :root_path, permission: :dashboard } ] ],
    [ "Inventory", [
      { label: "Stock", icon: :stock, path: :items_path, permission: :stock, match: "/stock" },
      { label: "Purchase orders", icon: :purchases, path: :purchase_orders_path, permission: :purchase_create, match: "/purchases" }
    ] ],
    [ "Sales and money", [
      { label: "Sales orders", icon: :sales, path: :sales_orders_path, permission: :sales, match: "/orders" },
      { label: "Bills", icon: :invoices, path: :invoices_path, permission: :invoices, match: "/bills" },
      { label: "Payments", icon: :payments, path: :payments_path, permission: :payments, match: "/payments" },
      { label: "Customers", icon: :customers, path: :customers_path, permission: :khata, match: "/customers" },
      { label: "Khata", icon: :khata, path: :khata_path, permission: :khata, match: "/khata" }
    ] ],
    [ "Admin", [
      { label: "Activity log", icon: :activity, path: :activity_logs_path, permission: :activity_log },
      { label: "Settings", icon: :settings, path: :settings_path, permission: :settings }
    ] ]
  ].freeze

  LEVEL_TONES = { "yes" => "pill-ok", "view" => "pill-info", "no" => "pill-mute" }.freeze

  def icon(name, classes: nil)
    tag.svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.8,
      "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true, class: classes) do
      tag.path(d: ICONS.fetch(name))
    end
  end

  def nav_groups
    NAV.filter_map do |group, items|
      visible = items.select { |item| item[:permission].nil? || Current.access.sees?(item[:permission]) }
      [ group, visible ] if visible.any?
    end
  end

  def record_path_for(ref)
    return if ref.blank?

    if ref.match?(/\A[RP]\d+\z/) && Current.access.sees?(:stock)
      @item_ids_by_code ||= Current.company.items.pluck(:code, :id).to_h
      item_path(@item_ids_by_code[ref]) if @item_ids_by_code[ref]
    elsif ref.match?(/\AC\d+\z/) && Current.access.sees?(:khata)
      @customer_ids_by_code ||= Current.company.customers.pluck(:code, :id).to_h
      customer_path(@customer_ids_by_code[ref]) if @customer_ids_by_code[ref]
    elsif ref.match?(/\ASO-\d+\z/) && Current.access.sees?(:sales)
      @so_ids_by_number ||= Current.company.sales_orders.pluck(:number, :id).to_h
      sales_order_path(@so_ids_by_number[ref]) if @so_ids_by_number[ref]
    elsif ref.match?(/\ARV-\d+\z/) && Current.access.sees?(:payments)
      @payment_ids_by_number ||= Current.company.payments.pluck(:number, :id).to_h
      payment_path(@payment_ids_by_number[ref]) if @payment_ids_by_number[ref]
    elsif ref.match?(/\AINV-\d+\z/) && Current.access.sees?(:invoices)
      @invoice_ids_by_number ||= Current.company.invoices.pluck(:number, :id).to_h
      invoice_path(@invoice_ids_by_number[ref]) if @invoice_ids_by_number[ref]
    elsif ref.match?(/\APO-\d+\z/) && Current.access.sees?(:purchase_create)
      @po_ids_by_number ||= Current.company.purchase_orders.pluck(:number, :id).to_h
      purchase_order_path(@po_ids_by_number[ref]) if @po_ids_by_number[ref]
    end
  end

  def field_number(record, attribute)
    value = record.public_send(attribute)
    return if value.nil? || (record.new_record? && value.zero? && !record.errors.key?(attribute))

    value.to_d.to_s("F").delete_suffix(".0")
  end

  def person_policy(person)
    PersonPolicy.new(Current.access, person)
  end

  def pill(text, tone = nil)
    tag.span(text, class: [ "pill", tone ])
  end

  def level_pill(level)
    pill(level.to_s.capitalize, LEVEL_TONES[level.to_s])
  end

  def rs(amount) = Fmt.rs(amount)

  def brand_style(company)
    color = company&.brand_color || "#0F766E"
    ink = company&.brand_ink || "#FFFFFF"
    "--brand: #{color}; --brand-ink: #{ink};"
  end

  def company_logo(company, size: "size-9", text: "text-[13px]")
    if company.logo.attached?
      image_tag company.logo, alt: "#{company.name} logo", class: "#{size} shrink-0 rounded-lg bg-white object-contain"
    else
      tag.span(company.initials, class: "#{size} #{text} grid shrink-0 place-items-center rounded-lg bg-brand font-semibold text-brand-ink", aria: { hidden: true })
    end
  end
end
