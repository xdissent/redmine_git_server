class PostReceiveHooksController < ApplicationController
  before_filter :check_enabled
  before_filter :find_repository
  before_filter :check_project

  skip_before_filter :verify_authenticity_token, :check_if_login_required

  def run
    @repository.fetch_changesets
    send_payloads
    render text: "Thanks for using Redmine Git Server\n", status: 200
  end

  private
  def check_enabled
    User.current = nil
    unless Setting.sys_api_enabled? && params[:key].to_s == Setting.sys_api_key
      msg = "Access denied. Repository management WS is disabled or key is invalid."
      render text: msg, status: 403
    end
  end

  def find_repository
    @repository = Repository::GitServer.find params[:repository_id]
  rescue ActiveRecord::RecordNotFound
    render nothing: true, status: 404
  end

  def check_project
    p = @repository.project
    unless p.present? && p.active? && p.module_enabled?(:repository)
      render nothing: true, status: 404
    end
  end

  def send_payloads
    Rails.logger.info "PAYLOADS: #{payloads}"
  end

  def payloads
    request.body.read.split("\n").map do |line| 
      oldhead, newhead, refname = line.to_s.chomp.split " "
      if valid_refname?(refname) && valid_newhead?(newhead)
        payload(oldhead, newhead, refname)
      end
    end.compact
  end

  def payload(oldhead, newhead, refname)
    {
      before: oldhead,
      after: newhead,
      ref: refname,
      commits: commits_between(oldhead, newhead),
      repository: {
        description: @repository.project.description,
        fork: false,
        forks: 0,
        homepage: @repository.project.homepage,
        name: @repository.project.identifier,
        open_issues: @repository.project.issues.open.length,
        owner: {
          name: Setting.app_title,
          email: Setting.mail_from
        },
        private: !@repository.project.is_public?,
        url: repository_url,
        watchers: 0
      }
    }
  end

  def repository_url
    url_for controller: "repositories", action: "show", 
      id: @repository.project, only_path: false, 
      host: Setting.host_name, protocol: Setting.protocol
  end

  def revision_url(revision)
    url_for controller: "repositories", action: "revision", 
      id: @repository.project, rev: revision.identifier, only_path: false, 
      host: Setting.host_name, protocol: Setting.protocol
  end

  def commits_between(oldhead, newhead)
    oldhead = "HEAD" if oldhead.match /^0{40}$/ # New branch, check from HEAD
    @repository.scm.revisions(nil, oldhead, newhead, reverse: true).map do |revision|
      commit_for_revision(revision)
    end
  end

  def changes_for_revision(revision)
    changes = {modified: [], added: [], removed: []}
    revision.paths.each do |change|
      if change[:action] == "M"
        changes[:modified] << change[:path]
      elsif change[:action] == "A"
        changes[:added] << change[:path]
      elsif change[:action] == "D"
        changes[:removed] << change[:path]
      end
    end
    changes
  end

  def commit_for_revision(revision)
    changes = changes_for_revision(revision)
    {
      id: revision.identifier,
      url: revision_url(revision),
      author: {
        name: revision.author.gsub(/^([^<]+)\s+.*$/, '\1'),
        email: revision.author.gsub(/^.*<([^>]+)>.*$/, '\1')
      },
      message: revision.message,
      timestamp: revision.time,
      added: changes[:added],
      modified: changes[:modified],
      removed: changes[:removed]
    }
  end

  def valid_refname?(refname)
    refname.match(/refs\/heads\//).present?
  end

  def valid_newhead?(newhead)
    !newhead.match(/^0{40}$/).present?
  end
end
