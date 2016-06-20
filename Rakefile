def run(command, min_exit_status = 0)
  puts "Executing: `#{command}`"
  system(command)
  return $?.exitstatus
end

desc "Install dependencies"
task :dependencies do
  run("gem install github_changelog_generator")
end

desc "Generate changelog"
task :changelog => [:dependencies] do
  run("github_changelog_generator -u LocativeHQ -p ios-app")
end
