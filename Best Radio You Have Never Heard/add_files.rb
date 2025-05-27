#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'BRYHNH2.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Files to add
files_to_add = [
  'Best Radio You Have Never Heard/Models/Models.swift',
  'Best Radio You Have Never Heard/Utilities/StringExtensions.swift',
  'Best Radio You Have Never Heard/Views/AirPlayButtonView.swift',
  'Best Radio You Have Never Heard/Views/SearchableListView.swift',
  'Best Radio You Have Never Heard/Views/EpisodeRow.swift',
  'Best Radio You Have Never Heard/Views/DetailView.swift'
]

# Add each file
files_to_add.each do |file_path|
  # Create a file reference
  file_ref = project.new_file(file_path)
  
  # Add the file to the target
  target.add_file_references([file_ref])
end

# Save the project
project.save 