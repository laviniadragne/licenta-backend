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

    # Setări pentru criptare deterministă
    CIPHER = OpenSSL::Cipher.new('aes-256-ecb')
    SECRET_KEY = Rails.application.secret_key_base.byteslice(0, 32)

    # Criptare deterministă
    def encrypt(value)
      CIPHER.encrypt
      CIPHER.key = SECRET_KEY
      encrypted_data = CIPHER.update(value.to_s) + CIPHER.final
      Base64.encode64(encrypted_data)
    end

    # Decriptare
    def decrypt(value)
      return if value.blank?
  
      CIPHER.decrypt
      CIPHER.key = SECRET_KEY
      encrypted_data = Base64.decode64(value) # Decodifică din Base64
      CIPHER.update(encrypted_data) + CIPHER.final
    rescue OpenSSL::Cipher::CipherError
      nil
    end

    # Criptarea câmpurilor sensibile
    def encrypt_sensitive_data
      self.name = encrypt(name)
      self.cui = encrypt(cui)
    end

    def decrypt_sensitive_data
      self.name = decrypt(name)
      self.cui = decrypt(cui)
    end
  end
  
