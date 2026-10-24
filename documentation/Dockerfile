FROM pandoc/latex:3.11

USER root
RUN export PATH=/opt/texlive/texdir/bin/x86_64-linuxmusl:$PATH && \
    tlmgr update --self && \
    tlmgr install fvextra
