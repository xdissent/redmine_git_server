# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  mount GitWit::Engine => "/"
  resources :public_keys
  put "/post-receive/:repository_id" => "post_receive_hooks#run"
end