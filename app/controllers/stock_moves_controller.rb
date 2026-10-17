class StockMovesController < ApplicationController
  include ListPdfDownload

  def index
    authorize Item, :index?
    @list = StockMoveList.new(StockMoveList.base(Current.company), params)

    respond_to do |format|
      format.html
      format.pdf { send_list_pdf(@list) }
    end
  end
end
