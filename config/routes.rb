Rails.application.routes.draw do
  scope "/plugin" do
    resources :servers
  end
end
