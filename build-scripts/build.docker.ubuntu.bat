cd ..
docker pull ghcr.io/mazoea/docker-i2t-bits
docker run --rm -it -e TE_LIBS=/opt/mazoea/installation -e GCCVERSION=8 -v %cd%:/opt/src ghcr.io/mazoea/docker-i2t-bits:latest /bin/bash -c "cd scripts && ./os.specific.sh && ./compile.sh"
pause