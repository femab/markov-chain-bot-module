require 'yaml'
require 'strscan'

# ---- Properties ----

BUILD_DIR = "build"
PEG2RB = "#{BUILD_DIR}/peg2rb.rb"

# ---- Utilities (part 1) ----

class FileList
  
  include Rake::DSL
  
  # Example:
  #   
  #   FileList["*.cpp"].to { |x| x.ext(".o") }.doing do |cpp, obj|
  #     sh "gcc -o #{obj} -c #{cpp}"
  #   end
  #
  def to(&rename_func)
    self.map do |src_file|
      [src_file, rename_func.(src_file)]
    end
  end
  
  def doing(&action)
    self.map do |src_and_dest_file|
      src_file, dest_file = *src_and_dest_file
      file dest_file => src_file do
        action.(src_file, dest_file)
      end
      dest_file
    end
  end
  
end

# ---- Build ----

GEM_FILES =
  FileList["*.rb"].to { |f| "#{BUILD_DIR}/lib/#{f}" }.doing do |src_file, dest_file|
    cp_p src_file, dest_file
  end +
  FileList["*.peg"].to { |f| "#{BUILD_DIR}/lib/#{f.ext(".rb")}" }.doing do |src_file, dest_file|
    peg2rb src_file, dest_file
  end +
  FileList["README.md"].to { |_| "#{BUILD_DIR}/README" }.doing do |src_file, dest_file|
    File.translate src_file, dest_file do |content|
      content.exclude_or_warning("<!-- exclude from gem -->", "<!-- end -->") do |b, e|
        %(WARNING: no #{b}...#{e} is found in #{src_file})
      end.
      markdown_sections.map do |section|
        "#{"=" * (section.depth + 1)} #{section.name}\n\n#{section.content}\n\n"
      end.join.
      gsub(/^    /, "  ")
    end
  end

GEMSPEC_FILES =
  FileList["README.md"].to { |_| "#{BUILD_DIR}/gemspec" }.doing do |src_file, dest_file|
    src_file_sections =
      File.read(src_file).markdown_sections
    misc_section =
      src_file_sections.find { |section| section.name = "Miscellaneous" } or raise %(section "Credits" must be present in #{src_file})
    misc =
      begin YAML.load(credits.content).which_must_be(Hash) rescue raise %(section "Credits" of "#{src_file}" must be YAML map) end
    misc_get = lambda do |key|
      misc[key] or raise %("#{key}" is not found in section "Credits" of "#{src_file}")
    end
    File.write dest_file, <<-GEMSPEC
      Gem::Specification.new do |s|
        s.name        = #{misc_get["Gem name"].to_rb}
        s.version     = #{misc_get["Version"].to_rb}
        s.licenses    = #{[misc_get["License"]].to_rb}
        s.summary     = #{src_file_sections.first.name.to_rb}
        s.description = #{src_file_sections.first.content.to_rb}
        s.authors     = #{misc_get["Authors"].split(/\s*,\s*/).to_rb}
        s.email       = #{misc_get["E-mail"].to_rb}
        s.files       = #{GEM_FILES.to_a.to_rb}
        s.homepage    = #{misc_get["Homepage"].to_rb}
      end
    GEMSPEC
  end

task :gem => (GEM_FILES + GEMSPEC_FILES) do
  sh "gem build #{GEMSPEC_FILES.join(" ")}"
end

task :all => [:gem]

task :default => :all

task :clean do
  (FileList["#{BUILD_DIR}/*"] - FileList[PEG2RB]).each do |entry|
    rm_r entry
  end
end

# ---- Utilities (part 2) ----

class File
  
  # reads +src_file+, processes it with +src_content_func+ and writes the result
  # to +dest_file+.
  def self.translate(src_file, dest_file, &src_content_func)
    File.write(dest_file, src_content_func.(File.read(src_file)))
  end
  
end

class Object
  
  def which_must_be x
    raise %(#{self} is not #{x}) unless self.is_a? x
    return self
  end
  
  # Ruby code representing this Object.
  def to_rb
    inspect
  end
  
end

class String
  
  # MarkdownSection-s of this MarkdownText
  def markdown_sections
    s = StringScanner.new(self)
    result = [MarkdownSection.new(nil, 0, "")]
    until s.eos?
      pos = s.pos
      (s.pos = pos and name = s.scan(/.*\n/) and s.scan(/^\=+\n/) and
        result << MarkdownSection.new(name.strip, 0, "")) or
      (s.pos = pos and name = s.scan(/.*\n/) and s.scan(/^\-+\n/) and
        result << MarkdownSection.new(name.strip, 1, "")) or
      (s.pos = pos and depth_str = s.scan(/#+/) and s.scan(/\s*/) and name = s.scan(/.*\n/) and
        result << MarkdownSection.new(name.strip, depth_str.length, "")) or
      (s.pos = pos and content = s.scan(/.*\n?/) and
        result.last.content << content.strip)
    end
    result.drop(1)
  end
  
  # removes everything between +start_string+ and +end_string+ (including) from
  # this String or displays a warning if such parts are not found. Warning is
  # a result of +warning_func+ which is passed with +start_string+ and
  # +end_string+.
  def exclude_or_warning(start_string, end_string, &warning_func)
    exclusion_regexp = Regexp.new(
      Regexp.escape(start_string) + ".*?" + Regexp.escape(end_string),
      Regexp::MULTILINE
    )
    STDERR.puts warning_func.(start_string, end_string) unless
      exclusion_regexp === self
    return self.gsub(exclusion_regexp, "")
  end
  
  class MarkdownSection < Struct.new(:name, :depth, :content); end
  
end

def peg2rb src_file, dest_file
  mkdir_p File.dirname(dest_file)
  retries = 0
  begin
    sh "ruby #{PEG2RB} #{src_file} > #{dest_file}"
  rescue
    case retries
    when 0
      STDERR.puts %(It looks like "#{PEG2RB}" is not present. I will try to download it for you.)
      sh "wget -O#{PEG2RB} https://raw.githubusercontent.com/LavirtheWhiolet/self-bootstrap/master/peg2rb.rb"
      retries += 1
      retry
    else
      raise %("#{PEG2RB}" is not present)
    end
  end
end

# The same as #cp() but creates destination directory if it does not exist.
def cp_p source_file, dest_file
  mkdir_p File.dirname(dest_file)
  cp source_file, dest_file
end
