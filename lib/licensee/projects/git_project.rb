# Git-based project
#
# Analyze a given (bare) Git repository for license information
module Licensee
  class GitProject < Project
    attr_reader :repository, :revision

    class InvalidRepository < ArgumentError; end

    def initialize(repo, revision: nil, **args)
      @repository = if repo.is_a? Rugged::Repository
        repo
      else
        Rugged::Repository.new(repo)
      end

      @revision = revision
      super(**args)
    rescue Rugged::OSError, Rugged::RepositoryError
      raise InvalidRepository
    end

    def close
      @repository.close
    end

    private

    def commit
      @commit ||= if revision
        repository.lookup(revision)
      else
        repository.last_commit
      end
    end

    MAX_LICENSE_SIZE = 64 * 1024

    def load_blob_data(oid)
      data, = Rugged::Blob.to_buffer(repository, oid, MAX_LICENSE_SIZE)
      data
    end

    def find_file
      files = commit.tree.map do |entry|
        next unless entry[:type] == :blob
        if (score = yield entry[:name]) > 0
          { name: entry[:name], oid: entry[:oid], score: score }
        end
      end.compact

      return if files.empty?
      files.sort! { |a, b| b[:score] <=> a[:score] }

      f = files.first
      [load_blob_data(f[:oid]), f[:name]]
    end
  end
end
