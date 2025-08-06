#!/bin/bash

# Simple build script to replace tup functionality
set -e

echo "Building client assets..."

# Clean previous builds
rm -rf static/guides/*.json
rm -rf static/scss/*.css
rm -rf static/js/st/song_parser_peg.js
rm -rf static/js/st/staff_assets.jsx
rm -rf static/jasmine.js static/main.js static/main.js.map static/main.min.js
rm -rf static/service_worker.js static/service_worker.js.map static/service_worker.min.js
rm -rf static/specs.js static/specs.js.map
rm -rf static/specs.css static/style.css static/style.min.css

# Build SCSS files
echo "Compiling SCSS..."
for scss_file in static/scss/*.scss; do
    if [ -f "$scss_file" ]; then
        base_name=$(basename "$scss_file" .scss)
        sassc -I static/scss/ "$scss_file" "static/scss/${base_name}.css"
    fi
done

# Concatenate CSS files
echo "Concatenating CSS..."
cat static/scss/*.css > static/style.css 2>/dev/null || touch static/style.css
sassc -t compressed static/style.css static/style.min.css

# Generate PEG parser if needed
if [ -f "static/js/st/song_parser_peg.pegjs" ]; then
    echo "Generating PEG parser..."
    node_modules/.bin/pegjs -o static/js/st/song_parser_peg.js static/js/st/song_parser_peg.pegjs
fi

# Build JavaScript bundles
echo "Building JavaScript bundles..."
NODE_PATH=static/js node_modules/.bin/esbuild static/js/st/main.jsx \
    --log-level=warning \
    --bundle \
    --sourcemap \
    --jsx=automatic \
    --outfile=static/main.js

NODE_PATH=static/js node_modules/.bin/esbuild static/js/service_worker.js \
    --log-level=warning \
    --bundle \
    --sourcemap \
    --outfile=static/service_worker.js

# Minify JavaScript
echo "Minifying JavaScript..."
node_modules/.bin/esbuild --minify --target=es6 static/main.js \
    --log-level=error \
    --outfile=static/main.min.js

node_modules/.bin/esbuild --minify --target=es6 static/service_worker.js \
    --log-level=error \
    --outfile=static/service_worker.min.js

# Build Jasmine for specs
echo "Building Jasmine..."
cat node_modules/jasmine-core/lib/jasmine-core/jasmine.js \
    node_modules/jasmine-core/lib/jasmine-core/jasmine-html.js \
    node_modules/jasmine-core/lib/jasmine-core/boot.js > static/jasmine.js

cp node_modules/jasmine-core/lib/jasmine-core/jasmine.css static/specs.css

# Build specs
if [ -f "static/js/specs.js" ]; then
    NODE_PATH=static/js node_modules/.bin/esbuild static/js/specs.js \
        --log-level=warning \
        --bundle \
        --sourcemap \
        --external:static/main.js \
        --outfile=static/specs.js
fi

echo "Client build complete!"
