#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'Best Radio You Have Never Heard.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Remove all files from the "2" directories
target.build_phases.each do |build_phase|
  if build_phase.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase)
    build_phase.files.each do |build_file|
      if build_file.file_ref.real_path.to_s.include?(' 2/')
        build_phase.remove_build_file(build_file)
      end
    end
  end
end

# Add the correct files
files_to_add = [
  'Models/Models.swift',
  'Utilities/StringExtensions.swift',
  'Views/AirPlayButtonView.swift',
  'Views/SearchableListView.swift',
  'Views/EpisodeRow.swift',
  'Views/DetailView.swift'
]

files_to_add.each do |file_path|
  # Create a file reference
  file_ref = project.new_file(file_path)
  
  # Add the file to the target
  target.add_file_references([file_ref])
end

# Save the project
project.save 