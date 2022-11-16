REM test for GLIBC ` strings libleptonica1.so.1.78.0 | grep ^GLIBC_`
cd ..
docker pull ghcr.io/mazoea/docker-i2t-bits:latest
docker run --rm -it -v %cd%:/opt/src ghcr.io/mazoea/docker-i2t-bits:latest /bin/bash
pause