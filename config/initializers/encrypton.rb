key = ActiveSupport::KeyGenerator.new(Rails.application.credentials.secret_key_base).generate_key('salt', 32)
ENCRYPTOR = ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-ecb')