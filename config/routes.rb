# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  mount GitWit::Engine => "/"

  resources :public_keys, except: [:edit, :update]

  scope "/projects/:project_id/repository/:repository_id" do
    resources :post_receive_hooks
  end

  scope "/repositories/:repository_id" do
    resources :post_receive_hooks, only: [] do
      put "run", on: :collection
    end
  end
end