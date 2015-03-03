class UpdateTagPermissions < ActiveRecord::Migration
  def change
    Permission.where(subject_class: 'Tag').update_all('action=action || \'_tag\', subject_class=\'AttachedAsset\'')
  end
end
