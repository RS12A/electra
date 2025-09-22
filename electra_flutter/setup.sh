#!/bin/bash

# Electra Flutter Setup Script
echo "🚀 Setting up Electra Flutter Development Environment"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Navigate to Flutter directory
cd electra_flutter

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Generate code
echo "🔄 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run analysis
echo "🔍 Running code analysis..."
flutter analyze

# Run tests
echo "🧪 Running tests..."
flutter test

# Create directories for assets
echo "📁 Creating asset directories..."
mkdir -p assets/{images,icons,logos,fonts}

echo "📱 Creating placeholder assets..."
# Create placeholder files
touch assets/images/kwasu_logo.png
touch assets/images/election_banner.png
touch assets/fonts/KWASU-Regular.ttf
touch assets/fonts/KWASU-Bold.ttf
touch assets/fonts/KWASU-Medium.ttf

# Display setup summary
echo ""
echo "🎉 Electra Flutter Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Add your KWASU assets to the assets/ directories"
echo "2. Update the API base URL in lib/shared/constants/app_constants.dart"
echo "3. Configure your backend server connection"
echo "4. Run 'flutter run' to start development"
echo ""
echo "📚 Useful Commands:"
echo "  flutter run                 # Run the app in debug mode"
echo "  flutter run --release      # Run in release mode"  
echo "  flutter test               # Run unit tests"
echo "  flutter analyze            # Run code analysis"
echo "  flutter build apk          # Build Android APK"
echo ""
echo "🔧 Development:"
echo "  flutter packages pub run build_runner watch   # Watch for code generation"
echo ""
echo "📖 Documentation: See README.md for detailed information"