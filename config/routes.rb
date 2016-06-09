Rails.application.routes.draw do
  scope "/plugin" do
    post ':controller/:id/actions/stop', to: 'servers#stop'
    post ':controller/:id/actions/start', to: 'servers#start'
    post ':controller/:id/actions/power_on', to: 'servers#power_on'
    post ':controller/:id/actions/power_off', to: 'servers#power_off'

    resources :servers
  end
end
