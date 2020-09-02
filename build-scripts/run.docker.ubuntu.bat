REM test for GLIBC ` strings libleptonica1.so.1.78.0 | grep ^GLIBC_`
cd ..
docker pull registry.gitlab.com/mazoea-team/docker-i2t-bits:v8
docker run --rm -it -v %cd%:/opt/src registry.gitlab.com/mazoea-team/docker-i2t-bits:latest /bin/bash
pause