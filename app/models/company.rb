# == Schema Information
#
# Table name: companies
#
#  id         :bigint           not null, primary key
#  name       :string
#  cui        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  status     :integer          default("cerere")
#
class Company < ApplicationRecord
    has_many :company_users, dependent: :restrict_with_error
    has_many :users, through: :company_users
    has_many :documents, dependent: :restrict_with_error
  
    enum status: [:cerere, :aprobat, :refuzat]

    validates_uniqueness_of :name, :cui
  
    # Setare automată criptare/decriptare
    before_save :encrypt_sensitive_data
    after_find :decrypt_sensitive_data
  
    def serialize
      self.as_json(only: [:id, :name, :cui, :status])
    end
  
    private
  
    def encrypt_sensitive_data
      self.name = ENCRYPTOR.encrypt_and_sign(name)
      self.cui = ENCRYPTOR.encrypt_and_sign(cui)
    end
  
    def decrypt_sensitive_data
      self.name = ENCRYPTOR.decrypt_and_verify(name)
      self.cui = ENCRYPTOR.decrypt_and_verify(cui)
    rescue
      # În caz de eroare de decriptare (date vechi)
    end
  end
  
