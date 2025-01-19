class RemoveMetadataFromDocuments < ActiveRecord::Migration[6.1]
  def change
    remove_column :documents, :metadata, :jsonb
  end
end
