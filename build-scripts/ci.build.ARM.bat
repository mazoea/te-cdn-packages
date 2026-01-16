set IMG=ghcr.io/mazoea/docker-ci-build:al2023arm64
REM set BUILDTYPE=RELWITHDEBINFO
set BUILDTYPE=RELEASE

REM compile all deps again
REM CDN_USE=false

pushd "%~dp0.."
docker pull %IMG%
docker run --rm -it -w /te -e OUTPUTDIR=./bin-nix -e BUILD_TYPE=%BUILDTYPE% -v %cd%:/te --entrypoint /bin/bash %IMG% -c "cd scripts && ./ci/os.specific.sh && ./build.sh"
popd
