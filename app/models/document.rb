class Document < ActiveRecord::Base
  belongs_to :documentable, :polymorphic => true
  has_attached_file :file, PAPERCLIP_SETTINGS
  attr_accessible :name, :file
end
