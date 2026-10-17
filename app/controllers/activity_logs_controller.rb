class ActivityLogsController < ApplicationController
  include ListPdfDownload

  def index
    authorize ActivityLog
    @list = ActivityLogList.new(Current.company.activity_logs, params)

    respond_to do |format|
      format.html
      format.pdf { send_list_pdf(@list) }
    end
  end
end
