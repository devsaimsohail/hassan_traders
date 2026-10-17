class ActivityLogList < ListView
  ACTION_TONES = {
    "Created" => "pill-info", "Approved" => "pill-ok", "Received" => "pill-ok", "Payment received" => "pill-ok",
    "Dispatched" => "pill-info", "Issued" => "pill-info", "Edited" => "pill-warn", "Deleted" => "pill-bad",
    "Cancelled" => "pill-mute", "Reversed" => "pill-warn", "Logged in" => "pill-mute", "Login failed" => "pill-bad",
    "Downloaded PDF" => "pill-mute"
  }.freeze
  FLAGGED = [ "Deleted", "Login failed" ].freeze

  self.title = "Activity log"
  self.search_columns = %w[activity_logs.detail activity_logs.ref activity_logs.user_name]
  self.search_placeholder = "Search what happened, ref or person"
  self.date_column = "activity_logs.created_at"
  self.default_preset = "month"
  self.default_sort = [ :created_at, :desc ]
  self.pdf_landscape = true

  tab :all, "Everything"
  tab :attention, "Needs attention", ->(s) { s.where(action: ActivityLog::ATTENTION) }
  tab :money, "Money", ->(s) { s.where(section: %w[Payments Invoices]) }
  tab :stock, "Stock", ->(s) { s.where(section: %w[Stock Purchase]) }

  select :person, "Person", all_label: "Everyone", column: :user_name
  select :section, "Section", all_label: "All sections"
  select :event, "Action", all_label: "All actions", column: :action

  column :created_at, "When", sort: "activity_logs.created_at", format: :datetime, pdf_width: 13
  column :user_name, "Person", sort: "activity_logs.user_name", pdf_width: 13
  column :role, "Role", sort: "activity_logs.role", optional: true, pdf_width: 10
  column :action, "Action", sort: "activity_logs.action", format: :pill, tones: ACTION_TONES, pdf_width: 10
  column :section, "Section", sort: "activity_logs.section", optional: true
  column :ref, "Ref", sort: "activity_logs.ref", pdf_width: 8
  column :detail, "What happened", pdf_width: 34
  column :device, "Device", optional: true, pdf_width: 12

  def flagged?(row) = FLAGGED.include?(row.action)

  def totals
    [
      [ "Entries", Fmt.lakh(scope.count) ],
      [ "People", Fmt.lakh(scope.distinct.count(:user_name)) ],
      [ "Needs attention", Fmt.lakh(scope.where(action: ActivityLog::ATTENTION).count), :warn ]
    ]
  end
end
