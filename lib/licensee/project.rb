require 'rugged'

module Licensee
  class Project
    attr_reader :detect_readme, :detect_packages
    alias detect_readme? detect_readme
    alias detect_packages? detect_packages

    def initialize(detect_packages: false, detect_readme: false)
      @detect_packages = detect_packages
      @detect_readme = detect_readme
    end

    # Returns the matching License instance if a license can be detected
    def license
      @license ||= matched_file && matched_file.license
    end

    def matched_file
      @matched_file ||= (license_file || readme || package_file)
    end

    def license_file
      return @license_file if defined? @license_file
      @license_file = begin
        content, name = find_file { |n| LicenseFile.name_score(n) }
        LicenseFile.new(content, name) if content && name
      end
    end

    def readme
      return unless detect_readme?
      return @readme if defined? @readme
      @readme = begin
        content, name = find_file { |n| Readme.name_score(n) }
        content = Readme.license_content(content)
        Readme.new(content, name) if content && name
      end
    end

    def package_file
      return unless detect_packages?
      return @package_file if defined? @package_file
      @package_file = begin
        content, name = find_file { |n| PackageInfo.name_score(n) }
        PackageInfo.new(content, name) if content && name
      end
    end
  end
end
