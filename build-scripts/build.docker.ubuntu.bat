cd ..
docker pull registry.gitlab.com/mazoea-team/docker-i2t-bits
docker run --rm -it -e TE_LIBS=/opt/mazoea/installation -e GCCVERSION=8 -v %cd%:/opt/src registry.gitlab.com/mazoea-team/docker-i2t-bits:latest /bin/bash -c "cd scripts && ./os.specific.sh && ./compile.sh"
pause