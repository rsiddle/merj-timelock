require 'sinatra'
require 'openssl'
require 'base64'

class App < Sinatra::Base
  SECRET_KEY = '1234567890987654'
  TIME_FROM_NOW = 10 # seconds

  get '/generate' do
    @text = (Time.now.to_i + TIME_FROM_NOW).to_s
    @encrypted = Cipher.encrypt_base64(SECRET_KEY, @text)
    redirect url("/secret?t=#{@encrypted}")
  end

  get '/secret' do
    begin
      if !params[:t].nil? && params[:t] != ''
        @decrypted = Cipher.decrypt_base64(SECRET_KEY, params[:t])
        @time = Time.at(@decrypted.to_i)
        if @time > Time.now
          html = "This page will expire at: <%= @time.to_s %>.<br />\
                  The time now is: <%= Time.now %>.<br />\
                  This is the secret area!
                  "
          return erb(html)
        end
      end
    rescue OpenSSL::Cipher::CipherError
      # Captures bad cipher and moves on.
    end

    status 403
    html = "Content no longer exists. Generate a new key at <%= url('/generate') %>"
    erb(html)
  end
end

module Cipher
  def self.encrypt_base64(key, data)
    Base64.encode64(cipher(:encrypt, key, (data + '_')))
  end

  def self.decrypt_base64(key, base64_str)
    cipher(:decrypt, key, Base64.decode64(base64_str))[0...-1]
  end

  private

  def self.cipher(mode, key, data)
    cipher = OpenSSL::Cipher.new('bf-cbc').send(mode)
    cipher.key = key
    cipher.update(data) << cipher.final
  end
end

App.run!
