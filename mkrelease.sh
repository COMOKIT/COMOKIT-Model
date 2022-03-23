#!/bin/sh

# Exit when any command fail
set -e

usage () {
    echo "./build --platform Linux/Win/Mac [--gama <gamatag>]  [--release]"
}

info () {
    echo "[INFO] $@"
}

####

OPTIONS="release,help,platform:,gama:"
PARSED=$(getopt -o "" -l $OPTIONS -u -- "$@")
set -- $PARSED

gama="1.8.2"
platform=""
release=

while ! [ -z $1 ]; do
    case $1 in
        --help)
            usage
            exit 2
            ;;
        --gama)
            gama="$2"
            shift 2
            ;;
        --platform)
            if [ $2 != "Linux" ] && [ $2 != "Win" ] && [ $2 != "Mac" ]; then
                echo "Invalid platform \"$2\" >:("
                usage
                exit 2
            fi
            platform="$2"
            shift 2
            ;;
        --release)
            release=1
            shift 1
            ;;
        --)
            shift 1;
            break;
            ;;
        *)
            shift 1
            ;;
    esac
done

info "GAMA version: $gama"
info "Platform: $platform"
info "Release: $release"

echo "=============== $platform build ==============="

# Download GAMA
GAMA=$(curl -s https://api.github.com/repos/gama-platform/gama/releases/tags/$gama | grep "with_JDK" | grep $platform | grep https | grep zip | cut -d ':' -f 2,3 | tr -d \")
info "Downloading GAMA from:"
info "GAMA: $GAMA"
curl -o gama-$platform.zip -fSL $GAMA
unzip gama-$platform.zip -d ./GAMA

info "Adding COMOKIT Model"
modeljar=$(find ./GAMA -name 'msi.gama.models*' | sed 's/\n//g' | sed 's/\r//g')
info "Model JAR: $modeljar"
mv "$modeljar" model.zip
unzip model.zip -d ./models
cp -r COMOKIT ./models/models/
cp -r "COMOKIT Template Project" ./models/models/
cd models
zip -r --symlinks ../$modeljar .
cd ..

# Fix GAMA plugins security
jarsize=$(ls -l $modeljar | cut -d " " -f5)
if [ $platform = Mac ]; then
    artifactfile="./GAMA/Gama.app/Contents/Eclipse/artifacts.xml"
else
    artifactfile="./GAMA/artifacts.xml"
fi
sed -i "/<artifact classifier='osgi.bundle' id='msi.gama.models'/,/<\/artifact>/ s/<property name.*/<property name='download.size' value='$jarsize'\/>/g;" "$artifactfile"

# Prepare release
info "Preparing release"
if [ $platform = Mac ]; then
    zip -r -q --symlinks "./COMOKIT-$platform.zip" ./GAMA/Gama.app
else
    zip -r -q --symlinks ./COMOKIT-$platform.zip ./GAMA
fi

# Clean GAMA version
info "Cleaning up"
rm -fr ./GAMA ./models.zip ./models

info "Done"
