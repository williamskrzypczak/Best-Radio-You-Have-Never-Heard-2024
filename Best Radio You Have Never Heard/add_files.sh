#!/bin/bash

# Create a temporary project.pbxproj file
cat > temp.pbxproj << 'EOL'
// !$*UTF8*$!
{
    archiveVersion = 1;
    classes = {
    };
    objectVersion = 56;
    objects = {
        /* Begin PBXBuildFile section */
        /* End PBXBuildFile section */
        
        /* Begin PBXFileReference section */
        /* End PBXFileReference section */
        
        /* Begin PBXFrameworksBuildPhase section */
        /* End PBXFrameworksBuildPhase section */
        
        /* Begin PBXGroup section */
        /* End PBXGroup section */
        
        /* Begin PBXNativeTarget section */
        /* End PBXNativeTarget section */
        
        /* Begin PBXProject section */
        /* End PBXProject section */
        
        /* Begin PBXResourcesBuildPhase section */
        /* End PBXResourcesBuildPhase section */
        
        /* Begin PBXSourcesBuildPhase section */
        /* End PBXSourcesBuildPhase section */
        
        /* Begin XCBuildConfiguration section */
        /* End XCBuildConfiguration section */
        
        /* Begin XCConfigurationList section */
        /* End XCConfigurationList section */
    };
    rootObject = PROJECT_ROOT_OBJECT /* Project object */;
}
EOL

# Add the files to the project
echo "Adding files to Xcode project..."
echo "Please add these files manually in Xcode:"
echo "1. Models/Models.swift"
echo "2. Utilities/StringExtensions.swift"
echo "3. Views/AirPlayButtonView.swift"
echo "4. Views/SearchableListView.swift"
echo "5. Views/EpisodeRow.swift"
echo "6. Views/DetailView.swift"
echo ""
echo "Steps:"
echo "1. In Xcode, select your project in the navigator"
echo "2. Select your target"
echo "3. Go to 'Build Phases'"
echo "4. Expand 'Compile Sources'"
echo "5. Click the '+' button"
echo "6. Click 'Add Other...'"
echo "7. Click 'Add Files...'"
echo "8. Select all the files listed above"
echo "9. Make sure 'Copy items if needed' is UNCHECKED"
echo "10. Click 'Add'" 