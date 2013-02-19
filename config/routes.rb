# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  mount GitWit::Engine => "/"
  resources :public_keys, except: [:edit, :update]
  resources :post_receive_hooks, except: [:index, :new, :create]
  scope "/projects/:project_id/repository/:repository_id" do
    resources :post_receive_hooks, only: [:index, :new, :create] do
      put "run", on: :collection
    end
  end
end