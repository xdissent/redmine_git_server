class PostReceiveHook::Payload

  include ActionDispatch::Routing::UrlFor
  include Rails.application.routes.url_helpers

  attr_accessor :repository, :before, :after, :ref, :project

  def self.parse_refs(repository, refs)
    refs.split("\n").map do |line| 
      before, after, ref = line.to_s.chomp.split " "
      if valid_ref?(ref) && valid_after?(after)
        self.new repository, before, after, ref
      end
    end.compact
  end

  def self.valid_ref?(ref)
    ref.match(/refs\/heads\//).present?
  end

  def self.valid_after?(after)
    !after.match(/^0{40}$/).present?
  end

  def initialize(repository, before, after, ref)
    self.repository = repository
    self.before = before
    self.after = after
    self.ref = ref
    self.project = repository.project
  end

  def to_hash
    @hash ||= {
      before: before,
      after: after,
      ref: ref,
      commits: commits,
      repository: {
        id: repository.id,
        description: project.description,
        fork: false,
        forks: 0,
        master_branch: repository.default_branch,
        homepage: project.homepage,
        name: project.identifier,
        open_issues: project.issues.open.length,
        owner: {
          name: Setting.app_title,
          email: Setting.mail_from
        },
        private: !project.is_public?,
        url: repository_url,
        watchers: project.members.count
      }
    }
  end

  private
  def commits
    # New branch, check from HEAD
    before_rev = before.match(/^0{40}$/) ? "HEAD" : before
    repository.scm.revisions(nil, before_rev, after, reverse: true).map do |rev|
      commit_for_revision(rev)
    end
  end

  def commit_for_revision(revision)
    changes = changes_for_revision(revision)
    {
      id: revision.identifier,
      url: revision_url(revision),
      author: {
        name: revision_author_name(revision),
        email: revision_author_email(revision),
        username: repository.find_committer_user(revision.author)
      },
      message: revision.message,
      timestamp: revision.time,
      added: changes["A"] || [],
      modified: changes["M"] || [],
      removed: changes["D"] || []
    }
  end

  def revision_author_name(revision)
    revision.author.gsub /^([^<]+)\s+.*$/, '\1'
  end

  def revision_author_email(revision)
    revision.author.gsub /^.*<([^>]+)>.*$/, '\1'
  end

  def changes_for_revision(revision)
    revision.paths.map { |p| [p[:action], p[:path]] }.inject({}) do |h, k| 
      h[k[0]] ||= []
      h[k[0]] << k[1]
      h
    end
  end

  def repository_url
    url_for controller: "repositories", action: "show", 
      id: project, only_path: false, 
      host: Setting.host_name, protocol: Setting.protocol
  end

  def revision_url(revision)
    url_for controller: "repositories", action: "revision", 
      id: project, rev: revision.identifier, only_path: false, 
      host: Setting.host_name, protocol: Setting.protocol
  end
end