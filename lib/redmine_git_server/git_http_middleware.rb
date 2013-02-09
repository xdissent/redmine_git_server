require "rack/auth/basic"

module RedmineGitServer
  class GitHttpMiddleware < Rack::Auth::Basic

    def initialize(app)
      super app, conf(:realm), &method(:authorize)
    end

    def call(env)
      @env = env
      return @app.call env unless repository_exists?

      auth = Rack::Auth::Basic::Request.new(@env)
      if auth.provided?
        return bad_request unless auth.basic?
        return unauthorized unless valid?(auth) # Sets @user
      else
        @user = User.anonymous
      end

      run_gitolite_shell
    end

    def run_gitolite_shell
      status, headers, body = 200, {}, nil

      IO.popen(command, File::RDWR) do |io|
        IO.copy_stream @env["rack.input"], io
        io.close_write
        until io.eof? || (line = io.readline.chomp) == ''
          k, v = line.split(/\s*\:\s*/, 2)
          headers[k] = headers.key?(k) ? "#{headers[k]}\n#{v}" : v
        end
        body = io.read
      end

      return git_error_response unless $?.success?

      status = headers.delete("Status").to_i if headers.key? "Status"
      [status, headers, [body]]
    rescue
      git_error_response
    end

    def authorize(username, password)
      @user = User.try_to_login(username, password)
    end

    def repo_url
      @env["PATH_INFO"].match(/^\/([-\/\w\.]+\.git)\//) { |m| m[1] }
    end

    def repository_exists?
      Repository::GitServer.find_by_url(repo_url).present?
    end

    def env_vars
      env_keys = %w{PATH_INFO REQUEST_METHOD SCRIPT_NAME SERVER_NAME SERVER_PORT QUERY_STRING}
      extras = {
        REMOTE_USER: @user.anonymous? ? conf(:anonymous_user) : @user.login,
        GIT_HTTP_EXPORT_ALL: "doit", 
        GITOLITE_HTTP_HOME: conf(:home), 
        GIT_PROJECT_ROOT: conf(:repositories),
        REQUEST_URI: @env["PATH_INFO"]
      }
      vars = @env.select { |k, v| env_keys.include?(k) || k.start_with?("HTTP_") }
      vars.merge(extras).map { |k, v| "#{k}=#{v}" }
    end

    def sudo
      %W{sudo -u #{conf(:user)} -i}
    end

    def command
      [*sudo, *env_vars, conf(:gitolite_shell)]
    end

    def conf(k)
      RedmineGitServer.config.send k.to_sym
    end

    def git_error_response
      [500, {"Content-Type" => "text/plain"}, ["Redmine Git Server Error"]]
    end
  end
end