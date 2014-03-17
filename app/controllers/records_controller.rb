class RecordsController < ApplicationController
  before_action :set_record, except: [:index]

  def index
    @records = Record.paginate(:page => params[:page])
  end

  def show
    preview = @record.diff_with_dpla
    if !preview['error']
      @field_diffs = preview['field_diffs']
      @ours = preview['records'][0]
      @theirs = preview['records'][1]
      @dpla_url = preview['dpla_url']
      # Placeholder - need to implement revision history feature
      @revision_history = []
    else
      @not_found = true
      flash[:notice] = "#{preview['error']}"
    end
  end

  # Todo: move to records controller
  def batch_records
    @records = Record.where(:import_batch_id => params[:id]).paginate(:page => import_batch_params[:page])
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_record
      @record = Record.find(record_params[:id])
    end

    def record_params
      params.permit(:import_batch_id, :id, :version_id)
    end
end
