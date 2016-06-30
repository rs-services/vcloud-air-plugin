require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe '#authenticate' do
    controller do
      def find
        render text: 'hello'
      end
    end
    before(:each) do
      routes.draw do
        get 'find' => 'anonymous#find'
      end
    end

    it 'can authenticate' do
      config = YAML.load_file("#{Rails.root}/config/vcloudair.yml")[Rails.env]
      secret = config['api-shared-secret']
      request.headers['X-Api-Shared-Secret'] = secret
      get :find, id: '1234'
      expect(response).to be_successful
      expect(response.status).to eq 200
    end

    it 'can not authenticate' do
      get :find, id: '1234'
      expect(response).to_not be_successful
      expect(response.status).to eq 403
    end
  end
end
