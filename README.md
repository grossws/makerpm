# Info

[Dockerfiles][df] with RPM build environment for [CentOS][centos] 6 and 7.
Used for automated builds on [docker hub][dhub].

Both spec files and SRPMs are supported.

Based on official `centos` image.



# Usage

## Layout for building from spec files

Place `SPECS` directory with spec file(s) into some base directory (called `<base-dir>` below).

If package requires some local (with non-url source) files, place them into `<base-dir>/SOURCES/`.


## Layout for building from SRPMs

Place `*.src.rpm` somewhere into `<base-dir>`. 


## Building

```bash
docker run -it --rm -v <base-dir>:/data grossws/makerpm:6 pkg1.spec path/to/srpm/relative/to/<base-dir>/pkg2.src.rpm ...
docker run -it --rm -v <base-dir>:/data grossws/makerpm:7 pkg1.spec path/to/srpm/relative/to/<base-dir>/pkg2.src.rpm ...
```

Resulting rpms will be stored in `<base-dir>/REPO/centos/$releasever/$basearch/` (only x86\_64 is supported).
SRPMs will be in `<base-dir>/REPO/centos/$releasever/SRPMS/` (they are produced only when building from spec).

Packages are built in same order as they appear in command line. Any package can depend on previuos ones.



# Dependencies

Dependencies are resolved against standart CentOS repos and [EPEL][epel].

To disable EPEL either remove `/etc/yum.repos.d/epel.repo` file or `epel-release` package.

To add custom repos just add them to `/etc/yum.repos.d/` or install as packages.



# Internals

`makerpm.sh` script:
* Ensures clean rpmbuild tree for build user (`makerpm`);
* Maintains internal temporary repo where all build packages are deployed after build;
* Creates output layout (like `<base-dir>/repo/centos/7/x86_64/`);
* Installs build dependencies for spec/SRPM currently built;
* Fetches remote sources for package built from spec (using `spectool -g -R <pkg.spec>`);
* Builds package (using `rpmbuild -ba <pkg.spec>` or `rpmbuild --rebuild <pkg.src.rpm>`);
* Copies build RPMs and SRPMs to appropriate output dirs and to temporary repo;
* Invokes `createrepo` on output dirs.


[df]: http://docs.docker.com/reference/builder/ "Dockerfile reference"
[dhub]: https://hub.docker.com/u/grossws/
[centos]: https://www.centos.org/
[epel]: https://fedoraproject.org/wiki/EPEL

# Licensing

Licensed under MIT License. See [LICENSE file](LICENSE)

