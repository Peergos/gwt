#!/bin/sh
# Builds the SDK with ant and installs its jars as com.github.Peergos.gwt:<jar>:<tag>.
set -eu

TOOLS_COMMIT=a8f32ca7319a968711dc51470222b77f1cf70d72
ANT_VERSION=1.10.15
ANT_SHA512=d78427aff207592c024ff1552dc04f7b57065a195c42d398fcffe7a0145e8d00cd46786f5aa52e77ab0fdf81334f065eb8011eecd2b48f7228e97ff4cb20d16c

work="$(pwd)/.jitpack"
mkdir -p "$work"

curl -fsSLo "$work/ant.tar.gz" "https://archive.apache.org/dist/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz"
echo "$ANT_SHA512  $work/ant.tar.gz" | sha512sum -c -
tar -xzf "$work/ant.tar.gz" -C "$work"

git init -q "$work/tools"
git -C "$work/tools" fetch -q --depth 1 https://github.com/gwtproject/tools.git "$TOOLS_COMMIT"
git -C "$work/tools" checkout -q FETCH_HEAD

GWT_TOOLS="$work/tools" "$work/apache-ant-$ANT_VERSION/bin/ant" clean dist-dev -Dgwt.version="$VERSION"

for jar in gwt-user gwt-dev gwt-codeserver gwt-servlet gwt-servlet-deps; do
  mvn -B -q install:install-file -Dfile="build/lib/$jar.jar" -DgroupId="$GROUP.$ARTIFACT" \
      -DartifactId="$jar" -Dversion="$VERSION" -Dpackaging=jar -DgeneratePom=true
done

# JitPack publishes the poms it finds in the build directory in preference to ~/.m2, and GWT's
# templates and ant's bundled poms would otherwise stand in for the jars installed above.
rm -rf "$work"
find . -name "*pom*.xml" -delete
