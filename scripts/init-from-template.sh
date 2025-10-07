#!/bin/bash

# Initialize a new repo from the railway-monorepo-poc template
# This script updates all references to the template name with your new repo name

echo "🚀 Initialize New Repo from Template"
echo "======================================"
echo ""

# Get the new repo name
read -p "Enter your new repo name: " REPO_NAME

if [ -z "$REPO_NAME" ]; then
  echo "❌ Error: Repo name cannot be empty"
  exit 1
fi

# Convert to package.json format (lowercase, spaces to dashes)
PKG_NAME=$(echo "$REPO_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

echo ""
echo "Display name: $REPO_NAME"
echo "Package name: $PKG_NAME"
echo ""

# Update root package.json
if [ -f "package.json" ]; then
  sed -i '' "s/\"name\": \"railway-monorepo-poc\"/\"name\": \"$PKG_NAME\"/" package.json
  echo "✅ Updated package.json"
fi

# Update App.jsx
if [ -f "client/src/App.jsx" ]; then
  sed -i '' "s/Railway Monorepo PoC/$REPO_NAME/g" client/src/App.jsx
  echo "✅ Updated client/src/App.jsx"
fi

echo ""
echo "🎉 Template initialization complete!"
echo ""
echo "Next steps:"
echo "1. Review the changes"
echo "2. Run 'npm run init' to install dependencies"
echo "3. Follow the README for local development or Railway deployment"
