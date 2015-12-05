#!/bin/bash

if [ ! -d /data ] ; then
  echo "usage: docker run -it --rm -v <rpmbuild-dir>:/data -v <repo-dir>:/data/REPO grossws/makerpm pkg1.spec|pkg1.src.rpm pkg2.spec|pkg2.src.rpm ..."
  echo "  \`rpmbuild-dir\` should contain at least SPECS dir with specs mentioned"
  echo "  if some local SOURCES are required for building rpm they should be present in /data/SOURCES"
  exit 1
fi

set -e

BASE=/data
RPMB=/makerpm/rpmbuild

cd /makerpm

cleantree() {
  rm -rf ${RPMB}
  su - makerpm -c 'rpmdev-setuptree'
}
cleantree

# internal repo
REPO_ID=centos/6
REPO=/makerpm/repo/${REPO_ID}/$(uname -m)
mkdir -p ${REPO}
createrepo ${REPO}

echo <<EOF > /etc/yum.repos.d/makerpm.repo
[makerpm]
name = makerpm local repo
baseurl = file://${REPO}
enabled = 1 
protect = 0 
gpgcheck = 0
EOF

# output dirs
OUT=${BASE}/REPO/${REPO_ID}
OUT_RPMS=${OUT}/$(uname -m)
OUT_SRPMS=${OUT}/SRPMS
mkdir -p ${OUT_RPMS}
mkdir -p ${OUT_SRPMS}

buildspec() {
  spec=$1

  echo "Copy spec and sources"
  cp -f ${BASE}/SPECS/${spec} ${RPMB}/SPECS/

  if [ -d ${BASE}/SOURCES ] ; then
    cp -rf ${BASE}/SOURCES/* ${RPMB}/SOURCES/
  fi

  chown -R makerpm:users ~makerpm

  echo "Building ${spec}"
  su - makerpm -c "spectool -g -R rpmbuild/SPECS/${spec}"
  yum-builddep -y rpmbuild/SPECS/${spec}
  su - makerpm -c "rpmbuild -ba rpmbuild/SPECS/${spec}"
  echo "Finished building ${spec}"
}

buildsrpm() {
  srpm=$1
  
  echo "Building ${srpm}"
  yum-builddep -y ${BASE}/${srpm}
  su - makerpm -c "rpmbuild --rebuild ${BASE}/${srpm}"
  echo "Finished building ${srpm}"
}

for pkg in "$@" ; do
  if [[ "$pkg" == *.src.rpm ]] ; then
    buildsrpm "$pkg"
  elif [[ "$pkg" == *.spec ]] ; then
    buildspec "${pkg##*/}"
  else
    echo "Unknown package type: $pkg"
    exit 1
  fi

  echo "Copy rpms and srpms"
  find ${RPMB}/RPMS/ -name '*.rpm' -print0 | xargs -0 -r cp -vft ${OUT_RPMS}/
  find ${RPMB}/SRPMS/ -name '*.rpm' -print0 | xargs -0 -r cp -vft ${OUT_SRPMS}/

  echo "Rebuild makerpm repo"
  find ${RPMB}/RPMS/ -name '*.rpm' -print0 | xargs -0 -r cp -ft ${REPO}/
  createrepo ${REPO}

  cleantree
done

echo "Making repo in ${OUT_RPMS} and ${OUT_SRPMS}"
createrepo ${OUT_RPMS}
createrepo ${OUT_SRPMS}

echo "Done"

