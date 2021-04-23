set IMG=registry.gitlab.com/mazoea-team/docker-ci-build:u18g8
REM set BUILDTYPE=RELWITHDEBINFO
set BUILDTYPE=RELEASE

REM compile all deps again
REM CDN_USE=false

pushd ..
docker pull %IMG%
docker run --rm -it -e OUTPUTDIR=./bin-nix -e BUILD_TYPE=%BUILDTYPE% -v %cd%:/te %IMG% /bin/bash
popd

pause