set IMG=registry.gitlab.com/mazoea-team/docker-ci-build:u14g8
docker pull %IMG%

pushd ..
docker run --rm -it -e TE_LIBS=/opt/mazoea/installation -e GCCVERSION=8 -e CPU_NATIVE=false -v %cd%:/te %IMG% /bin/bash -c "cd /te/scripts && ./os.specific.sh && ./build.sh"
popd

IF "%1"=="nopause" GOTO No1
    echo %~n0
    pause
:No1
