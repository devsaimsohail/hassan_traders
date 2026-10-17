class ProductionIssuesController < ApplicationController
  BLANK_LINES = 5

  before_action { authorize :production_issue, :create? }

  def new
    @issue = ProductionIssue.new(company: Current.company, user: Current.user)
    @issue.lines = Array.new(BLANK_LINES) { {} }
  end

  def create
    @issue = ProductionIssue.new(company: Current.company, user: Current.user, **issue_params.except(:lines_attributes))
    @issue.lines_attributes = issue_params[:lines_attributes] || {}

    if @issue.save
      redirect_to stock_moves_path(q: @issue.slip_no, preset: "all"), notice: "Issued to production on slip #{@issue.slip_no}. Stock is updated."
    else
      @issue.lines = @issue.lines + Array.new([ BLANK_LINES - @issue.lines.size, 0 ].max) { {} }
      render :new, status: :unprocessable_content
    end
  end

  private
    def issue_params
      params.require(:production_issue).permit(:date, :note, lines_attributes: [ :item_id, :qty ])
    end
end
