# == Schema Information
#
# Table name: list_exports
#
#  id                :integer          not null, primary key
#  list_class        :string(255)
#  params            :string(255)
#  export_format     :string(255)
#  aasm_state        :string(255)
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  user_id           :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class ListExport < ActiveRecord::Base
  belongs_to :user
  attr_accessible :list_class, :params, :export_format

  serialize :params

  include AASM

  aasm do
    state :new, :initial => true
    state :queued, before_enter: :queue_process
    state :processing, after_enter: :export_list
    state :completed

    event :queue do
      transitions :from => [:new, :complete], :to => :queued
    end

    event :process do
      transitions :from => [:queued, :new], :to => :processing
    end

    event :complete do
      transitions :from => :processing, :to => :completed
    end
  end

  def queue_process
    Resque.enqueue(ListExportWorker, self.id)
  end

  def download_url(style_name=:original)
    'url'
  end

  def export_list
    @solr_search = self.list_class.constantize.do_search(self.params)
    @collection_count = @solr_search.total
    @total_pages = @solr_search.results.total_pages
    @collection_results = @solr_search.results

    ApplicationController.new.render_to_string(:template => "results/event_data/index", :handlers => [:axlsx], :formats => [:xlsx], :layout => false)

    # Mark download as completed
    self.complete!
  end
end
