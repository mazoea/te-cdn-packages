set IMG=ghcr.io/mazoea/docker-ci-build:u22g12
REM set BUILDTYPE=RELWITHDEBINFO
set BUILDTYPE=RELEASE

REM compile all deps again
REM CDN_USE=false

pushd ..
docker pull %IMG%
docker run --rm -it -e OUTPUTDIR=./bin-nix -e BUILD_TYPE=%BUILDTYPE% -v %cd%:/te %IMG% /bin/bash -c "cd scripts && ./ci/os.specific.sh && ./build.sh"
popd

pause
