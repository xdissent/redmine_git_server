
require File.expand_path('../../../test_helper', __FILE__)

class Repository::GitServerTest < ActiveSupport::TestCase
  fixtures :projects, :repositories, :enabled_modules, :users, :roles

  context "git server repository" do
    setup do
      Setting.enabled_scm << "GitServer"
      p = Project.find(4)
      p.enabled_module_names += ["repository"]
      extra = {"extra_url_format" => "flat"}
      @repo = Repository::GitServer.create url: "#{p.identifier}.git", project: p, extra_info: extra
    end

    should "validate the git server scm is available for new records" do
      Setting.enabled_scm = ["Bazaar", "Git"]

      repo = Repository::GitServer.new identifier: "foo", project: @repo.project, extra_info: @repo.extra_info
      repo.url = repo.calculate_url
      
      assert !repo.valid?
      assert_equal 1, repo.errors.keys.length
      assert_equal :type, repo.errors.keys.first

      Setting.enabled_scm << "GitServer"
      assert repo.valid?
    end

    should "validate url uniqueness" do
      extra = {"extra_url_format" => "custom"}
      repo = Repository::GitServer.new identifier: "foo", url: @repo.url, project: @repo.project, extra_info: extra

      assert !repo.valid?
      assert_equal 1, repo.errors.keys.length
      assert_equal :url, repo.errors.keys.first

      repo.url = "foo/bar.git"
      repo.url_format = "custom"
      assert repo.valid?
    end

    should "use the default url format from settings unless set explicitly" do
      repo = Repository::GitServer.new url: "foo.git", project: Project.first
      assert_equal Setting.plugin_redmine_git_server["default_url_format"], repo.url_format

      repo.url_format = "flat"
      assert_equal "flat", repo.url_format
    end

    should "validate url_format is available" do
      @repo.url_format = "fake"
      assert !@repo.valid?
      assert_equal 1, @repo.errors.keys.length
      assert_equal :extra_url_format, @repo.errors.keys.first
    end

    should "validate matches url_format for new records" do
      repo = Repository::GitServer.new identifier: "another", url: "fake.git", project: @repo.project, extra_info: @repo.extra_info

      assert !repo.valid?
      assert_equal 1, repo.errors.keys.length
      assert_equal :url, repo.errors.keys.first

      repo.url_format = "custom"
      assert repo.valid?

      repo.url_format = "flat"
      repo.url = "#{repo.project.identifier}/#{repo.identifier}.git"

      assert repo.valid?

      @repo.url = "changed.git"
      assert @repo.valid?
    end
  end
end
